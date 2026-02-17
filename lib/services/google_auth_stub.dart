/// Stub implementation for non-web platforms.
/// On mobile, Google Sign-In is handled via the google_sign_in package directly.
Future<String?> requestGoogleAccessToken(String clientId) async {
  // Not used on mobile — GoogleSignIn package handles auth natively.
  return null;
}
