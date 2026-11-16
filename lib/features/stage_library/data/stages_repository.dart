import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/stage.dart';

abstract class StagesRepository {
  Future<List<Stage>> listStages();
  Future<void> saveStage(Stage stage);
  Future<void> deleteStage(String stageId);
}

class SupabaseStagesRepository implements StagesRepository {
  SupabaseStagesRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Not signed in');
    }
    return user.id;
  }

  @override
  Future<List<Stage>> listStages() async {
    final stageRows = await _client
        .from('stages')
        .select('id, title')
        .order('updated_at', ascending: false);

    final elementRows = await _client
        .from('stage_elements')
        .select()
        .order('sort_order', ascending: true);

    final elementsByStage = <String, List<Map<String, dynamic>>>{};
    for (final row in elementRows) {
      final stageId = row['stage_id'] as String;
      elementsByStage.putIfAbsent(stageId, () => <Map<String, dynamic>>[]).add(
            Map<String, dynamic>.from(row),
          );
    }

    return stageRows.map((row) {
      return Stage.fromRows(
        Map<String, dynamic>.from(row),
        elementsByStage[row['id'] as String] ?? const [],
      );
    }).toList();
  }

  @override
  Future<void> saveStage(Stage stage) async {
    final userId = _userId;
    await _client.from('stages').upsert(<String, dynamic>{
      'id': stage.id,
      'user_id': userId,
      'title': stage.title,
    });
    await _client.from('stage_elements').delete().eq('stage_id', stage.id);
    if (stage.elements.isNotEmpty) {
      final rows = <int, Map<String, dynamic>>{
        for (final entry in stage.elements.indexed)
          entry.$1: entry.$2.toRow(stageId: stage.id, sortOrder: entry.$1),
      };
      await _client
          .from('stage_elements')
          .insert(rows.values.toList(growable: false));
    }
  }

  @override
  Future<void> deleteStage(String stageId) async {
    await _client.from('stages').delete().eq('id', stageId);
  }
}

class InMemoryStagesRepository implements StagesRepository {
  final List<Stage> _stages = <Stage>[];

  @override
  Future<List<Stage>> listStages() async =>
      List<Stage>.unmodifiable(_stages);

  @override
  Future<void> saveStage(Stage stage) async {
    final index = _stages.indexWhere((s) => s.id == stage.id);
    if (index == -1) {
      _stages.insert(0, stage);
    } else {
      _stages[index] = stage;
    }
  }

  @override
  Future<void> deleteStage(String stageId) async {
    _stages.removeWhere((s) => s.id == stageId);
  }
}
