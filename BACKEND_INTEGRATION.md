# CocoGuard Flutter Mobile App - Backend Integration Guide

## Setup Steps

### 1. Update pubspec.yaml

Add these dependencies to your Flutter project:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  dio: ^5.3.0
  shared_preferences: ^2.2.0
  image_picker: ^1.0.0
  permission_handler: ^11.4.0
  geolocator: ^9.0.0
  provider: ^6.0.0
  intl: ^0.18.0
```

### 2. Create API Service Class

Create `lib/services/api_service.dart`:

```dart
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator
  // static const String baseUrl = 'http://localhost:8000'; // Web/iOS
  
  static String? _token;
  
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
  }
  
  static void setToken(String token) {
    _token = token;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('access_token', token);
    });
  }
  
  static void clearToken() {
    _token = null;
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('access_token');
    });
  }
  
  static Future<http.Response> get(String endpoint) async {
    final headers = _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    return response;
  }
  
  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return response;
  }
  
  static Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final headers = _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return response;
  }
  
  static Future<http.Response> delete(String endpoint) async {
    final headers = _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    return response;
  }
  
  static Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }
  
  // Auth Endpoints
  static Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await post('/auth/register', data);
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      setToken(result['access_token']);
      return result;
    } else {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Registration failed');
    }
  }
  
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await post('/auth/login', {
      'email_or_username': email,
      'password': password,
    });
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      setToken(result['access_token']);
      return result;
    } else {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Login failed');
    }
  }
  
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await get('/users/me');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get user');
    }
  }
  
  // Farm Endpoints
  static Future<List<dynamic>> listFarms() async {
    final response = await get('/farms');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load farms');
    }
  }
  
  static Future<Map<String, dynamic>> createFarm(Map<String, dynamic> data) async {
    final response = await post('/farms', data);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Failed to create farm');
    }
  }
  
  // Scan Endpoints
  static Future<Map<String, dynamic>> createScan(Map<String, dynamic> data) async {
    final response = await post('/scans', data);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Failed to create scan');
    }
  }
  
  static Future<List<dynamic>> listMyScans() async {
    final response = await get('/scans/my-scans');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load scans');
    }
  }
  
  // Pest Types
  static Future<List<dynamic>> listPestTypes() async {
    final response = await get('/pest-types');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load pest types');
    }
  }
  
  // Analytics
  static Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await get('/analytics/dashboard/summary');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load dashboard');
    }
  }
  
  // Knowledge Base
  static Future<List<dynamic>> listKnowledgeArticles() async {
    final response = await get('/knowledge');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load articles');
    }
  }
}
```

### 3. Update Main App

Update your `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CocoGuard',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
```

### 4. Use API in Widgets

Example login screen:

```dart
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  Future<void> handleLogin() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.login(
        emailController.text,
        passwordController.text,
      );
      
      // Navigate to dashboard
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CocoGuard Login')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : handleLogin,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
```

### 5. Handle Image Upload

For scan image upload:

```dart
import 'package:image_picker/image_picker.dart';

Future<void> uploadScanImage() async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.camera);
  
  if (image != null) {
    // Use Dio for file upload
    final dio = Dio();
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(image.path),
    });
    
    try {
      final response = await dio.post(
        '${ApiService.baseUrl}/uploads/scan-image',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${ApiService._token}',
          },
        ),
      );
      print('Upload successful: ${response.data}');
    } catch (e) {
      print('Upload error: $e');
    }
  }
}
```

## Testing

1. Ensure backend is running: `uvicorn app.main:app --reload`
2. Update API base URL for your platform (Android emulator vs iOS vs web)
3. Run Flutter app: `flutter run`
4. Test login, scan creation, and other features

## Troubleshooting

- **Connection refused**: Check backend is running and base URL is correct
- **Emulator can't reach localhost**: Use `10.0.2.2` for Android emulator
- **CORS errors**: Backend already allows all origins (configure in production)
