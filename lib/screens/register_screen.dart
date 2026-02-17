import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../services/api_endpoints.dart';
import '../utils/ph_locations.dart';
import '../services/translation_service.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import '../services/knowledge_service.dart';
import 'email_verification_screen.dart';
import 'dashboard_screen.dart';
import '../services/google_auth.dart';

// Attempt to import google_sign_in; works when package is available.
import 'package:google_sign_in/google_sign_in.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();

  String? _selectedRegion;
  String _selectedGender = 'Male';
  String? _selectedProvince;
  String? _selectedCity;
  String? _selectedBarangay;
  bool _agreedToPrivacy = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isGoogleLoading = false;

  List<String> _provinces = [];
  List<String> _cities = [];
  List<String> _barangays = [];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // Google OAuth Client ID
  static const _googleClientId =
      '744113878334-1u1jrh1f515176ul8d1hn9rg5tjm9d4f.apps.googleusercontent.com';

  // ── Google Sign-In ──────────────────────────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      String? accessToken;
      String? email;
      String? displayName;

      if (kIsWeb) {
        // ── Web: use GIS directly (avoids People API & deprecated signIn) ──
        accessToken = await requestGoogleAccessToken(_googleClientId);
        if (accessToken == null) {
          // User cancelled the popup
          if (mounted) setState(() => _isGoogleLoading = false);
          return;
        }

        // Fetch user info from Google's userinfo endpoint (no People API needed)
        final userInfoResp = await http.get(
          Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
          headers: {'Authorization': 'Bearer $accessToken'},
        );
        if (userInfoResp.statusCode != 200) {
          throw Exception('Failed to get Google user info.');
        }
        final userInfo = jsonDecode(userInfoResp.body);
        email = userInfo['email'] as String?;
        displayName = userInfo['name'] as String?;
        if (email == null || email.isEmpty) {
          throw Exception('Could not get email from Google account.');
        }
      } else {
        // ── Mobile: use google_sign_in package (works fine natively) ──
        final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          if (mounted) setState(() => _isGoogleLoading = false);
          return;
        }
        final googleAuth = await googleUser.authentication;
        accessToken = googleAuth.accessToken;
        email = googleUser.email;
        displayName = googleUser.displayName;
        if (accessToken == null) {
          throw Exception('Failed to get Google access token.');
        }
      }

      if (!mounted) return;

      // ── Show Set-Password dialog ──
      final password = await _showSetPasswordDialog(email, displayName ?? '');
      if (password == null) {
        // User cancelled
        if (mounted) setState(() => _isGoogleLoading = false);
        return;
      }

      // ── Call backend with access_token + password ──
      final result = await PublicRegisterApi.googleSignInWithAccessToken(
        accessToken: accessToken,
        password: password,
      );

      if (result['user'] != null) {
        final userData = result['user'];
        UserService.user.value = User(
          id: userData['id'] ?? 0,
          fullName: userData['full_name'] ?? displayName ?? 'User',
          email: userData['email'] ?? email,
          dob:
              DateTime.tryParse(userData['date_of_birth'] ?? '') ??
              DateTime(2000, 1, 1),
          gender: userData['gender'] ?? '',
          phone: userData['phone'] ?? '',
          location: userData['address_line'] ?? '',
        );
        try {
          await KnowledgeService.getArticles();
        } catch (_) {}
      }

      if (!mounted) return;

      final isNew = result['is_new_user'] == true;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF2d7a3e),
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(isNew ? 'Account Created!' : 'Welcome Back!'),
              ),
            ],
          ),
          content: Text(
            isNew
                ? 'Your account has been created successfully.\n\n'
                      'You can now log in with:\n'
                      'Email: $email\n'
                      'Password: (the one you just set)'
                : 'You have been signed in successfully.\n'
                      'Your password has been updated.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                tr('common.ok'),
                style: const TextStyle(color: Color(0xFF2d7a3e)),
              ),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      final errMsg = e.toString();
      if (errMsg.contains('popup_closed')) {
        // User closed the popup — do nothing
      } else if (errMsg.contains('ClientID not set') ||
          errMsg.contains('appClientId != null')) {
        _showErrorDialog(
          'Google Sign-In is not configured yet.\n\n'
          'Please use the email registration form below instead.',
        );
      } else {
        _showErrorDialog('Google Sign-In failed:\n$errMsg');
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  /// Dialog that asks the user to set a password for their CocoGuard account
  /// after authenticating with Google.
  Future<String?> _showSetPasswordDialog(
    String email,
    String displayName,
  ) async {
    final passwordCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscurePassword = true;
    bool obscureConfirm = true;
    String? errorText;

    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Image.network(
                'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                height: 24,
                width: 24,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.g_mobiledata, size: 24, color: Colors.red),
              ),
              const SizedBox(width: 10),
              const Expanded(child: Text('Set Your Password')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (displayName.isNotEmpty)
                  Text(
                    'Welcome, $displayName!',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Create a password so you can also log in\n'
                  'with your email and password.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordCtrl,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setDialogState(
                          () => obscurePassword = !obscurePassword,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmCtrl,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setDialogState(() => obscureConfirm = !obscureConfirm);
                      },
                    ),
                  ),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorText!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (passwordCtrl.text.isEmpty) {
                  setDialogState(() => errorText = 'Password is required.');
                  return;
                }
                if (passwordCtrl.text.length < 6) {
                  setDialogState(
                    () => errorText = 'Password must be at least 6 characters.',
                  );
                  return;
                }
                if (passwordCtrl.text != confirmCtrl.text) {
                  setDialogState(() => errorText = 'Passwords do not match.');
                  return;
                }
                Navigator.pop(context, passwordCtrl.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2d7a3e),
                foregroundColor: Colors.white,
              ),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Email-verified Registration ─────────────────────────────────────────
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreedToPrivacy) {
      _showErrorDialog(tr('register.agree_privacy'));
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog(tr('register.passwords_mismatch'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Parse date of birth
      String? dobString;
      if (_dobController.text.isNotEmpty) {
        try {
          final parts = _dobController.text.split('/');
          final dob = DateTime(
            int.parse(parts[2]),
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
          dobString = dob.toIso8601String().split('T')[0];
        } catch (e) {
          // Invalid date format
        }
      }

      // Step 1: Navigate to email verification screen
      final email = _emailController.text.trim();
      if (!mounted) return;
      final verifiedCode = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => EmailVerificationScreen(email: email),
        ),
      );

      if (verifiedCode == null) {
        // User cancelled verification
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Step 2: Complete registration with verified code
      final regData = await PublicRegisterApi.registerWithVerifiedEmail(
        email: email,
        password: _passwordController.text,
        code: verifiedCode,
        fullName: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        gender: _selectedGender,
        dateOfBirth: dobString,
        region: _selectedRegion,
        province: _selectedProvince,
        city: _selectedCity,
        barangay: _selectedBarangay,
        addressLine: _addressController.text.trim(),
      );

      if (regData['user'] != null) {
        final userData = regData['user'];
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
        // Fetch and cache knowledge articles for offline use (for all users)
        try {
          await KnowledgeService.getArticles();
        } catch (_) {}
      } else {
        // ...existing code...
      }

      if (!mounted) return;

      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF2d7a3e),
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(tr('register.success')),
            ],
          ),
          content: Text(tr('register.success_msg')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                tr('common.ok'),
                style: TextStyle(color: Color(0xFF2d7a3e)),
              ),
            ),
          ],
        ),
      );

      if (!mounted) return;

      // Navigate to login screen
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('${tr('register.failed')}: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('common.error')),
        content: Text(message),
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
        children: [
          // Background image
          Image.asset(
            'assets/images/register_bg.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 22,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Column(
                                children: [
                                  const Text(
                                    '🌴',
                                    style: TextStyle(fontSize: 64),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'CocoGuard',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFe6b800),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                            const Text(
                              'Maligayang Pagdating!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tr('register.create_account'),
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 16),
                            // ── Manual Registration Form ──
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: tr('register.full_name'),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return tr('register.enter_name');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: tr('register.email'),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return tr('register.enter_email');
                                }
                                if (!value.contains('@')) {
                                  return tr('register.valid_email');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: tr('register.username'),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return tr('register.enter_username');
                                }
                                if (value.trim().length < 3) {
                                  return tr('register.username_min');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: tr('register.phone'),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (value.length < 10) {
                                    return tr('register.phone_min');
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedGender,
                              decoration: InputDecoration(
                                labelText: tr('register.gender'),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: ['Male', 'Female', 'Other'].map((gender) {
                                return DropdownMenuItem(
                                  value: gender,
                                  child: Text(gender),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedGender = value!;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _dobController,
                              decoration: InputDecoration(
                                labelText: tr('register.dob'),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.calendar_today),
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime(2000, 1, 1),
                                      firstDate: DateTime(1950),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _dobController.text =
                                            '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
                                      });
                                    }
                                  },
                                ),
                              ),
                              readOnly: true,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _addressController,
                              decoration: InputDecoration(
                                labelText: tr('register.address'),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return tr('register.enter_address');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedRegion,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: tr('register.region'),
                                prefixIcon: const Icon(Icons.map),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: PhilippineLocations.regions.map((region) {
                                return DropdownMenuItem(
                                  value: region,
                                  child: Text(
                                    region,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedRegion = value;
                                  _selectedProvince = null;
                                  _selectedCity = null;
                                  _selectedBarangay = null;
                                  _provinces = value != null
                                      ? PhilippineLocations.getProvinces(value)
                                      : [];
                                  _cities = [];
                                  _barangays = [];
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedProvince,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: tr('register.province'),
                                prefixIcon: const Icon(Icons.location_city),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: _provinces.map((province) {
                                return DropdownMenuItem(
                                  value: province,
                                  child: Text(province),
                                );
                              }).toList(),
                              onChanged: _provinces.isEmpty
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _selectedProvince = value;
                                        _selectedCity = null;
                                        _selectedBarangay = null;
                                        _cities = value != null
                                            ? PhilippineLocations.getCities(
                                                value,
                                              )
                                            : [];
                                        _barangays = [];
                                      });
                                    },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedCity,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: tr('register.city'),
                                prefixIcon: const Icon(
                                  Icons.location_city_outlined,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: _cities.map((city) {
                                return DropdownMenuItem(
                                  value: city,
                                  child: Text(city),
                                );
                              }).toList(),
                              onChanged: _cities.isEmpty
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _selectedCity = value;
                                        _selectedBarangay = null;
                                        _barangays = value != null
                                            ? PhilippineLocations.getBarangays(
                                                value,
                                              )
                                            : [];
                                      });
                                    },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedBarangay,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: tr('register.barangay'),
                                prefixIcon: const Icon(Icons.home_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: _barangays.map((barangay) {
                                return DropdownMenuItem(
                                  value: barangay,
                                  child: Text(barangay),
                                );
                              }).toList(),
                              onChanged: _barangays.isEmpty
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _selectedBarangay = value;
                                      });
                                    },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: tr('register.password'),
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
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return tr('register.enter_password');
                                }
                                if (value.length < 6) {
                                  return tr('register.password_min');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                labelText: tr('register.confirm_password'),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return tr('register.confirm_pw_required');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Checkbox(
                                  value: _agreedToPrivacy,
                                  onChanged: (v) => setState(
                                    () => _agreedToPrivacy = v ?? false,
                                  ),
                                ),
                                Expanded(
                                  child: Wrap(
                                    children: [
                                      Text(tr('register.agree_text')),
                                      GestureDetector(
                                        onTap: () => showDialog<void>(
                                          context: context,
                                          builder: (d) => AlertDialog(
                                            title: Text(
                                              tr('register.data_privacy'),
                                            ),
                                            content: Text(
                                              tr('register.data_privacy_msg'),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(d),
                                                child: Text(tr('common.ok')),
                                              ),
                                            ],
                                          ),
                                        ),
                                        child: Text(
                                          tr('register.data_privacy'),
                                          style: const TextStyle(
                                            decoration:
                                                TextDecoration.underline,
                                            color: Color(0xFF2d7a3e),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2d7a3e),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
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
                                        tr('register.register_btn'),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(tr('register.have_account')),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // ── OR Divider (bottom) ──
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(color: Colors.grey[400]),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(color: Colors.grey[400]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // ── Google Sign-In Button (bottom) ──
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: _isGoogleLoading
                                    ? null
                                    : _handleGoogleSignIn,
                                icon: _isGoogleLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.g_mobiledata,
                                        size: 28,
                                        color: Colors.red,
                                      ),
                                label: const Text(
                                  'Sign up with Google',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black87,
                                  side: const BorderSide(color: Colors.black26),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
