import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  var supabaseReady = false;
  if (config.isConfigured) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabasePublishableKey,
    );
    supabaseReady = true;
  }
  runApp(ProviderScope(
    overrides: [supabaseReadyProvider.overrideWithValue(supabaseReady)],
    child: const IpscDesignerApp(),
  ));
}

class IpscDesignerApp extends ConsumerWidget {
  const IpscDesignerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needsLogin = ref.watch(supabaseReadyProvider) &&
        Supabase.instance.client.auth.currentSession == null;
    return MaterialApp(
      title: 'IPSC Stage Designer',
      theme: AppTheme.light,
      initialRoute: needsLogin ? AppRoutes.login : AppRoutes.stageLibrary,
      routes: AppRouter.routes,
    );
  }
}
