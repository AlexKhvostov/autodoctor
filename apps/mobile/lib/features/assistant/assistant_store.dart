import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'assistant.dart';

class AssistantThreadStore {
  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'assistant_threads.json'));
  }

  Future<List<ChatThread>> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return const [];
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => ChatThread.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    } on Object {
      return const [];
    }
  }

  Future<void> save(List<ChatThread> threads) async {
    final file = await _file();
    await file.writeAsString(
      jsonEncode(threads.map((thread) => thread.toJson()).toList()),
    );
  }
}

/// In-memory store for widget tests (no path_provider).
class InMemoryAssistantThreadStore extends AssistantThreadStore {
  List<ChatThread> _threads = const [];

  @override
  Future<List<ChatThread>> load() async => _threads;

  @override
  Future<void> save(List<ChatThread> threads) async {
    _threads = List<ChatThread>.from(threads);
  }
}

final assistantThreadStoreProvider = Provider<AssistantThreadStore>(
  (ref) => AssistantThreadStore(),
);
