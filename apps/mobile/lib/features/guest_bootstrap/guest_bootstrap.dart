class ConsentDocument {
  const ConsentDocument({
    required this.purpose,
    required this.version,
    required this.title,
    required this.text,
    required this.required,
  });

  final String purpose;
  final String version;
  final String title;
  final String text;
  final bool required;

  factory ConsentDocument.fromJson(Map<String, dynamic> json) {
    return ConsentDocument(
      purpose: json['purpose'] as String,
      version: json['version'] as String,
      title: json['title'] as String,
      text: json['text'] as String,
      required: json['required'] as bool,
    );
  }
}

class ConsentDecision {
  const ConsentDecision({
    required this.purpose,
    required this.version,
    required this.granted,
  });

  final String purpose;
  final String version;
  final bool granted;

  Map<String, dynamic> toJson() => {
    'purpose': purpose,
    'version': version,
    'granted': granted,
  };
}

class GuestSession {
  const GuestSession({required this.id, required this.status});

  final String id;
  final String status;
}

class CreatedGuestSession {
  const CreatedGuestSession({required this.session, required this.token});

  final GuestSession session;
  final String token;
}

class GuestBootstrapFailure implements Exception {
  const GuestBootstrapFailure({
    required this.safeMessage,
    this.kind,
    this.code,
    this.requestId,
    this.statusCode,
  });

  final String safeMessage;
  final GuestBootstrapFailureKind? kind;
  final String? code;
  final String? requestId;
  final int? statusCode;

  bool get isInvalidSession =>
      statusCode == 401 &&
      const {
        'SESSION_TOKEN_REQUIRED',
        'INVALID_SESSION_TOKEN',
        'SESSION_EXPIRED',
        'SESSION_REVOKED',
      }.contains(code);
}

enum GuestBootstrapFailureKind { network, unexpectedResponse, unavailable }

abstract interface class SessionTokenStore {
  Future<String?> read();

  Future<void> write(String token);

  Future<void> clear();
}

abstract interface class GuestBootstrapRepository {
  Future<CreatedGuestSession> createAnonymousSession({
    required String locale,
    required String platform,
    required String appVersion,
  });

  Future<GuestSession> getCurrentSession();

  Future<List<ConsentDocument>> getCurrentConsents();

  Future<void> saveConsents(List<ConsentDecision> decisions);
}
