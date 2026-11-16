import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/router/app_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final navigator = Navigator.of(context);
    await Supabase.instance.client.auth.signOut();
    navigator.pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(supabaseReadyProvider);
    final user = ready ? Supabase.instance.client.auth.currentUser : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('Backend'),
            subtitle: Text(
              ready
                  ? 'Supabase (${user != null ? 'signed in' : 'signed out'})'
                  : 'Offline mode: run with SUPABASE_URL and '
                      'SUPABASE_PUBLISHABLE_KEY dart-defines',
            ),
          ),
          if (user != null)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Account'),
              subtitle: Text(user.email ?? user.id),
            ),
          if (user != null)
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () => _signOut(context),
            ),
        ],
      ),
    );
  }
}
