import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/auto_doctor_app.dart';
import 'app/api_endpoint.dart';
import 'app/firebase_bootstrap.dart';
import 'app/locale_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();

  final container = ProviderContainer();
  await container.read(localeControllerProvider.future);
  await container.read(apiEndpointControllerProvider.notifier).hydrate();
  await container.read(apiEndpointControllerProvider.notifier).applyRemoteConfig();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AutoDoctorApp(),
    ),
  );
}
