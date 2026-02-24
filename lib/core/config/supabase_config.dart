import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://hlfhuutmarffhsntpcsi.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhsZmh1dXRtYXJmZmhzbnRwY3NpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE5Mjk3NzYsImV4cCI6MjA4NzUwNTc3Nn0.hAvguZN6E_FEBSSy_DZRGB_F2MZtI7XVm-K8U9juyaQ';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
