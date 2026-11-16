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
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('Бэкенд'),
            subtitle: Text(
              ready
                  ? 'Supabase (${user != null ? 'вход выполнен' : 'вход не выполнен'})'
                  : 'Оффлайн-режим: запустите с SUPABASE_URL и '
                      'SUPABASE_PUBLISHABLE_KEY',
            ),
          ),
          if (user != null)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Аккаунт'),
              subtitle: Text(user.email ?? user.id),
            ),
          if (user != null)
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Выйти'),
              onTap: () => _signOut(context),
            ),
        ],
      ),
    );
  }
}
