import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import 'locale_controller.dart';
import 'router.dart';
import 'theme.dart';

const _pilotDefaultLocale = Locale('ru');

class AutoDoctorApp extends ConsumerWidget {
  const AutoDoctorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeOverride = ref
        .watch(localeControllerProvider)
        .when(
          data: (locale) => locale,
          loading: () => _pilotDefaultLocale,
          error: (error, stackTrace) => _pilotDefaultLocale,
        );

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildAutoDoctorTheme(),
      locale: localeOverride,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: _resolveLocale,
      routerConfig: ref.watch(routerProvider),
    );
  }
}

Locale _resolveLocale(
  List<Locale>? preferredLocales,
  Iterable<Locale> supportedLocales,
) {
  for (final preferredLocale in preferredLocales ?? const <Locale>[]) {
    for (final supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == preferredLocale.languageCode) {
        return supportedLocale;
      }
    }
  }
  return _pilotDefaultLocale;
}
