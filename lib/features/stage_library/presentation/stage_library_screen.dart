import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/stage.dart';
import '../../../core/router/app_router.dart';
import '../providers/stages_provider.dart';

class StageLibraryScreen extends ConsumerWidget {
  const StageLibraryScreen({super.key});

  static const _uuid = Uuid();

  String _elementCount(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return '$count элемент';
    }
    if (count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 12 || count % 100 > 14)) {
      return '$count элемента';
    }
    return '$count элементов';
  }

  Future<void> _openEditor(BuildContext context, Stage? stage) async {
    final stageToOpen = stage ??
        Stage(id: _uuid.v4(), title: 'Новый стейдж');
    await Navigator.of(context)
        .pushNamed(AppRoutes.editor, arguments: stageToOpen);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Stage stage) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Удалить стейдж'),
          content: Text('Удалить «${stage.title}»? Действие необратимо.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await ref.read(stagesProvider.notifier).delete(stage.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagesAsync = ref.watch(stagesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Библиотека стейджей')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Создать'),
      ),
      body: stagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Не удалось загрузить стейджи'),
              const SizedBox(height: 8),
              Text('$error', textAlign: TextAlign.center),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.invalidate(stagesProvider),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (List<Stage> stages) {
          if (stages.isEmpty) {
            return const Center(
              child: Text('Стейджей пока нет. Нажмите «Создать».'),
            );
          }
          return ListView.builder(
            itemCount: stages.length,
            itemBuilder: (BuildContext context, int index) {
              final stage = stages[index];
              return ListTile(
                title: Text(stage.title),
                subtitle: Text(_elementCount(stage.elements.length)),
                leading: const Icon(Icons.map_outlined),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Удалить',
                  onPressed: () => _confirmDelete(context, ref, stage),
                ),
                onTap: () => _openEditor(context, stage),
              );
            },
          );
        },
      ),
    );
  }
}
