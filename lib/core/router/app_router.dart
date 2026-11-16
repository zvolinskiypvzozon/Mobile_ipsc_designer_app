import 'package:material_ui/material_ui.dart';

import '../../features/editor/presentation/editor_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/stage_library/presentation/stage_library_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String stageLibrary = '/';
  static const String editor = '/editor';
  static const String settings = '/settings';
}

class AppRouter {
  AppRouter._();

  static Map<String, WidgetBuilder> get routes => <String, WidgetBuilder>{
        AppRoutes.stageLibrary: (BuildContext context) =>
            const StageLibraryScreen(),
        AppRoutes.editor: (BuildContext context) => const EditorScreen(),
        AppRoutes.settings: (BuildContext context) => const SettingsScreen(),
      };
}
