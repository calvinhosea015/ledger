/// Supabase connection config via `--dart-define` (overrides defaults below).
///
/// ```
/// flutter run -d macos \
///   --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=sb_publishable_...
/// ```
///
/// Local demo (no Supabase):
/// ```
/// flutter run --dart-define=USE_FAKE_BACKEND=true
/// ```
class Env {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fcuailkqitbaruqachsp.supabase.co',
  );

  /// Dashboard "anon" / publishable key (safe for the client; RLS protects data).
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_O8j1yWs695oDrvCg_gESsw_HRVslZAP',
  );

  static const categoriesTable = String.fromEnvironment(
    'SUPABASE_CATEGORIES_TABLE',
    defaultValue: 'categories',
  );

  static const itemsTable = String.fromEnvironment(
    'SUPABASE_ITEMS_TABLE',
    defaultValue: 'items',
  );

  static const profilesTable = String.fromEnvironment(
    'SUPABASE_PROFILES_TABLE',
    defaultValue: 'profiles',
  );

  static const envelopesTable = String.fromEnvironment(
    'SUPABASE_ENVELOPES_TABLE',
    defaultValue: 'envelopes',
  );

  static const useFake = bool.fromEnvironment(
    'USE_FAKE_BACKEND',
    defaultValue: false,
  );

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Adapters use fake when forced, or when Supabase is not configured.
  static bool get shouldUseFake => useFake || !hasSupabase;
}
