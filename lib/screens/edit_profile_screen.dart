import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import '../services/api_endpoints.dart';
import '../services/api_service.dart';
import '../utils/ph_locations.dart';
import '../services/translation_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLineController = TextEditingController();
  final _dobController = TextEditingController();
  String _selectedGender = 'Male';

  String? _selectedRegion;
  String? _selectedProvince;
  String? _selectedCity;
  String? _selectedBarangay;

  List<String> _provinces = [];
  List<String> _cities = [];
  List<String> _barangays = [];

  bool _isLoading = true;
  bool _isSaving = false;

  late final Connectivity _connectivity;
  late final Stream<ConnectivityResult> _connectivityStream;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _connectivityStream = _connectivity.onConnectivityChanged;
    _connectivityStream.listen((result) {
      if (result != ConnectivityResult.none) {
        _syncQueuedProfileUpdates();
      }
    });
    // Try to sync on startup if online
    _syncQueuedProfileUpdates();
    _loadUserData();
  }

  Future<void> _syncQueuedProfileUpdates() async {
    final box = Hive.box('cocoguard');
    final List<dynamic> queue =
        box.get('profile_update_queue', defaultValue: []) as List<dynamic>;
    if (queue.isEmpty) return;
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return;
    final List<Map<String, dynamic>> updates = List<Map<String, dynamic>>.from(
      queue,
    );
    final List<Map<String, dynamic>> failed = [];
    for (final update in updates) {
      try {
        final response = await AuthApi.updateProfile(update);
        if (response['success'] != true) {
          failed.add(update);
        }
      } catch (_) {
        failed.add(update);
      }
    }
    await box.put('profile_update_queue', failed);
    if (failed.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('edit_profile.synced')),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await AuthApi.getCurrentUser();
      if (mounted) {
        setState(() {
          _nameController.text = userData['full_name'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _selectedGender = userData['gender'] ?? 'Male';

          // Load address data
          _addressLineController.text = userData['address_line'] ?? '';
          _selectedRegion = userData['region'];
          _selectedProvince = userData['province'];
          _selectedCity = userData['city'];
          _selectedBarangay = userData['barangay'];

          // Load dependent dropdowns
          if (_selectedRegion != null) {
            _provinces = PhilippineLocations.getProvinces(_selectedRegion!);
          }
          if (_selectedProvince != null) {
            _cities = PhilippineLocations.getCities(_selectedProvince!);
          }
          if (_selectedCity != null) {
            _barangays = PhilippineLocations.getBarangays(_selectedCity!);
          }

          // Parse date of birth
          if (userData['date_of_birth'] != null) {
            try {
              final dob = DateTime.parse(userData['date_of_birth']);
              _dobController.text = DateFormat('MM/dd/yyyy').format(dob);
            } catch (e) {
              _dobController.text = '';
            }
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressLineController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

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
        debugPrint('Date parsing error: $e');
      }
    }

    // Prepare update data
    final updateData = {
      'full_name': _nameController.text,
      'phone': _phoneController.text,
      'gender': _selectedGender,
      'address_line': _addressLineController.text,
      'region': _selectedRegion,
      'province': _selectedProvince,
      'city': _selectedCity,
      'barangay': _selectedBarangay,
      if (dobString != null) 'date_of_birth': dobString,
    };

    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;
    final box = Hive.box('cocoguard');

    if (isOnline) {
      try {
        final response = await AuthApi.updateProfile(updateData);
        if (!mounted) return;
        if (response['success'] == true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // Try to sync any queued updates
          final List<dynamic> queue =
              box.get('profile_update_queue', defaultValue: [])
                  as List<dynamic>;
          if (queue.isNotEmpty) {
            for (final update in List<Map<String, dynamic>>.from(queue)) {
              try {
                await AuthApi.updateProfile(update);
                queue.remove(update);
              } catch (_) {}
            }
            await box.put('profile_update_queue', queue);
          }
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.of(context).pop(true); // Return true to trigger refresh
            }
          });
        } else {
          throw Exception(response['message'] ?? 'Failed to update profile');
        }
      } catch (e) {
        // If error, queue update for later sync
        final List<dynamic> queue =
            box.get('profile_update_queue', defaultValue: []) as List<dynamic>;
        queue.add(updateData);
        await box.put('profile_update_queue', queue);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('edit_profile.queued')),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    } else {
      // Offline: queue update
      final List<dynamic> queue =
          box.get('profile_update_queue', defaultValue: []) as List<dynamic>;
      queue.add(updateData);
      await box.put('profile_update_queue', queue);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('edit_profile.queued')),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return tr('edit_profile.name_required');
    }
    if (value.length < 2) {
      return tr('edit_profile.name_min');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(tr('edit_profile.title')),
          backgroundColor: const Color(0xFF2d7a3e),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF2d7a3e)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('edit_profile.title')),
        backgroundColor: const Color(0xFF2d7a3e),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Text(
                  tr('edit_profile.heading'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2d7a3e),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tr('edit_profile.description'),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                // Full Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: tr('edit_profile.full_name'),
                    hintText: tr('edit_profile.full_name_hint'),
                    prefixIcon: const Icon(Icons.person),
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
                  ),
                  validator: _validateName,
                ),
                const SizedBox(height: 16),
                // Phone Number Field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: tr('edit_profile.phone'),
                    hintText: tr('edit_profile.phone_hint'),
                    prefixIcon: const Icon(Icons.phone),
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
                  ),
                ),
                const SizedBox(height: 16),
                // Gender Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedGender,
                  decoration: InputDecoration(
                    labelText: tr('edit_profile.gender'),
                    prefixIcon: const Icon(Icons.person_outline),
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
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                    DropdownMenuItem(
                      value: 'Prefer not to say',
                      child: Text('Prefer not to say'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedGender = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 16),
                // Date of Birth Field
                TextFormField(
                  controller: _dobController,
                  decoration: InputDecoration(
                    labelText: tr('edit_profile.dob'),
                    hintText: tr('edit_profile.dob_hint'),
                    prefixIcon: const Icon(Icons.calendar_today),
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
                  ),
                  readOnly: true,
                  onTap: _selectDate,
                ),
                const SizedBox(height: 16),
                // Region Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedRegion,
                  decoration: InputDecoration(
                    labelText: tr('edit_profile.region'),
                    prefixIcon: const Icon(Icons.map),
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
                  ),
                  items: PhilippineLocations.regions.map((region) {
                    return DropdownMenuItem(
                      value: region,
                      child: Text(region, style: const TextStyle(fontSize: 13)),
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
                const SizedBox(height: 16),
                // Province Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedProvince,
                  decoration: InputDecoration(
                    labelText: tr('edit_profile.province'),
                    prefixIcon: const Icon(Icons.location_city),
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
                                ? PhilippineLocations.getCities(value)
                                : [];
                            _barangays = [];
                          });
                        },
                ),
                const SizedBox(height: 16),
                // City/Municipality Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedCity,
                  decoration: InputDecoration(
                    labelText: tr('edit_profile.city'),
                    prefixIcon: const Icon(Icons.location_city_outlined),
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
                  ),
                  items: _cities.map((city) {
                    return DropdownMenuItem(value: city, child: Text(city));
                  }).toList(),
                  onChanged: _cities.isEmpty
                      ? null
                      : (value) {
                          setState(() {
                            _selectedCity = value;
                            _selectedBarangay = null;
                            _barangays = value != null
                                ? PhilippineLocations.getBarangays(value)
                                : [];
                          });
                        },
                ),
                const SizedBox(height: 16),
                // Barangay Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedBarangay,
                  decoration: InputDecoration(
                    labelText: tr('edit_profile.barangay'),
                    prefixIcon: const Icon(Icons.home_outlined),
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
                const SizedBox(height: 16),
                // Address Line Field
                TextFormField(
                  controller: _addressLineController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: tr('edit_profile.street'),
                    hintText: tr('edit_profile.street_hint'),
                    prefixIcon: const Icon(Icons.home),
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
                  ),
                ),
                const SizedBox(height: 32),
                // Save Button
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2d7a3e),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          tr('edit_profile.save'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                // Cancel Button
                OutlinedButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2d7a3e),
                    side: const BorderSide(color: Color(0xFF2d7a3e)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    tr('common.cancel'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Email Verification Dialog
class _EmailVerificationDialog extends StatefulWidget {
  final String email;

  const _EmailVerificationDialog({required this.email});

  @override
  State<_EmailVerificationDialog> createState() =>
      _EmailVerificationDialogState();
}

class _EmailVerificationDialogState extends State<_EmailVerificationDialog> {
  final _codeController = TextEditingController();
  bool _isVerifying = false;
  bool _codeSent = false;
  int _resendTimer = 60;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _isVerifying = true;
    });

    try {
      // Debug logging
      debugPrint('Token present: ${ApiService.isAuthenticated()}');
      debugPrint('Sending email verification to: ${widget.email}');

      // Send verification code via API
      final result = await AuthApi.sendVerificationCode('email', widget.email);

      if (mounted) {
        setState(() {
          _codeSent = true;
          _isVerifying = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Verification code sent to your email!',
            ),
            backgroundColor: result['success'] == true
                ? Colors.green
                : Colors.orange,
          ),
        );

        // Start countdown timer
        _startTimer();
      }
    } catch (e) {
      debugPrint('Send code error: $e');
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send verification code: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
        _startTimer();
      }
    });
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a 6-digit code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      // Verify code via API
      final result = await AuthApi.verifyCode(
        'email',
        widget.email,
        _codeController.text,
      );

      if (mounted) {
        if (result['success'] == true) {
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _isVerifying = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Invalid verification code'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Verify Email',
        style: TextStyle(color: Color(0xFF2d7a3e), fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'We will send a 6-digit verification code to:',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            widget.email,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (_codeSent) ...[
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Verification Code',
                hintText: 'Enter 6-digit code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _resendTimer > 0
                      ? 'Resend in ${_resendTimer}s'
                      : 'Didn\'t receive code?',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (_resendTimer == 0)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _resendTimer = 60;
                      });
                      _sendCode();
                    },
                    child: const Text('Resend'),
                  ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isVerifying
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isVerifying
              ? null
              : _codeSent
              ? _verifyCode
              : _sendCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2d7a3e),
            foregroundColor: Colors.white,
          ),
          child: _isVerifying
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(_codeSent ? 'Verify' : 'Send Code'),
        ),
      ],
    );
  }
}
