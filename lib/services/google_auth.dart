/// Platform-conditional export for Google auth helper.
/// On web, uses JS interop with Google Identity Services.
/// On mobile/desktop, returns null (GoogleSignIn package is used directly).
library;

export 'google_auth_stub.dart'
    if (dart.library.js_interop) 'google_auth_web.dart';
