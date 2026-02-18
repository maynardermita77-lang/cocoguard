import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../services/local_data_service.dart';
import '../services/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/user_service.dart';
import '../services/push_notification_service.dart';
import '../services/translation_service.dart';
import '../models/user.dart';
import '../services/knowledge_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'dashboard_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;

    if (isOnline) {
      try {
        final loginData = await AuthApi.login(username, password);

        // Save user data to UserService (including id)
        if (loginData['user'] != null) {
          final userData = loginData['user'];
          UserService.user.value = User(
            id: userData['id'] ?? 0,
            fullName: userData['full_name'] ?? 'User',
            email: userData['email'] ?? '',
            dob:
                DateTime.tryParse(userData['date_of_birth'] ?? '') ??
                DateTime(2000, 1, 1),
            gender: userData['gender'] ?? '',
            phone: userData['phone'] ?? '',
            location: userData['address_line'] ?? '',
          );
          // Save credentials for offline login (hash password for security)
          final passwordHash = sha256.convert(utf8.encode(password)).toString();
          await LocalDataService.saveUserCredentials(
            username,
            passwordHash,
            loginData['access_token'] ?? '',
          );
          // Save user profile for offline use
          await LocalDataService.saveUserProfile(username, {
            'id': userData['id'] ?? 0,
            'fullName': userData['full_name'] ?? 'User',
            'email': userData['email'] ?? '',
            'dob': userData['date_of_birth'] ?? '',
            'gender': userData['gender'] ?? '',
            'phone': userData['phone'] ?? '',
            'location': userData['address_line'] ?? '',
          });
        }

        // Fetch and cache knowledge articles for offline use (for all users)
        try {
          await KnowledgeService.getArticles();
        } catch (_) {}

        // Register FCM token for push notifications
        try {
          await PushNotificationService.registerTokenAfterLogin();
        } catch (_) {}

        // Login successful, navigate to dashboard
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } catch (e) {
        if (!mounted) return;
        _showLoginError(e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // Offline login: check cached credentials for this user
      try {
        final creds = LocalDataService.getUserCredentials(username);
        if (creds == null) {
          throw Exception(
            'No offline credentials found for this user. Please login online at least once.',
          );
        }
        final passwordHash = sha256.convert(utf8.encode(password)).toString();
        if (creds['passwordHash'] == passwordHash) {
          // Set token if needed, and proceed
          await ApiService.setToken(creds['token']);
          // Load user profile from local cache
          final profile = LocalDataService.getUserProfile(username);
          if (profile != null) {
            UserService.user.value = User(
              id: profile['id'] ?? 0,
              fullName: profile['fullName'] ?? 'User',
              email: profile['email'] ?? '',
              dob:
                  DateTime.tryParse(profile['dob'] ?? '') ??
                  DateTime(2000, 1, 1),
              gender: profile['gender'] ?? '',
              phone: profile['phone'] ?? '',
              location: profile['location'] ?? '',
            );
          }
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        } else {
          throw Exception('Offline login failed. Credentials do not match.');
        }
      } catch (e) {
        if (!mounted) return;
        _showLoginError(e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showLoginError(String message) {
    // Check if it's a connection error
    final isConnectionError =
        message.toLowerCase().contains('connection') ||
        message.toLowerCase().contains('socket') ||
        message.toLowerCase().contains('timeout') ||
        message.toLowerCase().contains('refused') ||
        message.toLowerCase().contains('network') ||
        message.toLowerCase().contains('host');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isConnectionError
              ? tr('login.connection_error')
              : tr('login.login_failed'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isConnectionError
                  ? tr('login.cannot_connect')
                  : tr('login.invalid_credentials'),
            ),
            if (isConnectionError) ...[
              const SizedBox(height: 12),
              Text(
                'Error: $message',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'Error: $message',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('common.ok')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/splash_bg.jpg', fit: BoxFit.cover),
          SingleChildScrollView(
            child: Column(
              children: [
                // White card at TOP
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 25,
                    horizontal: 25,
                  ),
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Column(
                    children: [
                      Text(
                        tr('login.new_era'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFB300),
                          letterSpacing: 1.0,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Palm tree icon
                          const Text('🌴', style: TextStyle(fontSize: 32)),
                          const SizedBox(width: 8),
                          // AGRICULTURE text
                          Text(
                            tr('login.agriculture'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2d7a3e),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'CocoGuard',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tr('login.tagline'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF666666),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                // Login form
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 30,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('login.welcome'),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2d7a3e),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            tr('login.subtitle'),
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 30),
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: tr('login.username_email'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? tr('login.enter_username')
                                : null,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: tr('login.password'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? tr('login.enter_password')
                                : null,
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: Text(tr('login.forgot_password')),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2d7a3e),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      tr('login.login_btn'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RegisterScreen(),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFc6a030),
                                side: const BorderSide(
                                  color: Color(0xFFc6a030),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                tr('login.register_btn'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
