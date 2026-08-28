class GoogleOAuthConfig {
  static const String clientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  static bool get isConfigured => clientId.trim().isNotEmpty;
}
