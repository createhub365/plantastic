/// Set in [main] during startup.
abstract final class AppConfig {
  /// True only after a successful [Supabase.initialize].
  static bool supabaseReady = false;

  /// True when `SUPABASE_URL` (or known alias) is missing or blank after load.
  static bool supabaseUrlMissing = false;

  /// Set if [dotenv.load] throws (e.g. `.env` missing from asset bundle).
  static String? envLoadError;

  /// Set if anon key looked long enough but [Supabase.initialize] threw.
  static String? supabaseInitError;

  /// Anon key string length after trim (for UI hints only, do not log full key).
  static int anonKeyLength = 0;

  /// When anon key ends up empty: `'empty'` (= line exists but blank),
  /// `'missing'` (none of the known keys), else null.
  static String? anonKeyProblemHint;

  /// Razorpay Standard Checkout **Key ID** (`rzp_live_…` / `rzp_test_…`), not the secret.
  /// Env: `RAZORPAY_KEY_ID`, `RAZORPAY_API_KEY`, or `RAZORPAY_PUBLISHABLE_KEY`; dart-define: `RAZORPAY_KEY_ID` / `RAZORPAY_API_KEY`.
  static String razorpayKeyId = '';
}
