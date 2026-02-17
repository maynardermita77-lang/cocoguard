import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_endpoints.dart';
import '../services/translation_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _codeController = TextEditingController();

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  // Multi-step flow
  int _currentStep = 1; // 1 = passwords, 2 = verification code
  String _userEmail = '';
  int _resendCountdown = 0;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60;
    });
    _countdown();
  }

  void _countdown() async {
    while (_resendCountdown > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendCountdown--;
        });
      }
    }
  }

  Future<void> _requestVerificationCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Request verification code
      final response = await AuthApi.requestChangePasswordCode(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          _currentStep = 2;
          _userEmail = response['email'] ?? '';
        });
        _startResendCountdown();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tr('change_pw.code_sent')} $_userEmail'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? tr('change_pw.failed_send')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      String errorMessage = tr('change_pw.failed_send');
      if (e.toString().contains('Current password is incorrect')) {
        errorMessage = tr('change_pw.incorrect');
      } else if (e.toString().contains('New password must be at least')) {
        errorMessage = tr('change_pw.min_length');
      } else if (e.toString().contains('401')) {
        errorMessage = tr('change_pw.session_expired');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyAndChangePassword() async {
    if (_codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('change_pw.enter_6digit')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthApi.verifyAndChangePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
        _codeController.text,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('change_pw.success')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? tr('change_pw.failed')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      String errorMessage = tr('change_pw.failed');
      if (e.toString().contains('Invalid or expired')) {
        errorMessage = tr('change_pw.invalid_code');
      } else if (e.toString().contains('Current password is incorrect')) {
        errorMessage = tr('change_pw.incorrect');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthApi.requestChangePasswordCode(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        _startResendCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('change_pw.new_code_sent')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('change_pw.failed_resend')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return tr('change_pw.required');
    }
    if (value.length < 6) {
      return tr('change_pw.min_length');
    }
    return null;
  }

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return tr('change_pw.current_required');
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return tr('change_pw.confirm_required');
    }
    if (value != _newPasswordController.text) {
      return tr('change_pw.mismatch');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('change_pw.title')),
        backgroundColor: const Color(0xFF2d7a3e),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep == 2) {
              setState(() {
                _currentStep = 1;
                _codeController.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _currentStep == 1
              ? _buildPasswordForm()
              : _buildVerificationForm(),
        ),
      ),
    );
  }

  Widget _buildPasswordForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            tr('change_pw.update'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2d7a3e),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr('change_pw.description'),
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          // Current Password Field
          TextFormField(
            controller: _currentPasswordController,
            obscureText: !_showCurrentPassword,
            decoration: InputDecoration(
              labelText: tr('change_pw.current'),
              hintText: tr('change_pw.current_hint'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF2d7a3e),
                  width: 2,
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _showCurrentPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _showCurrentPassword = !_showCurrentPassword;
                  });
                },
              ),
            ),
            validator: _validateCurrentPassword,
          ),
          const SizedBox(height: 20),
          // New Password Field
          TextFormField(
            controller: _newPasswordController,
            obscureText: !_showNewPassword,
            decoration: InputDecoration(
              labelText: tr('change_pw.new'),
              hintText: tr('change_pw.new_hint'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF2d7a3e),
                  width: 2,
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _showNewPassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _showNewPassword = !_showNewPassword;
                  });
                },
              ),
            ),
            validator: _validatePassword,
          ),
          const SizedBox(height: 20),
          // Confirm Password Field
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_showConfirmPassword,
            decoration: InputDecoration(
              labelText: tr('change_pw.confirm'),
              hintText: tr('change_pw.confirm_hint'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF2d7a3e),
                  width: 2,
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _showConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _showConfirmPassword = !_showConfirmPassword;
                  });
                },
              ),
            ),
            validator: _validateConfirmPassword,
          ),
          const SizedBox(height: 32),
          // Send Code Button
          ElevatedButton(
            onPressed: _isLoading ? null : _requestVerificationCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2d7a3e),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    tr('change_pw.send_code'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          // Cancel Button
          OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2d7a3e),
              side: const BorderSide(color: Color(0xFF2d7a3e)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              tr('common.cancel'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        // Email icon
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF2d7a3e).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.email_outlined,
              size: 40,
              color: Color(0xFF2d7a3e),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          tr('change_pw.enter_code'),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2d7a3e),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          '${tr('change_pw.we_sent_code')}\n$_userEmail',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        // Code input field
        TextFormField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: tr('change_pw.code_label'),
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2d7a3e), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Resend code
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              tr('change_pw.didnt_receive'),
              style: const TextStyle(color: Colors.grey),
            ),
            GestureDetector(
              onTap: _resendCountdown > 0 ? null : _resendCode,
              child: Text(
                _resendCountdown > 0
                    ? '${tr('change_pw.resend_in')} ${_resendCountdown}s'
                    : tr('change_pw.resend'),
                style: TextStyle(
                  color: _resendCountdown > 0
                      ? Colors.grey
                      : const Color(0xFF2d7a3e),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Verify and Change Password Button
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyAndChangePassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2d7a3e),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            disabledBackgroundColor: Colors.grey[300],
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  tr('change_pw.verify_change'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: 16),
        // Back Button
        OutlinedButton(
          onPressed: _isLoading
              ? null
              : () {
                  setState(() {
                    _currentStep = 1;
                    _codeController.clear();
                  });
                },
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2d7a3e),
            side: const BorderSide(color: Color(0xFF2d7a3e)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            tr('change_pw.back'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
