import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/locale_controller.dart';
import 'guest_bootstrap.dart';
import 'guest_bootstrap_data.dart';

final sessionTokenStoreProvider = Provider<SessionTokenStore>(
  (ref) => SecureSessionTokenStore(),
);

final guestBootstrapRepositoryProvider = Provider<GuestBootstrapRepository>(
  (ref) => DioGuestBootstrapRepository(
    ref.watch(sessionTokenStoreProvider),
    locale: ref.watch(activeLocaleProvider).languageCode,
  ),
);

enum GuestBootstrapStage { idle, loading, ready, submitting, error }

class GuestBootstrapState {
  const GuestBootstrapState({
    this.stage = GuestBootstrapStage.idle,
    this.documents = const [],
    this.selected = const {},
    this.failure,
    this.submitFailure = false,
  });

  final GuestBootstrapStage stage;
  final List<ConsentDocument> documents;
  final Map<String, bool> selected;
  final GuestBootstrapFailure? failure;
  final bool submitFailure;

  bool get canContinue =>
      stage == GuestBootstrapStage.ready &&
      documents
          .where((document) => document.required)
          .every((document) => selected[document.purpose] == true);

  GuestBootstrapState copyWith({
    GuestBootstrapStage? stage,
    List<ConsentDocument>? documents,
    Map<String, bool>? selected,
    GuestBootstrapFailure? failure,
    bool clearFailure = false,
    bool? submitFailure,
  }) {
    return GuestBootstrapState(
      stage: stage ?? this.stage,
      documents: documents ?? this.documents,
      selected: selected ?? this.selected,
      failure: clearFailure ? null : failure ?? this.failure,
      submitFailure: submitFailure ?? this.submitFailure,
    );
  }
}

final guestBootstrapControllerProvider =
    NotifierProvider<GuestBootstrapController, GuestBootstrapState>(
      GuestBootstrapController.new,
    );

class GuestBootstrapController extends Notifier<GuestBootstrapState> {
  bool _sessionReady = false;
  bool _recreatedInvalidToken = false;
  String _locale = 'ru';
  String _platform = 'android';

  GuestBootstrapRepository get _repository =>
      ref.read(guestBootstrapRepositoryProvider);
  SessionTokenStore get _tokenStore => ref.read(sessionTokenStoreProvider);

  @override
  GuestBootstrapState build() => const GuestBootstrapState();

  Future<void> start({required String locale, required String platform}) async {
    _locale = locale;
    _platform = platform;
    if (state.stage != GuestBootstrapStage.idle) {
      return;
    }
    await _load();
  }

  Future<void> retry() async {
    if (state.submitFailure) {
      await submit();
      return;
    }
    await _load();
  }

  Future<void> _load() async {
    state = state.copyWith(
      stage: GuestBootstrapStage.loading,
      clearFailure: true,
      submitFailure: false,
    );
    try {
      if (!_sessionReady) {
        await _ensureSession();
      }
      final documents = await _repository.getCurrentConsents();
      final selected = {
        for (final document in documents)
          document.purpose: state.selected[document.purpose] ?? false,
      };
      state = state.copyWith(
        stage: GuestBootstrapStage.ready,
        documents: documents,
        selected: selected,
        clearFailure: true,
      );
    } on GuestBootstrapFailure catch (failure) {
      state = state.copyWith(
        stage: GuestBootstrapStage.error,
        failure: failure,
        submitFailure: false,
      );
    } on Object {
      state = state.copyWith(
        stage: GuestBootstrapStage.error,
        failure: const GuestBootstrapFailure(
          safeMessage: '',
          kind: GuestBootstrapFailureKind.unavailable,
        ),
        submitFailure: false,
      );
    }
  }

  Future<void> _ensureSession() async {
    final token = await _tokenStore.read();
    if (token != null && token.isNotEmpty) {
      try {
        final session = await _repository.getCurrentSession();
        if (session.status == 'active') {
          _sessionReady = true;
          return;
        }
        throw const GuestBootstrapFailure(
          code: 'SESSION_REVOKED',
          statusCode: 401,
          safeMessage: '',
          kind: GuestBootstrapFailureKind.unavailable,
        );
      } on GuestBootstrapFailure catch (failure) {
        if (!failure.isInvalidSession || _recreatedInvalidToken) {
          rethrow;
        }
        _recreatedInvalidToken = true;
        await _tokenStore.clear();
      }
    }

    final created = await _repository.createAnonymousSession(
      locale: _locale,
      platform: _platform,
      appVersion: '0.1.0',
    );
    await _tokenStore.write(created.token);
    _sessionReady = true;
  }

  void setDecision(String purpose, bool granted) {
    state = state.copyWith(
      stage: GuestBootstrapStage.ready,
      selected: {...state.selected, purpose: granted},
      clearFailure: true,
    );
  }

  Future<void> submit() async {
    if (!state.canContinue && !state.submitFailure) {
      return;
    }
    final decisions = state.documents
        .map(
          (document) => ConsentDecision(
            purpose: document.purpose,
            version: document.version,
            granted: state.selected[document.purpose] ?? false,
          ),
        )
        .toList(growable: false);
    state = state.copyWith(
      stage: GuestBootstrapStage.submitting,
      clearFailure: true,
      submitFailure: false,
    );
    try {
      await _repository.saveConsents(decisions);
      state = state.copyWith(
        stage: GuestBootstrapStage.ready,
        clearFailure: true,
      );
    } on GuestBootstrapFailure catch (failure) {
      state = state.copyWith(
        stage: GuestBootstrapStage.error,
        failure: failure,
        submitFailure: true,
      );
    } on Object {
      state = state.copyWith(
        stage: GuestBootstrapStage.error,
        failure: const GuestBootstrapFailure(
          safeMessage: '',
          kind: GuestBootstrapFailureKind.unavailable,
        ),
        submitFailure: true,
      );
    }
  }

  void reset() {
    state = const GuestBootstrapState();
  }
}
