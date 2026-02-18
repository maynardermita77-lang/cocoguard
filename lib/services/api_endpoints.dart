import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Auth API endpoints
class AuthApi {
  /// Login with email/username and password
  /// Returns: {access_token: "token", token_type: "bearer", user: {...}}
  static Future<Map<String, dynamic>> login(
    String emailOrUsername,
    String password,
  ) async {
    try {
      final response = await ApiService.post('/auth/login', {
        'email_or_username': emailOrUsername,
        'password': password,
      });

      final data = ApiService.handleResponse(response);
      if (data['access_token'] != null) {
        await ApiService.setToken(data['access_token']);
      }
      return data;
    } catch (e) {
      rethrow;
    }
  }

  /// Register new user
  /// Returns: {access_token: "token", token_type: "bearer", user: {...}}
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String username,
    String? phone,
    String? gender,
    String? dateOfBirth,
    String? region,
    String? province,
    String? city,
    String? barangay,
    required String addressLine,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'email': email,
        'password': password,
        'full_name': fullName,
        'username': username,
      };

      // Add optional fields if provided
      if (phone != null) body['phone'] = phone;
      if (gender != null) body['gender'] = gender;
      if (dateOfBirth != null) body['date_of_birth'] = dateOfBirth;
      if (region != null) body['region'] = region;
      if (province != null) body['province'] = province;
      if (city != null) body['city'] = city;
      if (barangay != null) body['barangay'] = barangay;
      body['address_line'] = addressLine;

      final response = await ApiService.post('/auth/register', body);

      final data = ApiService.handleResponse(response);
      // Save token if registration returns one
      if (data['access_token'] != null) {
        ApiService.setToken(data['access_token']);
      }
      return data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get current user profile
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await ApiService.get('/auth/me');
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Update current user profile
  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await ApiService.put('/auth/me', data);
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Logout
  static Future<void> logout() async {
    try {
      await ApiService.post('/auth/logout', {});
      ApiService.clearToken();
    } catch (e) {
      // Clear token even if request fails
      ApiService.clearToken();
      rethrow;
    }
  }

  /// Refresh authentication token
  static Future<Map<String, dynamic>> refreshToken() async {
    try {
      final response = await ApiService.post('/auth/refresh', {});
      final data = ApiService.handleResponse(response);
      if (data['access_token'] != null) {
        await ApiService.setToken(data['access_token']);
      }
      return data;
    } catch (e) {
      rethrow;
    }
  }

  /// Change password
  static Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await ApiService.post('/auth/change-password', {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Request verification code for changing password
  /// Returns email address where code was sent
  static Future<Map<String, dynamic>> requestChangePasswordCode(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await ApiService.post(
        '/auth/change-password/request-code',
        {'current_password': currentPassword, 'new_password': newPassword},
      );
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Verify code and change password
  static Future<Map<String, dynamic>> verifyAndChangePassword(
    String currentPassword,
    String newPassword,
    String code,
  ) async {
    try {
      final response = await ApiService.post('/auth/change-password/verify', {
        'current_password': currentPassword,
        'new_password': newPassword,
        'code': code,
      });
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Send verification code (email or SMS)
  static Future<Map<String, dynamic>> sendVerificationCode(
    String type,
    String recipient,
  ) async {
    try {
      final response = await ApiService.post('/verification/send', {
        'type': type,
        'recipient': recipient,
      });
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Verify code (email or SMS)
  static Future<Map<String, dynamic>> verifyCode(
    String type,
    String recipient,
    String code,
  ) async {
    try {
      final response = await ApiService.post('/verification/verify', {
        'type': type,
        'recipient': recipient,
        'code': code,
      });
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }
}

/// Public Registration API (no auth required) — email verification & Google sign-in
class PublicRegisterApi {
  /// Send a verification code to email for registration
  static Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    try {
      final response = await ApiService.post(
        '/public-register/send-verification-code',
        {'recipient': email},
      );
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Verify an email code (without consuming it)
  static Future<Map<String, dynamic>> verifyCode(
    String email,
    String code,
  ) async {
    try {
      final response = await ApiService.post('/public-register/verify-code', {
        'email': email,
        'code': code,
      });
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Complete registration with a verified email code
  static Future<Map<String, dynamic>> registerWithVerifiedEmail({
    required String email,
    required String password,
    required String code,
    required String fullName,
    required String username,
    String? phone,
    String? gender,
    String? dateOfBirth,
    String? addressLine,
    String? region,
    String? province,
    String? city,
    String? barangay,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'email': email,
        'password': password,
        'code': code,
        'full_name': fullName,
        'username': username,
      };
      if (phone != null) body['phone'] = phone;
      if (gender != null) body['gender'] = gender;
      if (dateOfBirth != null) body['date_of_birth'] = dateOfBirth;
      if (addressLine != null) body['address_line'] = addressLine;
      if (region != null) body['region'] = region;
      if (province != null) body['province'] = province;
      if (city != null) body['city'] = city;
      if (barangay != null) body['barangay'] = barangay;

      final response = await ApiService.post(
        '/public-register/register-verified',
        body,
      );
      final data = ApiService.handleResponse(response);
      if (data['access_token'] != null) {
        await ApiService.setToken(data['access_token']);
      }
      return data;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in or register with Google (using access_token + user-chosen password)
  static Future<Map<String, dynamic>> googleSignInWithAccessToken({
    required String accessToken,
    required String password,
  }) async {
    try {
      final response = await ApiService.post(
        '/public-register/google-signin-v2',
        {'access_token': accessToken, 'password': password},
      );
      final data = ApiService.handleResponse(response);
      if (data['access_token'] != null) {
        await ApiService.setToken(data['access_token']);
      }
      return data;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in or register with Google (legacy id_token flow)
  static Future<Map<String, dynamic>> googleSignIn({
    required String idToken,
    String? fullName,
    String? phone,
    String? gender,
    String? dateOfBirth,
    String? addressLine,
    String? region,
    String? province,
    String? city,
    String? barangay,
  }) async {
    try {
      final Map<String, dynamic> body = {'id_token': idToken};
      if (fullName != null) body['full_name'] = fullName;
      if (phone != null) body['phone'] = phone;
      if (gender != null) body['gender'] = gender;
      if (dateOfBirth != null) body['date_of_birth'] = dateOfBirth;
      if (addressLine != null) body['address_line'] = addressLine;
      if (region != null) body['region'] = region;
      if (province != null) body['province'] = province;
      if (city != null) body['city'] = city;
      if (barangay != null) body['barangay'] = barangay;

      final response = await ApiService.post(
        '/public-register/google-signin',
        body,
      );
      final data = ApiService.handleResponse(response);
      if (data['access_token'] != null) {
        await ApiService.setToken(data['access_token']);
      }
      return data;
    } catch (e) {
      rethrow;
    }
  }
}

/// Scans API endpoints
class ScansApi {
  /// Get all scans for current user
  static Future<List<dynamic>> getScans({int? limit, int? offset}) async {
    try {
      String endpoint = '/scans/my-scans';
      List<String> params = [];
      if (limit != null) params.add('limit=$limit');
      if (offset != null) params.add('offset=$offset');
      if (params.isNotEmpty) endpoint += '?${params.join('&')}';

      final response = await ApiService.get(endpoint);
      final data = ApiService.handleResponse(response);
      // Backend returns 'records', not 'scans'
      return data['records'] ?? data['scans'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get scan details
  static Future<Map<String, dynamic>> getScanDetail(int scanId) async {
    try {
      final response = await ApiService.get('/scans/$scanId');
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Create new scan record (saves detection result to history)
  static Future<Map<String, dynamic>> saveScanRecord({
    required String pestType,
    String? imageUrl,
    String? locationText,
    String? treeCode,
    int? pestTypeId,
  }) async {
    try {
      final body = <String, dynamic>{
        'pest_type': pestType, // Pass name so backend can look up ID
        'pest_type_id': pestTypeId,
        'image_url': imageUrl,
        'location_text': locationText,
        'tree_code': treeCode,
      };
      // Remove null values
      body.removeWhere((key, value) => value == null);

      final response = await ApiService.post('/scans', body);
      return ApiService.handleResponse(response);
    } catch (e) {
      // Don't rethrow - just log the error, scan saving is not critical
      debugPrint('Failed to save scan record: $e');
      return {'error': e.toString()};
    }
  }

  /// Create new scan with image
  static Future<Map<String, dynamic>> createScan(
    String imagePath,
    String pestType,
    double? latitude,
    double? longitude,
  ) async {
    try {
      final additionalFields = {'pest_type': pestType};
      if (latitude != null) additionalFields['latitude'] = latitude.toString();
      if (longitude != null) {
        additionalFields['longitude'] = longitude.toString();
      }

      final streamedResponse = await ApiService.postWithFile(
        '/scans/create',
        imagePath,
        'image',
        additionalFields: additionalFields,
      );

      final response = await http.Response.fromStream(streamedResponse);
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Update scan
  static Future<Map<String, dynamic>> updateScan(
    int scanId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await ApiService.put('/scans/$scanId', data);
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete scan
  static Future<void> deleteScan(int scanId) async {
    try {
      final response = await ApiService.delete('/scans/$scanId');
      ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete all scans for current user
  static Future<Map<String, dynamic>> deleteAllScans() async {
    try {
      final response = await ApiService.delete('/scans');
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Save survey result as a scan record
  static Future<Map<String, dynamic>> saveSurveyResult({
    required String pestType,
    required Map<String, int> answerCounts,
    String? locationText,
  }) async {
    try {
      final body = <String, dynamic>{
        'pest_type': pestType,
        'answer_counts': answerCounts,
        'location_text': locationText ?? 'Survey Assessment',
      };

      final response = await ApiService.post('/survey/result', body);
      return ApiService.handleResponse(response);
    } catch (e) {
      debugPrint('Failed to save survey result: $e');
      return {'error': e.toString()};
    }
  }
}

/// Pest Types API endpoints
class PestTypesApi {
  /// Get all pest types
  static Future<List<dynamic>> getPestTypes() async {
    try {
      final response = await ApiService.get('/pest-types');
      final data = ApiService.handleResponse(response);
      return data['pest_types'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get pest type details
  static Future<Map<String, dynamic>> getPestTypeDetail(int pestTypeId) async {
    try {
      final response = await ApiService.get('/pest-types/$pestTypeId');
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Search pest types
  static Future<List<dynamic>> searchPestTypes(String query) async {
    try {
      final response = await ApiService.get('/pest-types/search?q=$query');
      final data = ApiService.handleResponse(response);
      return data['pest_types'] ?? [];
    } catch (e) {
      rethrow;
    }
  }
}

/// Knowledge API endpoints
class KnowledgeApi {
  /// Get all knowledge articles
  static Future<List<dynamic>> getArticles({int? limit, int? offset}) async {
    try {
      String endpoint = '/knowledge';
      List<String> params = [];
      if (limit != null) params.add('limit=$limit');
      if (offset != null) params.add('offset=$offset');
      if (params.isNotEmpty) endpoint += '?${params.join('&')}';

      final response = await ApiService.get(endpoint);
      final data = ApiService.handleResponse(response);
      return data['articles'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  /// Get article details
  static Future<Map<String, dynamic>> getArticleDetail(int articleId) async {
    try {
      final response = await ApiService.get('/knowledge/$articleId');
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }
}

/// Farms API endpoints
class FarmsApi {
  /// Get all farms for current user
  static Future<List<dynamic>> getFarms() async {
    try {
      final response = await ApiService.get('/farms');
      final data = ApiService.handleResponse(response);
      return data['farms'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  /// Create new farm
  static Future<Map<String, dynamic>> createFarm(
    String name,
    String location,
    double? latitude,
    double? longitude,
  ) async {
    try {
      final body = {'name': name, 'location': location};
      if (latitude != null) body['latitude'] = latitude.toString();
      if (longitude != null) body['longitude'] = longitude.toString();

      final response = await ApiService.post('/farms', body);
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Update farm
  static Future<Map<String, dynamic>> updateFarm(
    int farmId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await ApiService.put('/farms/$farmId', data);
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete farm
  static Future<void> deleteFarm(int farmId) async {
    try {
      final response = await ApiService.delete('/farms/$farmId');
      ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }
}

/// Analytics API endpoints
class AnalyticsApi {
  /// Get dashboard analytics
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await ApiService.get('/analytics/dashboard');
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Get scan statistics
  static Future<Map<String, dynamic>> getScanStats({String? period}) async {
    try {
      String endpoint = '/analytics/scans';
      if (period != null) endpoint += '?period=$period';

      final response = await ApiService.get(endpoint);
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }
}

/// Feedback API endpoints
class FeedbackApi {
  /// Submit feedback
  static Future<Map<String, dynamic>> submitFeedback(
    String subject,
    String message,
    String rating,
  ) async {
    try {
      final response = await ApiService.post('/feedback', {
        'subject': subject,
        'message': message,
        'rating': rating,
      });
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Get current user's feedback history
  static Future<List<dynamic>> getMyFeedback({int limit = 50}) async {
    try {
      final response = await ApiService.get('/feedback/user/me?limit=$limit');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded;
        if (decoded is Map && decoded.containsKey('feedback')) {
          return decoded['feedback'] as List;
        }
        return [];
      }
      throw Exception('Failed to load feedback: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }
}

/// Two-Factor Authentication API endpoints
class TwoFactorApi {
  /// Get 2FA status for current user
  static Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await ApiService.get('/2fa/status');
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Request 2FA setup (sends email code)
  static Future<Map<String, dynamic>> setup() async {
    try {
      final response = await ApiService.post('/2fa/setup', {});
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Enable 2FA with verification code
  static Future<Map<String, dynamic>> enable(String code) async {
    try {
      final response = await ApiService.post('/2fa/enable', {'code': code});
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Disable 2FA
  static Future<Map<String, dynamic>> disable() async {
    try {
      final response = await ApiService.post('/2fa/disable', {});
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Send login 2FA code (no auth required, uses email query param)
  static Future<Map<String, dynamic>> sendLoginCode(String email) async {
    try {
      final url = await ApiService.getBaseUrl();
      final response = await http.post(
        Uri.parse('$url/2fa/send-login-code?email=${Uri.encodeComponent(email)}'),
        headers: {'Accept': 'application/json'},
      );
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Verify login 2FA code (no auth required)
  static Future<Map<String, dynamic>> verifyLoginCode(
    String email,
    String code,
  ) async {
    try {
      final url = await ApiService.getBaseUrl();
      final response = await http.post(
        Uri.parse(
          '$url/2fa/verify-login?email=${Uri.encodeComponent(email)}&code=${Uri.encodeComponent(code)}',
        ),
        headers: {'Accept': 'application/json'},
      );
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }
}

/// Account management API endpoints
class AccountApi {
  /// Delete account (requires password verification)
  static Future<Map<String, dynamic>> deleteAccount(
    String currentPassword,
  ) async {
    try {
      final url = await ApiService.getBaseUrl();
      final token = ApiService.getToken();
      // http.delete doesn't support body, so we use http.Request
      final request = http.Request(
        'DELETE',
        Uri.parse('$url/auth/delete-account'),
      );
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });
      request.body = jsonEncode({'current_password': currentPassword});
      final streamed = await http.Client().send(request);
      final response = await http.Response.fromStream(streamed);
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }
}

/// Settings API endpoints
class SettingsApi {
  /// Get current user's settings from backend
  static Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await ApiService.get('/settings/');
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Update user settings (partial update)
  static Future<Map<String, dynamic>> updateSettings(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await ApiService.put('/settings/', data);
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Reset settings to defaults
  static Future<Map<String, dynamic>> resetSettings() async {
    try {
      final response = await ApiService.post('/settings/reset', {});
      return ApiService.handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }
}
