import 'dart:js_interop';

/// Calls the global JS function `requestGoogleToken(clientId)` defined in index.html.
/// Returns the Google OAuth2 access_token, or null if the user cancels / an error occurs.
@JS()
external JSPromise<JSString> requestGoogleToken(JSString clientId);

Future<String?> requestGoogleAccessToken(String clientId) async {
  try {
    final JSString result = await requestGoogleToken(clientId.toJS).toDart;
    return result.toDart;
  } catch (e) {
    return null;
  }
}
