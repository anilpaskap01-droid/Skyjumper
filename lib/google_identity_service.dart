import 'package:google_sign_in/google_sign_in.dart';

class GoogleIdentityService {
  GoogleIdentityService._();

  static const String clientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool _initialized = false;

  static bool get isConfigured => clientId.trim().isNotEmpty;

  static Future<void> initialize() async {
    if (_initialized || !isConfigured) return;
    await _googleSignIn.initialize(clientId: clientId);
    _initialized = true;
  }

  static Future<GoogleSignInAccount?> signIn() async {
    await initialize();
    if (!isConfigured) return null;
    return _googleSignIn.authenticate();
  }

  static Future<void> signOut() async {
    if (!_initialized) return;
    await _googleSignIn.disconnect();
  }
}
