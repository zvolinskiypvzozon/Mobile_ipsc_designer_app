import 'package:material_ui/material_ui.dart';

import '../../../core/models/stage_element.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stage editor')),
      body: const Center(
        child: Text('Canvas placeholder'),
      ),
      bottomNavigationBar: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: <Widget>[
              for (final StageElementType type in StageElementType.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ActionChip(
                    label: Text(type.label),
                    onPressed: () {},
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
