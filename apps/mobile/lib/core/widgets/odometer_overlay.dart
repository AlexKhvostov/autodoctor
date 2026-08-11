import 'package:flutter/foundation.dart';

/// Counts open odometer dialogs so shell UI (e.g. roadmap FAB) can hide.
final ValueNotifier<int> odometerPickerOpenCount = ValueNotifier<int>(0);
