import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/auto_doctor_app.dart';
import 'app/locale_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  await container.read(localeControllerProvider.future);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AutoDoctorApp(),
    ),
  );
}
