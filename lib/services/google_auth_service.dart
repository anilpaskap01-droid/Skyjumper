import 'package:google_sign_in/google_sign_in.dart';

/// Firebase-free Google Sign-In wrapper.
///
/// Pass a Google OAuth Web Client ID at build time:
/// flutter build apk --release --dart-define=GOOGLE_CLIENT_ID=YOUR_ID.apps.googleusercontent.com
class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService instance = GoogleAuthService._();

  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const <String>['email', 'profile'],
    serverClientId: googleClientId.isEmpty ? null : googleClientId,
  );

  bool get isConfigured => googleClientId.trim().isNotEmpty;

  Future<GoogleSignInAccount?> restoreSession() async {
    if (!isConfigured) return null;
    try {
      return await _googleSignIn.signInSilently();
    } catch (_) {
      return null;
    }
  }

  Future<GoogleSignInAccount?> signIn() async {
    if (!isConfigured) return null;
    return _googleSignIn.signIn();
  }

  Future<void> signOut() async {
    if (!isConfigured) return;
    await _googleSignIn.signOut();
  }
}
