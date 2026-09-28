/// Connexion au projet Supabase.
///
/// La clé `anon` est publique par conception (elle est embarquée dans
/// l'app) : ce sont les politiques RLS de la base qui protègent les
/// données. Ne jamais mettre ici la clé `service_role`.
///
/// Surchargeable sans toucher au code :
/// `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ymyngfzlsosdoxyzhpgb.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlteW5nZnpsc29zZG94eXpocGdiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA2MDIyOTEsImV4cCI6MjEwNjE3ODI5MX0.yjfCX0zDsKYkOIqefZ11LuOMEty7ML25j9rI7XHfSpY',
  );

  /// Lien profond ouvert après confirmation d'email ou réinitialisation
  /// du mot de passe. Doit figurer dans Authentication > URL Configuration
  /// > Redirect URLs du tableau de bord Supabase.
  static const String authRedirectUrl = 'io.supabase.ecowaste://login-callback';

  SupabaseConfig._();
}
