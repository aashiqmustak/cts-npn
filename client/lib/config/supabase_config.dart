// Alternea Supabase Configuration
class SupabaseConfig {
  static const String supabaseAnonKey = 'sb_publishable_6O0GgNlaCxfPvu0Ixi8ODw_bEeIMa62';
  static const String supabaseUrl = 'https://hhlivbsbwhrjuxvpfbba.supabase.co';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('your-supabase-project') &&
      !supabaseAnonKey.contains('your-supabase-anon-key');
}
