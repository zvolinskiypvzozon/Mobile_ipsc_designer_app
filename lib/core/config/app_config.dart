import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
  });

  factory AppConfig.fromEnvironment() {
    const url = String.fromEnvironment('SUPABASE_URL');
    const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    return AppConfig(
      supabaseUrl: url,
      supabasePublishableKey: publishableKey,
    );
  }

  final String supabaseUrl;
  final String supabasePublishableKey;

  bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}

final supabaseReadyProvider = Provider<bool>((ref) => false);
