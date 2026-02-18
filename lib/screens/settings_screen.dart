import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';

import '../services/api_endpoints.dart';
import '../services/api_service.dart';
import '../services/theme_service.dart';
import '../services/translation_service.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _language = 'English';

  // Notification & privacy toggles (synced with backend)
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;
  bool _autoBackup = true;
  bool _profileVisible = true;
  bool _dataSharing = false;

  late final Connectivity _connectivity;
  late final Stream<ConnectivityResult> _connectivityStream;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _connectivityStream = _connectivity.onConnectivityChanged;
    _connectivityStream.listen((result) {
      if (result != ConnectivityResult.none) {
        _syncQueuedSettings();
      }
    });
    // Load local values first, then fetch from backend
    final box = Hive.box('cocoguard');
    final lang = box.get('settings_language');
    if (lang != null) _language = lang;
    _loadLocalToggles(box);
    _fetchSettingsFromBackend();
    _syncQueuedSettings();
  }

  void _loadLocalToggles(Box box) {
    _emailNotifications =
        box.get('settings_email_notifications', defaultValue: true) as bool;
    _pushNotifications =
        box.get('settings_push_notifications', defaultValue: true) as bool;
    _smsNotifications =
        box.get('settings_sms_notifications', defaultValue: false) as bool;
    _autoBackup = box.get('settings_auto_backup', defaultValue: true) as bool;
    _profileVisible =
        box.get('settings_profile_visible', defaultValue: true) as bool;
    _dataSharing =
        box.get('settings_data_sharing', defaultValue: false) as bool;
  }

  Future<void> _fetchSettingsFromBackend() async {
    try {
      final data = await SettingsApi.getSettings();
      final box = Hive.box('cocoguard');

      // Language
      final langCode = data['language'] ?? 'en';
      final langLabel = langCode == 'fil' ? 'Filipino' : 'English';
      await box.put('settings_language', langLabel);

      // Theme
      final theme = data['theme'] ?? 'light';
      await box.put('settings_theme', theme);
      if (theme == 'dark') {
        await ThemeService.setDark(true);
      } else {
        await ThemeService.setDark(false);
      }

      // Toggles
      final emailN = data['email_notifications'] ?? true;
      final pushN = data['push_notifications'] ?? true;
      final smsN = data['sms_notifications'] ?? false;
      final autoB = data['auto_backup'] ?? true;
      final profV = data['profile_visible'] ?? true;
      final dataS = data['data_sharing'] ?? false;

      await box.put('settings_email_notifications', emailN);
      await box.put('settings_push_notifications', pushN);
      await box.put('settings_sms_notifications', smsN);
      await box.put('settings_auto_backup', autoB);
      await box.put('settings_profile_visible', profV);
      await box.put('settings_data_sharing', dataS);

      if (mounted) {
        setState(() {
          _language = langLabel;
          _emailNotifications = emailN;
          _pushNotifications = pushN;
          _smsNotifications = smsN;
          _autoBackup = autoB;
          _profileVisible = profV;
          _dataSharing = dataS;
        });
      }
    } catch (_) {
      // Offline — use local values
    }
  }

  Future<void> _syncQueuedSettings() async {
    final box = Hive.box('cocoguard');
    final List<dynamic> queue =
        box.get('settings_update_queue', defaultValue: []) as List<dynamic>;
    if (queue.isEmpty) return;
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return;

    // Merge all queued updates into one map
    final Map<String, dynamic> merged = {};
    for (final update in queue) {
      if (update is Map) {
        merged.addAll(Map<String, dynamic>.from(update));
      }
    }

    try {
      await SettingsApi.updateSettings(merged);
      // Save locally
      if (merged.containsKey('language')) {
        await box.put('settings_language', merged['language']);
      }
      if (merged.containsKey('theme')) {
        await box.put('settings_theme', merged['theme']);
      }
      await box.put('settings_update_queue', []);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('settings.synced')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      // Keep queue for next attempt
    }
  }

  Future<void> _updateSingleSetting(String key, dynamic value) async {
    final box = Hive.box('cocoguard');
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;

    if (isOnline) {
      try {
        await SettingsApi.updateSettings({key: value});
        await box.put('settings_$key', value);
      } catch (e) {
        // Queue for later
        _queueSetting(box, key, value);
      }
    } else {
      _queueSetting(box, key, value);
      await box.put('settings_$key', value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_formatKey(key)} change queued for sync when online.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _queueSetting(Box box, String key, dynamic value) {
    final List<dynamic> queue =
        box.get('settings_update_queue', defaultValue: []) as List<dynamic>;
    queue.add({key: value});
    box.put('settings_update_queue', queue);
  }

  String _formatKey(String key) {
    return key.replaceAll('_', ' ').replaceFirst(key[0], key[0].toUpperCase());
  }

  Future<void> _chooseLanguage() async {
    final sel = await showDialog<String>(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text(tr('settings.language')),
        children: [
          SimpleDialogOption(
            child: const Text('English'),
            onPressed: () => Navigator.pop(c, 'English'),
          ),
          SimpleDialogOption(
            child: const Text('Filipino'),
            onPressed: () => Navigator.pop(c, 'Filipino'),
          ),
        ],
      ),
    );
    if (sel != null) {
      setState(() => _language = sel);
      // Update the translation service so the entire app rebuilds
      TranslationService.instance.setLanguage(sel);
      final langCode = sel == 'Filipino' ? 'fil' : 'en';
      await _updateSingleSetting('language', langCode);
    }
  }

  Future<void> _showPrivacyPolicy() async {
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.policy, color: Color(0xFF2d7a3e)),
            const SizedBox(width: 8),
            Text(tr('settings.privacy_policy')),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'CocoGuard Privacy Policy',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 12),
                Text(
                  'Effective Date: January 1, 2026',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '1. Information We Collect',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'We collect information you provide directly, including your name, email address, phone number, location data, and coconut farm details. '
                  'We also collect images of coconut trees you upload for pest detection analysis.',
                ),
                SizedBox(height: 12),
                Text(
                  '2. How We Use Your Information',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  '- To provide pest detection and identification services\n'
                  '- To maintain your scan history and farm records\n'
                  '- To send notifications about pest alerts in your area\n'
                  '- To improve our pest detection AI models\n'
                  '- To provide personalized recommendations for pest management',
                ),
                SizedBox(height: 12),
                Text(
                  '3. Data Storage & Security',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Your data is stored securely on our servers with encryption. '
                  'Scan images are processed for pest detection and stored alongside your scan records. '
                  'We implement industry-standard security measures to protect your personal information.',
                ),
                SizedBox(height: 12),
                Text(
                  '4. Data Sharing',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'We do not sell or share your personal data with third parties. '
                  'Aggregated, anonymized data may be used for agricultural research to improve pest management strategies in the Philippines.',
                ),
                SizedBox(height: 12),
                Text(
                  '5. Your Rights',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  '- Access and export your personal data at any time\n'
                  '- Request deletion of your account and associated data\n'
                  '- Opt out of email and push notifications\n'
                  '- Control visibility of your profile',
                ),
                SizedBox(height: 12),
                Text(
                  '6. Contact Us',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'For privacy concerns, contact us at:\nsupport@cocoguard.app',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showTermsOfService() async {
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.gavel, color: Color(0xFF2d7a3e)),
            const SizedBox(width: 8),
            Text(tr('settings.terms')),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'CocoGuard Terms of Service',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 12),
                Text(
                  'Last Updated: January 1, 2026',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '1. Acceptance of Terms',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'By using CocoGuard, you agree to these Terms of Service. '
                  'If you do not agree, please discontinue use of the application.',
                ),
                SizedBox(height: 12),
                Text(
                  '2. Service Description',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'CocoGuard is a mobile application that uses artificial intelligence to identify pests affecting coconut trees. '
                  'The app provides pest identification through image analysis and survey assessments, along with management recommendations.',
                ),
                SizedBox(height: 12),
                Text(
                  '3. User Responsibilities',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  '- Provide accurate information during registration\n'
                  '- Keep your account credentials secure\n'
                  '- Use the app only for its intended agricultural purpose\n'
                  '- Do not upload inappropriate or unrelated images\n'
                  '- Report any suspected security issues',
                ),
                SizedBox(height: 12),
                Text(
                  '4. Accuracy Disclaimer',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Pest detection results are provided as guidance and may not be 100% accurate. '
                  'We recommend consulting with agricultural experts for confirmation before applying treatments. '
                  'CocoGuard is not liable for crop damage resulting from reliance on detection results.',
                ),
                SizedBox(height: 12),
                Text(
                  '5. Account Termination',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'We reserve the right to suspend or terminate accounts that violate these terms. '
                  'You may delete your account at any time through the app settings.',
                ),
                SizedBox(height: 12),
                Text(
                  '6. Changes to Terms',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'We may update these terms from time to time. Continued use of the app after changes constitutes acceptance of the new terms.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _dataManagement() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'Data Management',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.download, color: Color(0xFF2d7a3e)),
                title: const Text('Export My Data'),
                subtitle: const Text(
                  'Download all your scan history and profile data',
                ),
                onTap: () => _exportData(c),
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Delete All Data'),
                subtitle: const Text(
                  'Permanently remove all local and server data',
                ),
                onTap: () => _deleteAllData(c),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext sheetContext) async {
    Navigator.pop(sheetContext);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Exporting your data...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      // Gather user profile
      final profile = await AuthApi.getCurrentUser();
      // Gather scan history
      final scans = await ScansApi.getScans();
      // Gather settings
      Map<String, dynamic> settings = {};
      try {
        settings = await SettingsApi.getSettings();
      } catch (_) {}

      final exportData = {
        'exported_at': DateTime.now().toIso8601String(),
        'profile': profile,
        'scan_history': scans,
        'settings': settings,
        'total_scans': scans.length,
      };

      // Save to local Hive for retrieval
      final box = Hive.box('cocoguard');
      await box.put('last_export', jsonEncode(exportData));
      await box.put('last_export_date', DateTime.now().toIso8601String());

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Data exported successfully! (${scans.length} scan records)',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _deleteAllData(BuildContext sheetContext) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Confirm Delete All Data'),
        content: const Text(
          'This will permanently delete:\n\n'
          '• All your scan history\n'
          '• All local cached data\n'
          '• Your settings preferences\n\n'
          'This action cannot be undone. Your account will remain active.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text(
              'Delete Everything',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (conf != true) return;
    if (!mounted) return;
    if (sheetContext.mounted) Navigator.pop(sheetContext);

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Deleting all data...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      // Delete server-side scan data
      await ScansApi.deleteAllScans();
      // Reset settings to defaults
      await SettingsApi.resetSettings();

      // Clear local Hive data
      final box = Hive.box('cocoguard');
      await box.delete('settings_language');
      await box.delete('settings_theme');
      await box.delete('settings_email_notifications');
      await box.delete('settings_push_notifications');
      await box.delete('settings_sms_notifications');
      await box.delete('settings_auto_backup');
      await box.delete('settings_profile_visible');
      await box.delete('settings_data_sharing');
      await box.delete('settings_update_queue');
      await box.delete('last_export');
      await box.delete('last_export_date');

      // Reset local state
      await ThemeService.setDark(false);

      if (mounted) {
        setState(() {
          _language = 'English';
          _emailNotifications = true;
          _pushNotifications = true;
          _smsNotifications = false;
          _autoBackup = true;
          _profileVisible = true;
          _dataSharing = false;
        });
      }

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('All data deleted successfully.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _performLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          tr('settings.logout'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2d7a3e),
          ),
        ),
        content: Text(tr('settings.logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: Text(
              tr('common.cancel'),
              style: const TextStyle(color: Color(0xFF2d7a3e)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(d, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFe64a19),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(tr('settings.logout_yes')),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await AuthApi.logout();
    } catch (_) {
      // logout clears token even on failure
    }

    // Clear local state
    ApiService.clearToken();
    final box = Hive.box('cocoguard');
    await box.delete('settings_update_queue');

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(
                tr('settings.title'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d7a3e),
                ),
              ),
              const SizedBox(height: 16),

              // ───── Account Settings ─────
              _buildSectionCard(
                icon: Icons.person,
                title: tr('settings.account'),
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.edit, color: Color(0xFF2d7a3e)),
                    title: Text(tr('settings.edit_profile')),
                    subtitle: Text(tr('settings.edit_profile_desc')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.lock_outline,
                      color: Color(0xFF2d7a3e),
                    ),
                    title: Text(tr('settings.change_password')),
                    subtitle: Text(tr('settings.change_password_desc')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ───── General Preferences ─────
              _buildSectionCard(
                icon: Icons.tune,
                title: tr('settings.general'),
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.language, color: Colors.green),
                    title: Text(tr('settings.language')),
                    subtitle: Text(
                      '${tr('settings.language_desc')}: $_language',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _chooseLanguage,
                  ),

                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: ThemeService.themeMode,
                    builder: (context, mode, _) {
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(tr('settings.dark_mode')),
                        subtitle: Text(tr('settings.dark_mode_desc')),
                        value: mode == ThemeMode.dark,
                        activeThumbColor: const Color(0xFF2d7a3e),
                        onChanged: (v) async {
                          await ThemeService.setDark(v);
                          await _updateSingleSetting(
                            'theme',
                            v ? 'dark' : 'light',
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ───── Notifications ─────
              _buildSectionCard(
                icon: Icons.notifications,
                title: tr('settings.notifications'),
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr('settings.push_notif')),
                    subtitle: Text(tr('settings.push_notif_desc')),
                    value: _pushNotifications,
                    activeThumbColor: const Color(0xFF2d7a3e),
                    onChanged: (v) async {
                      setState(() => _pushNotifications = v);
                      await _updateSingleSetting('push_notifications', v);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr('settings.email_notif')),
                    subtitle: Text(tr('settings.email_notif_desc')),
                    value: _emailNotifications,
                    activeThumbColor: const Color(0xFF2d7a3e),
                    onChanged: (v) async {
                      setState(() => _emailNotifications = v);
                      await _updateSingleSetting('email_notifications', v);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr('settings.sms_notif')),
                    subtitle: Text(tr('settings.sms_notif_desc')),
                    value: _smsNotifications,
                    activeThumbColor: const Color(0xFF2d7a3e),
                    onChanged: (v) async {
                      setState(() => _smsNotifications = v);
                      await _updateSingleSetting('sms_notifications', v);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ───── Privacy & Security ─────
              _buildSectionCard(
                icon: Icons.lock,
                title: tr('settings.data_mgmt'),
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr('settings.profile_visible')),
                    subtitle: Text(tr('settings.profile_visible_desc')),
                    value: _profileVisible,
                    activeThumbColor: const Color(0xFF2d7a3e),
                    onChanged: (v) async {
                      setState(() => _profileVisible = v);
                      await _updateSingleSetting('profile_visible', v);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr('settings.data_sharing')),
                    subtitle: Text(tr('settings.data_sharing_desc')),
                    value: _dataSharing,
                    activeThumbColor: const Color(0xFF2d7a3e),
                    onChanged: (v) async {
                      setState(() => _dataSharing = v);
                      await _updateSingleSetting('data_sharing', v);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr('settings.auto_backup')),
                    subtitle: Text(tr('settings.auto_backup_desc')),
                    value: _autoBackup,
                    activeThumbColor: const Color(0xFF2d7a3e),
                    onChanged: (v) async {
                      setState(() => _autoBackup = v);
                      await _updateSingleSetting('auto_backup', v);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.policy, color: Colors.grey),
                    title: Text(tr('settings.privacy_policy')),
                    subtitle: const Text('Read our data protection guidelines'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showPrivacyPolicy,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.gavel, color: Colors.grey),
                    title: Text(tr('settings.terms')),
                    subtitle: const Text(
                      "Review the application's terms and conditions",
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showTermsOfService,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.storage, color: Colors.grey),
                    title: Text(tr('settings.data_mgmt')),
                    subtitle: Text(tr('settings.export_data_desc')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _dataManagement,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ───── App Information & Logout ─────
              _buildSectionCard(
                icon: Icons.info_outline,
                title: tr('settings.app_info'),
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.info, color: Colors.green),
                    title: Text(tr('settings.about')),
                    subtitle: const Text('Version 1.0.0'),
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'CocoGuard',
                      applicationVersion: '1.0.0',
                      applicationIcon: Image.asset(
                        'assets/icons/app_icon.png',
                        width: 48,
                        height: 48,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.eco,
                          size: 48,
                          color: Color(0xFF2d7a3e),
                        ),
                      ),
                      children: [Text(tr('settings.about_desc'))],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _performLogout,
                      icon: const Icon(Icons.logout),
                      label: Text(tr('settings.logout')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFe64a19),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF2d7a3e)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}
