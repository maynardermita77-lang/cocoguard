import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
// ignore: depend_on_referenced_packages
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: depend_on_referenced_packages
import 'dart:io' show Platform;

class ApiService {
  // Base URL with automatic network discovery
  // Supports localhost, emulator, and custom backend URL configuration
  static String? _customBaseUrl;
  static String? _token;

  // Default server port
  static const int _defaultPort = 8000;

  // Production backend URL (Render deployment)
  static const String _productionUrl = 'https://cocoguard-backend.onrender.com';

  /// Get the base URL with automatic platform detection
  /// For physical devices: uses production URL by default
  /// For emulators/web: uses appropriate localhost mapping
  static Future<String> getBaseUrl() async {
    // Check if user has configured a custom backend URL (for physical devices)
    final prefs = await SharedPreferences.getInstance();
    final customUrl = prefs.getString('custom_backend_url');

    if (customUrl != null && customUrl.isNotEmpty) {
      return customUrl;
    }

    // Auto-detect based on platform
    if (kIsWeb) {
      // Web: Use current browser hostname (works on any network)
      // This is handled by JavaScript, but provide fallback
      return 'http://localhost:$_defaultPort';
    }

    // For mobile devices (Android/iOS), use production URL by default
    // This allows the app to work on any phone with internet access
    return _productionUrl;
  }

  /// Get the base URL synchronously (uses cached value or default)
  /// For physical devices, defaults to production URL
  static String get baseUrl {
    if (_customBaseUrl != null) return _customBaseUrl!;
    if (kIsWeb) return 'http://localhost:$_defaultPort';
    // Mobile devices use production URL
    return _productionUrl;
  }

  /// Set a custom backend URL (e.g., for physical devices on same network)
  static Future<void> setCustomBackendUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_backend_url', url);
    _customBaseUrl = url;
    developer.log('Custom backend URL set to: $url', name: 'ApiService');
  }

  /// Clear custom backend URL and use auto-detection
  static Future<void> clearCustomBackendUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('custom_backend_url');
    _customBaseUrl = null;
    developer.log(
      'Custom backend URL cleared, using auto-detection',
      name: 'ApiService',
    );
  }

  /// Get the currently configured backend URL
  static Future<String> getCurrentBackendUrl() async {
    return await getBaseUrl();
  }

  /// Initialize the API service and load stored token and custom backend URL
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    _customBaseUrl = prefs.getString('custom_backend_url');

    final currentUrl = await getBaseUrl();
    developer.log(
      'ApiService initialized with base URL: $currentUrl',
      name: 'ApiService',
    );
  }

  /// Set authentication token
  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    developer.log(
      'Token saved to storage: ${token.substring(0, 20)}...',
      name: 'ApiService',
    );
    developer.log(
      'Token in memory: ${_token?.substring(0, 20)}...',
      name: 'ApiService',
    );
  }

  /// Get current token
  static String? getToken() {
    return _token;
  }

  /// Ensure token is loaded from storage
  static Future<void> ensureTokenLoaded() async {
    // Always reload from SharedPreferences on web to handle navigation
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('access_token');
    developer.log(
      'Loading token from storage: ${storedToken != null ? "${storedToken.substring(0, 20)}..." : "NULL"}',
      name: 'ApiService',
    );
    if (storedToken != null) {
      _token = storedToken;
      developer.log(
        'Token loaded into memory: ${_token?.substring(0, 20)}...',
        name: 'ApiService',
      );
    } else {
      developer.log('No token found in storage!', name: 'ApiService');
    }
  }

  /// Clear authentication token
  static void clearToken() {
    _token = null;
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('access_token');
    });
  }

  /// Check if user is authenticated
  static bool isAuthenticated() {
    return _token != null && _token!.isNotEmpty;
  }

  /// GET request
  static Future<http.Response> get(String endpoint) async {
    await ensureTokenLoaded();
    final url = await getBaseUrl();
    developer.log('GET Request to: $url$endpoint', name: 'ApiService');
    developer.log(
      'Token in memory after load: ${_token != null ? "${_token!.substring(0, 20)}..." : "NULL"}',
      name: 'ApiService',
    );
    final headers = _getHeaders();
    developer.log(
      'Headers Authorization: ${headers.containsKey("Authorization") ? "Present" : "Missing"}',
      name: 'ApiService',
    );
    if (headers.containsKey("Authorization")) {
      developer.log(
        'Auth header value: ${headers["Authorization"]!.substring(0, 27)}...',
        name: 'ApiService',
      );
    }
    try {
      final response = await http
          .get(Uri.parse('$url$endpoint'), headers: headers)
          .timeout(const Duration(seconds: 30));
      developer.log(
        'Response status: ${response.statusCode}',
        name: 'ApiService',
      );
      if (response.statusCode != 200) {
        developer.log('Response body: ${response.body}', name: 'ApiService');
      }
      return response;
    } catch (e) {
      developer.log('GET request error: $e', name: 'ApiService');
      throw ApiException('GET request failed: $e');
    }
  }

  /// POST request
  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    await ensureTokenLoaded();
    final url = await getBaseUrl();
    final headers = _getHeaders();
    try {
      final response = await http
          .post(
            Uri.parse('$url$endpoint'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      return response;
    } catch (e) {
      throw ApiException('POST request failed: $e');
    }
  }

  /// POST request with file upload (multipart/form-data)
  static Future<http.StreamedResponse> postWithFile(
    String endpoint,
    String filePath,
    String fieldName, {
    Map<String, String>? additionalFields,
  }) async {
    await ensureTokenLoaded();
    final url = await getBaseUrl();
    final headers = _getHeaders();
    headers.remove('Content-Type'); // Let http package set it with boundary

    try {
      final request = http.MultipartRequest('POST', Uri.parse('$url$endpoint'))
        ..headers.addAll(headers)
        ..files.add(await http.MultipartFile.fromPath(fieldName, filePath));

      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 5),
      );
      return streamedResponse;
    } catch (e) {
      throw ApiException('File upload failed: $e');
    }
  }

  /// PUT request
  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    await ensureTokenLoaded();
    final url = await getBaseUrl();
    final headers = _getHeaders();
    developer.log('PUT Request to: $url$endpoint', name: 'ApiService');
    developer.log('Headers: ${headers.keys.toList()}', name: 'ApiService');
    developer.log('Body: ${jsonEncode(body)}', name: 'ApiService');
    developer.log(
      'Token present: ${_token != null && _token!.isNotEmpty}',
      name: 'ApiService',
    );
    try {
      final response = await http
          .put(
            Uri.parse('$url$endpoint'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      developer.log(
        'Response status: ${response.statusCode}',
        name: 'ApiService',
      );
      developer.log('Response body: ${response.body}', name: 'ApiService');
      return response;
    } catch (e) {
      developer.log('PUT request error: $e', name: 'ApiService');
      throw ApiException('PUT request failed: $e');
    }
  }

  /// PATCH request
  static Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    await ensureTokenLoaded();
    final url = await getBaseUrl();
    final headers = _getHeaders();
    try {
      final response = await http
          .patch(
            Uri.parse('$url$endpoint'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      return response;
    } catch (e) {
      throw ApiException('PATCH request failed: $e');
    }
  }

  /// DELETE request
  static Future<http.Response> delete(String endpoint) async {
    await ensureTokenLoaded();
    final url = await getBaseUrl();
    final headers = _getHeaders();
    try {
      final response = await http
          .delete(Uri.parse('$url$endpoint'), headers: headers)
          .timeout(const Duration(seconds: 30));
      return response;
    } catch (e) {
      throw ApiException('DELETE request failed: $e');
    }
  }

  /// Build headers with authentication
  static Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  /// Public method to get headers (for use in other services)
  static Map<String, String> getHeaders() {
    return _getHeaders();
  }

  // ============= PASSWORD RESET =============

  /// Request a password reset code to be sent to email
  static Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    final url = await getBaseUrl();
    developer.log('Requesting password reset for: $email', name: 'ApiService');

    try {
      final response = await http
          .post(
            Uri.parse('$url/password-reset/request'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 30));

      developer.log(
        'Password reset request response: ${response.statusCode}',
        name: 'ApiService',
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Handle HTTP error responses (e.g. 404 = email not found)
      if (response.statusCode == 404) {
        return {
          'success': false,
          'message':
              data['detail'] ??
              'No account found with that email. Please create an account first.',
        };
      }
      if (response.statusCode >= 400) {
        return {
          'success': false,
          'message':
              data['detail'] ??
              data['message'] ??
              'Something went wrong. Please try again.',
        };
      }

      return data;
    } catch (e) {
      developer.log('Password reset request error: $e', name: 'ApiService');
      throw ApiException('Failed to request password reset: $e');
    }
  }

  /// Verify the password reset code
  static Future<Map<String, dynamic>> verifyResetCode(
    String email,
    String code,
  ) async {
    final url = await getBaseUrl();
    developer.log('Verifying reset code for: $email', name: 'ApiService');

    try {
      final response = await http
          .post(
            Uri.parse('$url/password-reset/verify'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'code': code}),
          )
          .timeout(const Duration(seconds: 30));

      developer.log(
        'Verify code response: ${response.statusCode}',
        name: 'ApiService',
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data;
    } catch (e) {
      developer.log('Verify code error: $e', name: 'ApiService');
      throw ApiException('Failed to verify code: $e');
    }
  }

  /// Confirm password reset with new password
  static Future<Map<String, dynamic>> confirmPasswordReset(
    String email,
    String code,
    String newPassword,
  ) async {
    final url = await getBaseUrl();
    developer.log('Confirming password reset for: $email', name: 'ApiService');

    try {
      final response = await http
          .post(
            Uri.parse('$url/password-reset/confirm'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'code': code,
              'new_password': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 30));

      developer.log(
        'Confirm password reset response: ${response.statusCode}',
        name: 'ApiService',
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data;
    } catch (e) {
      developer.log('Confirm password reset error: $e', name: 'ApiService');
      throw ApiException('Failed to reset password: $e');
    }
  }

  /// Resend the password reset code
  static Future<Map<String, dynamic>> resendResetCode(String email) async {
    return requestPasswordReset(email);
  }

  /// Handle API response
  static Map<String, dynamic> handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      switch (response.statusCode) {
        case 200:
        case 201:
          return data;
        case 400:
          throw ApiException(data['detail'] ?? 'Bad request');
        case 401:
          clearToken(); // Clear token on unauthorized
          throw ApiException(
            'Unauthorized: ${data['detail'] ?? 'Authentication failed'}',
          );
        case 403:
          throw ApiException('Forbidden: ${data['detail'] ?? 'Access denied'}');
        case 404:
          throw ApiException(
            'Not found: ${data['detail'] ?? 'Resource not found'}',
          );
        case 422:
          throw ApiException(data['detail'] ?? 'Validation error');
        case 500:
          throw ApiException(
            'Server error: ${data['detail'] ?? 'Internal server error'}',
          );
        default:
          throw ApiException(
            'Error ${response.statusCode}: ${data['detail'] ?? response.body}',
          );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to parse response: $e');
    }
  }
}

/// Custom API exception
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}
