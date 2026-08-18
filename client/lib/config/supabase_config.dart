// Alternea Supabase Configuration
class SupabaseConfig {
  // Replace these with your actual Supabase URL and Anon Key from Supabase Dashboard
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-supabase-project.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-supabase-anon-key',
  );

  static bool get isConfigured =>
      supabaseUrl != 'https://your-supabase-project.supabase.co' &&
      supabaseAnonKey != 'your-supabase-anon-key' &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty;
}
