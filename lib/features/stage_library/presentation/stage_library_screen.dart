import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../providers/stages_provider.dart';

class StageLibraryScreen extends ConsumerWidget {
  const StageLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stages = ref.watch(stagesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Stage library')),
      body: stages.isEmpty
          ? const Center(
              child: Text('No stages yet. Tap + to create one.'),
            )
          : ListView.builder(
              itemCount: stages.length,
              itemBuilder: (BuildContext context, int index) {
                final stage = stages[index];
                return ListTile(
                  leading: const Icon(Icons.map_outlined),
                  title: Text(stage.title),
                  subtitle: Text('${stage.elements.length} elements'),
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.editor);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRoutes.editor);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
