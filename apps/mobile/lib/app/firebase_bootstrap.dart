import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Android-only for now (google-services.json). Missing Firebase must not block the app.
Future<void> initializeFirebase() async {
  if (kIsWeb || !Platform.isAndroid) {
    return;
  }
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  } on Object catch (error, stack) {
    debugPrint('Firebase init skipped: $error');
    debugPrintStack(stackTrace: stack);
  }
}
