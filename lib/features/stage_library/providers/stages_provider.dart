import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/stage.dart';
import '../data/stages_repository.dart';

final stagesRepositoryProvider = Provider<StagesRepository>((ref) {
  final ready = ref.watch(supabaseReadyProvider);
  if (ready && AppConfig.fromEnvironment().isConfigured) {
    return SupabaseStagesRepository(Supabase.instance.client);
  }
  return InMemoryStagesRepository();
});
final stagesProvider =
    AsyncNotifierProvider<StagesNotifier, List<Stage>>(StagesNotifier.new);

class StagesNotifier extends AsyncNotifier<List<Stage>> {
  StagesRepository get _repository => ref.read(stagesRepositoryProvider);

  @override
  Future<List<Stage>> build() => _repository.listStages();

  Future<void> save(Stage stage) async {
    state = const AsyncValue<List<Stage>>.loading();
    try {
      await _repository.saveStage(stage);
      final stages = await _repository.listStages();
      state = AsyncValue<List<Stage>>.data(stages);
    } catch (error, stackTrace) {
      state = AsyncValue<List<Stage>>.error(error, stackTrace);
    }
  }

  Future<void> delete(String stageId) async {
    state = const AsyncValue<List<Stage>>.loading();
    try {
      await _repository.deleteStage(stageId);
      final stages = await _repository.listStages();
      state = AsyncValue<List<Stage>>.data(stages);
    } catch (error, stackTrace) {
      state = AsyncValue<List<Stage>>.error(error, stackTrace);
    }
  }
}
