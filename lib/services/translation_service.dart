import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Lightweight translation service for English/Filipino
/// Use `tr(key)` anywhere to get translated text.
class TranslationService extends ChangeNotifier {
  TranslationService._();
  static final TranslationService instance = TranslationService._();

  String _lang = 'English';
  String get currentLanguage => _lang;
  String get langCode => _lang == 'Filipino' ? 'fil' : 'en';

  /// Initialize from Hive
  Future<void> init() async {
    final box = Hive.box('cocoguard');
    _lang = box.get('settings_language', defaultValue: 'English') as String;
  }

  /// Switch language and notify listeners
  void setLanguage(String language) {
    if (_lang == language) return;
    _lang = language;
    final box = Hive.box('cocoguard');
    box.put('settings_language', language);
    notifyListeners();
  }

  /// Get translated text
  String t(String key, [String? fallback]) {
    final code = langCode;
    final entry = _translations[key];
    if (entry == null) return fallback ?? key;
    return entry[code] ?? entry['en'] ?? fallback ?? key;
  }

  // ══════════════════════════════════════════════════════════════════
  // TRANSLATION DICTIONARY
  // ══════════════════════════════════════════════════════════════════

  static const Map<String, Map<String, String>> _translations = {
    // ─── NAVIGATION / BOTTOM BAR ───
    'nav.home': {'en': 'Home', 'fil': 'Home'},
    'nav.camera': {'en': 'Camera', 'fil': 'Camera'},
    'nav.history': {'en': 'History', 'fil': 'Kasaysayan'},
    'nav.profile': {'en': 'Profile', 'fil': 'Profile'},

    // ─── DASHBOARD HOME ───
    'dashboard.greeting': {'en': 'Good Day!', 'fil': 'Magandang Araw!'},
    'dashboard.menu': {'en': 'Menu', 'fil': 'Menu'},
    'dashboard.features': {'en': 'Features', 'fil': 'Mga Features'},
    'dashboard.camera': {'en': 'Camera', 'fil': 'Camera'},
    'dashboard.history': {'en': 'History', 'fil': 'Kasaysayan'},
    'dashboard.knowledge': {'en': 'Knowledge', 'fil': 'Kaalaman'},
    'dashboard.directories': {'en': 'Directories', 'fil': 'Mga Direktoryo'},
    'dashboard.infographic': {'en': 'Infographic', 'fil': 'Infographic'},
    'dashboard.dashboard': {'en': 'Dashboard', 'fil': 'Dashboard'},
    'dashboard.profile': {'en': 'Profile', 'fil': 'Profile'},
    'dashboard.settings': {'en': 'Settings', 'fil': 'Mga Setting'},
    'dashboard.loading': {'en': 'Loading...', 'fil': 'Naglo-load...'},
    'dashboard.celsius': {'en': '°C', 'fil': '°C'},
    'dashboard.founding_anniversary': {
      'en': 'Founding Anniversary',
      'fil': 'Anibersaryo ng Pagkakatatag',
    },
    'dashboard.version': {'en': 'Version 1.0.0', 'fil': 'Bersyon 1.0.0'},
    'dashboard.location_unavailable': {
      'en': 'Location unavailable',
      'fil': 'Hindi available ang lokasyon',
    },

    // ─── SETTINGS SCREEN ───
    'settings.title': {'en': 'Settings', 'fil': 'Mga Setting'},
    'settings.account': {
      'en': 'Account Settings',
      'fil': 'Mga Setting ng Account',
    },
    'settings.edit_profile': {
      'en': 'Edit Profile',
      'fil': 'I-edit ang Profile',
    },
    'settings.edit_profile_desc': {
      'en': 'Update your personal information',
      'fil': 'I-update ang iyong personal na impormasyon',
    },
    'settings.change_password': {
      'en': 'Change Password',
      'fil': 'Palitan ang Password',
    },
    'settings.change_password_desc': {
      'en': 'Secure your account with a new password',
      'fil': 'I-secure ang iyong account gamit ang bagong password',
    },
    'settings.general': {
      'en': 'General Preferences',
      'fil': 'Pangkalahatang Kagustuhan',
    },
    'settings.language': {'en': 'Language', 'fil': 'Wika'},
    'settings.language_desc': {
      'en': 'Choose your preferred language',
      'fil': 'Pumili ng gustong wika',
    },
    'settings.dark_mode': {'en': 'Dark Mode', 'fil': 'Dark Mode'},
    'settings.dark_mode_desc': {
      'en': 'Switch between light and dark themes',
      'fil': 'Lumipat sa pagitan ng light at dark na tema',
    },
    'settings.backend': {'en': 'Backend Server', 'fil': 'Backend Server'},
    'settings.backend_desc': {
      'en': 'Configure backend URL for any network',
      'fil': 'I-configure ang backend URL para sa anumang network',
    },
    'settings.notifications': {
      'en': 'Notifications',
      'fil': 'Mga Notipikasyon',
    },
    'settings.push_notif': {
      'en': 'Push Notifications',
      'fil': 'Mga Push Notification',
    },
    'settings.push_notif_desc': {
      'en': 'Pest alerts and scan results',
      'fil': 'Mga alerto sa peste at resulta ng pag-scan',
    },
    'settings.email_notif': {
      'en': 'Email Notifications',
      'fil': 'Mga Notipikasyon sa Email',
    },
    'settings.email_notif_desc': {
      'en': 'Reports and account updates',
      'fil': 'Mga ulat at update sa account',
    },
    'settings.sms_notif': {
      'en': 'SMS Notifications',
      'fil': 'Mga Notipikasyon sa SMS',
    },
    'settings.sms_notif_desc': {
      'en': 'Text message alerts',
      'fil': 'Mga alerto sa text message',
    },
    'settings.data_mgmt': {
      'en': 'Data Management',
      'fil': 'Pamamahala ng Data',
    },
    'settings.auto_backup': {'en': 'Auto Backup', 'fil': 'Awtomatikong Backup'},
    'settings.auto_backup_desc': {
      'en': 'Automatic cloud backup',
      'fil': 'Awtomatikong cloud backup',
    },
    'settings.profile_visible': {
      'en': 'Profile Visible',
      'fil': 'Makikita ang Profile',
    },
    'settings.profile_visible_desc': {
      'en': 'Allow others to see your profile',
      'fil': 'Payagan ang ibang makita ang iyong profile',
    },
    'settings.data_sharing': {
      'en': 'Data Sharing',
      'fil': 'Pagbabahagi ng Data',
    },
    'settings.data_sharing_desc': {
      'en': 'Share anonymized data for research',
      'fil': 'Ibahagi ang anonymized na data para sa pananaliksik',
    },
    'settings.export_data': {'en': 'Export Data', 'fil': 'I-export ang Data'},
    'settings.export_data_desc': {
      'en': 'Download your scan data as JSON',
      'fil': 'I-download ang iyong scan data bilang JSON',
    },
    'settings.delete_all': {
      'en': 'Delete All Data',
      'fil': 'Burahin ang Lahat ng Data',
    },
    'settings.delete_all_desc': {
      'en': 'Erase local scan history',
      'fil': 'Burahin ang lokal na kasaysayan ng pag-scan',
    },
    'settings.app_info': {'en': 'App Information', 'fil': 'Impormasyon ng App'},
    'settings.privacy_policy': {
      'en': 'Privacy Policy',
      'fil': 'Patakaran sa Privacy',
    },
    'settings.terms': {
      'en': 'Terms of Service',
      'fil': 'Mga Tuntunin ng Serbisyo',
    },
    'settings.about': {'en': 'About CocoGuard', 'fil': 'Tungkol sa CocoGuard'},
    'settings.about_desc': {
      'en':
          'Developed to support sustainable coconut farming in the Philippines.',
      'fil':
          'Binuo upang suportahan ang napapanatiling pagtatanim ng niyog sa Pilipinas.',
    },
    'settings.logout': {'en': 'Log Out', 'fil': 'Mag-log Out'},
    'settings.logout_confirm': {
      'en': 'Are you sure you want to log out?',
      'fil': 'Sigurado ka bang gusto mong mag-log out?',
    },
    'settings.logout_yes': {'en': 'Yes, Log Out', 'fil': 'Oo, Mag-log Out'},
    'settings.synced': {
      'en': 'All queued settings synced!',
      'fil': 'Lahat ng naka-queue na setting ay na-sync!',
    },

    // ─── PROFILE SCREEN ───
    'profile.title': {'en': 'Profile', 'fil': 'Profile'},
    'profile.personal_details': {
      'en': 'Personal Details',
      'fil': 'Mga Personal na Detalye',
    },
    'profile.contact_info': {
      'en': 'Contact Information',
      'fil': 'Impormasyon sa Pakikipag-ugnayan',
    },
    'profile.personal': {
      'en': 'Personal Details',
      'fil': 'Mga Personal na Detalye',
    },
    'profile.contact': {
      'en': 'Contact Information',
      'fil': 'Impormasyon sa Pakikipag-ugnayan',
    },
    'profile.dob': {'en': 'Date of Birth', 'fil': 'Petsa ng Kapanganakan'},
    'profile.gender': {'en': 'Gender', 'fil': 'Kasarian'},
    'profile.not_specified': {'en': 'Not specified', 'fil': 'Hindi tinukoy'},
    'profile.user': {'en': 'User', 'fil': 'User'},
    'profile.no_email': {'en': 'No email', 'fil': 'Walang email'},
    'profile.no_phone': {
      'en': 'No phone number',
      'fil': 'Walang numero ng telepono',
    },
    'profile.edit_profile': {'en': 'Edit Profile', 'fil': 'I-edit ang Profile'},
    'profile.change_password': {
      'en': 'Change Password',
      'fil': 'Palitan ang Password',
    },
    'profile.settings': {'en': 'Settings', 'fil': 'Mga Setting'},
    'profile.edit': {'en': 'Edit Profile', 'fil': 'I-edit ang Profile'},
    'profile.logout': {'en': 'Logout', 'fil': 'Mag-logout'},
    'profile.logout_confirm': {
      'en': 'Are you sure you want to logout?',
      'fil': 'Sigurado ka bang gusto mong mag-logout?',
    },
    'profile.cancel_logout': {
      'en': 'Noah, Just Kidding',
      'fil': 'Hindi, Biro Lang',
    },
    'profile.confirm_logout': {
      'en': 'Yes, Log Me Out',
      'fil': 'Oo, I-log Out Ako',
    },
    'profile.logout_yes': {'en': 'Yes, Log Me Out', 'fil': 'Oo, I-log Out Ako'},

    // ─── HISTORY SCREEN ───
    'history.title': {'en': 'History', 'fil': 'Kasaysayan'},
    'history.search_hint': {
      'en': 'Search (location, pest)',
      'fil': 'Maghanap (lokasyon, peste)',
    },
    'history.error_loading': {
      'en': 'Error loading scans',
      'fil': 'Error sa pag-load ng mga scan',
    },
    'history.no_history': {
      'en': 'No scan history yet',
      'fil': 'Wala pang kasaysayan ng pag-scan',
    },
    'history.start_scanning': {
      'en': 'Start scanning to see your history here',
      'fil': 'Magsimulang mag-scan upang makita ang iyong kasaysayan dito',
    },
    'history.delete_scan': {'en': 'Delete Scan', 'fil': 'Burahin ang Scan'},
    'history.delete_confirm_msg': {
      'en': 'This will also remove the scanned image from the server.',
      'fil': 'Aaalisin din nito ang na-scan na larawan mula sa server.',
    },
    'history.scan_deleted': {
      'en': 'Scan deleted successfully',
      'fil': 'Matagumpay na nabura ang scan',
    },
    'history.scan_id': {'en': 'Scan ID', 'fil': 'Scan ID'},
    'history.unknown_location': {
      'en': 'Unknown Location',
      'fil': 'Hindi Alam na Lokasyon',
    },
    'history.unknown_pest': {
      'en': 'Unknown Pest',
      'fil': 'Hindi Alam na Peste',
    },
    'history.empty': {
      'en': 'No scan history yet',
      'fil': 'Wala pang kasaysayan ng pag-scan',
    },
    'history.empty_desc': {
      'en': 'Start scanning to see your history here',
      'fil': 'Magsimulang mag-scan upang makita ang iyong kasaysayan dito',
    },
    'history.error': {
      'en': 'Error loading scans',
      'fil': 'Error sa pag-load ng mga scan',
    },
    'history.retry': {'en': 'Retry', 'fil': 'Subukan Muli'},
    'history.delete': {'en': 'Delete Scan', 'fil': 'Burahin ang Scan'},
    'history.delete_confirm': {
      'en': 'Are you sure you want to delete this scan?',
      'fil': 'Sigurado ka bang gusto mong burahin ang scan na ito?',
    },
    'history.deleted': {
      'en': 'Scan deleted successfully',
      'fil': 'Matagumpay na nabura ang scan',
    },
    'history.total_scans': {'en': 'Total Scans', 'fil': 'Kabuuang Pag-scan'},
    'history.total_trees': {'en': 'Total Trees', 'fil': 'Kabuuang Puno'},

    // ─── LOGIN SCREEN ───
    'login.title': {
      'en': 'Login to Pest Management',
      'fil': 'Mag-login sa Pamamahala ng Peste',
    },
    'login.email': {'en': 'Email', 'fil': 'Email'},
    'login.password': {'en': 'Password', 'fil': 'Password'},
    'login.submit': {'en': 'Login', 'fil': 'Mag-login'},
    'login.forgot': {
      'en': 'Forgot Password?',
      'fil': 'Nakalimutan ang Password?',
    },
    'login.no_account': {
      'en': "Don't have an account?",
      'fil': 'Wala ka pang account?',
    },
    'login.register': {'en': 'Register', 'fil': 'Mag-register'},
    'login.connection_error': {
      'en': 'Connection Error',
      'fil': 'Error sa Koneksyon',
    },
    'login.login_failed': {'en': 'Login Failed', 'fil': 'Nabigo ang Pag-login'},
    'login.cannot_connect': {
      'en':
          'Cannot connect to the server.\n\nIf you are using a physical phone, please configure the server IP address first.',
      'fil':
          'Hindi makakonekta sa server.\n\nKung gumagamit ka ng pisikal na telepono, mangyaring i-configure muna ang IP address ng server.',
    },
    'login.invalid_credentials': {
      'en': 'Invalid credentials. Please try again.',
      'fil': 'Hindi wastong kredensyal. Mangyaring subukan muli.',
    },
    'login.configure_server': {
      'en': 'Configure Server',
      'fil': 'I-configure ang Server',
    },
    'login.new_era': {'en': 'THE NEW ERA OF', 'fil': 'ANG BAGONG PANAHON NG'},
    'login.agriculture': {'en': 'AGRICULTURE', 'fil': 'AGRIKULTURA'},
    'login.tagline': {
      'en': 'Guarding Coconut Farms with the Power of AI',
      'fil': 'Pinoprotektahan ang mga Taniman ng Niyog gamit ang AI',
    },
    'login.welcome': {'en': 'Welcome!', 'fil': 'Maligayang Pagdating!'},
    'login.subtitle': {
      'en': 'Login to your Account',
      'fil': 'Mag-login sa iyong Account',
    },
    'login.username_email': {
      'en': 'Username or Email',
      'fil': 'Username o Email',
    },
    'login.enter_username': {
      'en': 'Please enter username or email',
      'fil': 'Mangyaring maglagay ng username o email',
    },
    'login.enter_password': {
      'en': 'Please enter password',
      'fil': 'Mangyaring maglagay ng password',
    },
    'login.forgot_password': {
      'en': 'Forgot Password?',
      'fil': 'Nakalimutan ang password?',
    },
    'login.login_btn': {'en': 'Login', 'fil': 'Mag login'},
    'login.register_btn': {'en': 'Register', 'fil': 'Mag-register'},
    'login.config_server': {
      'en': 'Configure Server (Physical Device)',
      'fil': 'I-configure ang Server (Pisikal na Device)',
    },
    'login.offline_fail': {
      'en':
          'No offline credentials found for this user. Please login online at least once.',
      'fil':
          'Walang offline na kredensyal para sa user na ito. Mangyaring mag-login online kahit isang beses.',
    },
    'login.credentials_fail': {
      'en': 'Offline login failed. Credentials do not match.',
      'fil': 'Nabigo ang offline na pag-login. Hindi tugma ang mga kredensyal.',
    },

    // ─── REGISTER SCREEN ───
    'register.welcome': {'en': 'Welcome!', 'fil': 'Maligayang Pagdating!'},
    'register.create': {'en': 'Create an Account', 'fil': 'Gumawa ng Account'},
    'register.create_account': {
      'en': 'Create an Account',
      'fil': 'Gumawa ng Account',
    },
    'register.full_name': {
      'en': 'Full Name',
      'fil': 'Pangalan (Buong Pangalan)',
    },
    'register.enter_name': {
      'en': 'Please enter your full name',
      'fil': 'Mangyaring ilagay ang iyong buong pangalan',
    },
    'register.name': {'en': 'Full Name', 'fil': 'Buong Pangalan'},
    'register.email': {'en': 'Email', 'fil': 'Email'},
    'register.enter_email': {
      'en': 'Please enter your email',
      'fil': 'Mangyaring ilagay ang iyong email',
    },
    'register.valid_email': {
      'en': 'Please enter a valid email',
      'fil': 'Mangyaring maglagay ng wastong email',
    },
    'register.username': {'en': 'Username', 'fil': 'Username'},
    'register.enter_username': {
      'en': 'Please enter a username',
      'fil': 'Mangyaring maglagay ng username',
    },
    'register.username_min': {
      'en': 'Username must be at least 3 characters',
      'fil': 'Ang username ay dapat hindi bababa sa 3 karakter',
    },
    'register.phone': {'en': 'Phone Number', 'fil': 'Numero ng Telepono'},
    'register.phone_min': {
      'en': 'Phone number must be at least 10 digits',
      'fil': 'Ang numero ng telepono ay dapat hindi bababa sa 10 digit',
    },
    'register.gender': {'en': 'Gender', 'fil': 'Kasarian'},
    'register.dob': {
      'en': 'Date of Birth (MM/DD/YYYY)',
      'fil': 'Petsa ng Kapanganakan (MM/DD/YYYY)',
    },
    'register.address': {'en': 'Address', 'fil': 'Address'},
    'register.enter_address': {
      'en': 'Please enter your address',
      'fil': 'Mangyaring ilagay ang iyong address',
    },
    'register.region': {'en': 'Region', 'fil': 'Rehiyon'},
    'register.province': {'en': 'Province', 'fil': 'Lalawigan'},
    'register.city': {
      'en': 'City/Municipality',
      'fil': 'Lungsod/Munisipalidad',
    },
    'register.barangay': {'en': 'Barangay', 'fil': 'Barangay'},
    'register.password': {'en': 'Password', 'fil': 'Password'},
    'register.enter_password': {
      'en': 'Please enter a password',
      'fil': 'Mangyaring maglagay ng password',
    },
    'register.password_min': {
      'en': 'Password must be at least 6 characters',
      'fil': 'Ang password ay dapat hindi bababa sa 6 na karakter',
    },
    'register.confirm_password': {
      'en': 'Confirm your Password',
      'fil': 'Kumpirmahin ang iyong Password',
    },
    'register.confirm_pw_required': {
      'en': 'Please confirm your password',
      'fil': 'Mangyaring kumpirmahin ang iyong password',
    },
    'register.agree_text': {
      'en': 'I agree to the ',
      'fil': 'Sumasang-ayon ako sa ',
    },
    'register.data_privacy': {
      'en': 'Data Privacy Agreement',
      'fil': 'Kasunduan sa Privacy ng Data',
    },
    'register.data_privacy_msg': {
      'en':
          'By using CocoGuard, you agree to our collection and use of your data for pest detection and farm management purposes.',
      'fil':
          'Sa paggamit ng CocoGuard, sumasang-ayon ka sa aming pagkolekta at paggamit ng iyong data para sa pagtukoy ng peste at pamamahala ng bukid.',
    },
    'register.agree_privacy': {
      'en': 'Please agree to the Data Privacy Agreement',
      'fil': 'Mangyaring sumang-ayon sa Kasunduan sa Privacy ng Data',
    },
    'register.passwords_mismatch': {
      'en': 'Passwords do not match',
      'fil': 'Hindi tugma ang mga password',
    },
    'register.register_btn': {'en': 'Register', 'fil': 'Magrehistro'},
    'register.have_account': {
      'en': 'Already have an account? Login',
      'fil': 'May Account Ka Na? Mag-login',
    },
    'register.success': {'en': 'Success', 'fil': 'Tagumpay'},
    'register.success_msg': {
      'en': 'Your account has been successfully created! You can now log in.',
      'fil':
          'Matagumpay na nagawa ang iyong account! Maaari ka nang mag-login.',
    },
    'register.failed': {
      'en': 'Registration failed',
      'fil': 'Nabigo ang pagpaparehistro',
    },
    'register.confirm': {
      'en': 'Confirm Password',
      'fil': 'Kumpirmahin ang Password',
    },
    'register.agree': {
      'en': 'Please agree to the Data Privacy Agreement',
      'fil': 'Mangyaring sumang-ayon sa Data Privacy Agreement',
    },

    // ─── CHANGE PASSWORD ───
    'change_pw.title': {'en': 'Change Password', 'fil': 'Palitan ang Password'},
    'change_pw.update': {
      'en': 'Update Your Password',
      'fil': 'I-update ang Iyong Password',
    },
    'change_pw.description': {
      'en':
          'Please enter your current password and your new password. A verification code will be sent to your email.',
      'fil':
          'Mangyaring ilagay ang iyong kasalukuyang password at bagong password. Magpapadala ng verification code sa iyong email.',
    },
    'change_pw.current': {
      'en': 'Current Password',
      'fil': 'Kasalukuyang Password',
    },
    'change_pw.current_hint': {
      'en': 'Enter your current password',
      'fil': 'Ilagay ang iyong kasalukuyang password',
    },
    'change_pw.new': {'en': 'New Password', 'fil': 'Bagong Password'},
    'change_pw.new_hint': {
      'en': 'Enter your new password',
      'fil': 'Ilagay ang iyong bagong password',
    },
    'change_pw.confirm': {
      'en': 'Confirm New Password',
      'fil': 'Kumpirmahin ang Bagong Password',
    },
    'change_pw.confirm_hint': {
      'en': 'Confirm your new password',
      'fil': 'Kumpirmahin ang iyong bagong password',
    },
    'change_pw.required': {
      'en': 'Password is required',
      'fil': 'Kinakailangan ang password',
    },
    'change_pw.min_length': {
      'en': 'Password must be at least 6 characters',
      'fil': 'Ang password ay dapat hindi bababa sa 6 na karakter',
    },
    'change_pw.current_required': {
      'en': 'Current password is required',
      'fil': 'Kinakailangan ang kasalukuyang password',
    },
    'change_pw.confirm_required': {
      'en': 'Please confirm your password',
      'fil': 'Mangyaring kumpirmahin ang iyong password',
    },
    'change_pw.mismatch': {
      'en': 'Passwords do not match',
      'fil': 'Hindi tugma ang mga password',
    },
    'change_pw.send_code': {
      'en': 'Send Verification Code',
      'fil': 'Magpadala ng Verification Code',
    },
    'change_pw.code_sent': {
      'en': 'Verification code sent to',
      'fil': 'Ipinadala ang verification code sa',
    },
    'change_pw.enter_code': {
      'en': 'Enter Verification Code',
      'fil': 'Ilagay ang Verification Code',
    },
    'change_pw.code_label': {
      'en': 'Verification Code',
      'fil': 'Verification Code',
    },
    'change_pw.enter_6digit': {
      'en': 'Please enter the 6-digit verification code',
      'fil': 'Mangyaring ilagay ang 6-digit na verification code',
    },
    'change_pw.we_sent_code': {
      'en': 'We sent a 6-digit code to',
      'fil': 'Nagpadala kami ng 6-digit na code sa',
    },
    'change_pw.didnt_receive': {
      'en': "Didn't receive the code? ",
      'fil': 'Hindi natanggap ang code? ',
    },
    'change_pw.resend': {'en': 'Resend Code', 'fil': 'I-resend ang Code'},
    'change_pw.resend_in': {'en': 'Resend in', 'fil': 'I-resend sa'},
    'change_pw.new_code_sent': {
      'en': 'New verification code sent!',
      'fil': 'Naipadala ang bagong verification code!',
    },
    'change_pw.verify_change': {
      'en': 'Verify & Change Password',
      'fil': 'I-verify at Palitan ang Password',
    },
    'change_pw.back': {'en': 'Back', 'fil': 'Bumalik'},
    'change_pw.success': {
      'en': 'Password changed successfully!',
      'fil': 'Matagumpay na napalitan ang password!',
    },
    'change_pw.failed': {
      'en': 'Failed to change password',
      'fil': 'Nabigo ang pagpapalit ng password',
    },
    'change_pw.failed_send': {
      'en': 'Failed to send verification code',
      'fil': 'Nabigo ang pagpapadala ng verification code',
    },
    'change_pw.failed_resend': {
      'en': 'Failed to resend code',
      'fil': 'Nabigo ang pag-resend ng code',
    },
    'change_pw.incorrect': {
      'en': 'Current password is incorrect',
      'fil': 'Hindi tama ang kasalukuyang password',
    },
    'change_pw.invalid_code': {
      'en': 'Invalid or expired verification code',
      'fil': 'Hindi wasto o nag-expire na ang verification code',
    },
    'change_pw.session_expired': {
      'en': 'Session expired. Please login again',
      'fil': 'Nag-expire na ang session. Mangyaring mag-login muli',
    },

    // ─── NOTIFICATIONS (mobile) ───
    'notifications.page_title': {
      'en': 'Notifications',
      'fil': 'Mga Notification',
    },
    'notifications.read_all': {'en': 'Read All', 'fil': 'Basahin Lahat'},
    'notifications.no_notif': {
      'en': 'No Notifications',
      'fil': 'Walang Notification',
    },
    'notifications.no_notif_desc': {
      'en': 'Alerts for dangerous pests\nwill appear here.',
      'fil': 'Ang mga alert para sa mapanganib na peste\nay lalabas dito.',
    },
    'notifications.dangerous_pest': {
      'en': 'DANGEROUS PEST',
      'fil': 'MAPANGANIB NA PESTE',
    },
    'notifications.urgent_action': {
      'en': 'Urgent action needed!',
      'fil': 'Kailangan ng agarang aksyon!',
    },
    'notifications.close': {'en': 'Close', 'fil': 'Isara'},
    'notifications.just_now': {'en': 'Just now', 'fil': 'Ngayon lang'},
    'notifications.minutes_ago': {
      'en': 'minutes ago',
      'fil': 'minuto nakaraan',
    },
    'notifications.hours_ago': {'en': 'hours ago', 'fil': 'oras nakaraan'},
    'notifications.days_ago': {'en': 'days ago', 'fil': 'araw nakaraan'},

    // ─── EDIT PROFILE ───
    'edit_profile.title': {'en': 'Edit Profile', 'fil': 'I-edit ang Profile'},
    'edit_profile.heading': {
      'en': 'Update Your Profile',
      'fil': 'I-update ang Iyong Profile',
    },
    'edit_profile.description': {
      'en': 'Edit your personal information below.',
      'fil': 'I-edit ang iyong personal na impormasyon sa ibaba.',
    },
    'edit_profile.full_name': {'en': 'Full Name', 'fil': 'Buong Pangalan'},
    'edit_profile.full_name_hint': {
      'en': 'Enter your full name',
      'fil': 'Ilagay ang iyong buong pangalan',
    },
    'edit_profile.phone': {'en': 'Phone Number', 'fil': 'Numero ng Telepono'},
    'edit_profile.phone_hint': {
      'en': 'Enter your phone number',
      'fil': 'Ilagay ang iyong numero ng telepono',
    },
    'edit_profile.gender': {'en': 'Gender', 'fil': 'Kasarian'},
    'edit_profile.dob': {'en': 'Date of Birth', 'fil': 'Petsa ng Kapanganakan'},
    'edit_profile.dob_hint': {'en': 'MM/DD/YYYY', 'fil': 'MM/DD/YYYY'},
    'edit_profile.region': {'en': 'Region', 'fil': 'Rehiyon'},
    'edit_profile.province': {'en': 'Province', 'fil': 'Lalawigan'},
    'edit_profile.city': {
      'en': 'City/Municipality',
      'fil': 'Lungsod/Munisipalidad',
    },
    'edit_profile.barangay': {'en': 'Barangay', 'fil': 'Barangay'},
    'edit_profile.street': {
      'en': 'Street/House No./Building',
      'fil': 'Kalye/Numero ng Bahay/Gusali',
    },
    'edit_profile.street_hint': {
      'en': 'Enter your complete address',
      'fil': 'Ilagay ang iyong kumpletong address',
    },
    'edit_profile.save': {
      'en': 'Save Changes',
      'fil': 'I-save ang mga Pagbabago',
    },
    'edit_profile.name_required': {
      'en': 'Name is required',
      'fil': 'Kinakailangan ang pangalan',
    },
    'edit_profile.name_min': {
      'en': 'Name must be at least 2 characters',
      'fil': 'Ang pangalan ay dapat hindi bababa sa 2 karakter',
    },
    'edit_profile.success': {
      'en': 'Profile updated successfully!',
      'fil': 'Matagumpay na na-update ang profile!',
    },
    'edit_profile.queued': {
      'en': 'Profile update queued for sync when online.',
      'fil':
          'Naka-queue ang pag-update ng profile para sa pag-sync kapag online.',
    },
    'edit_profile.synced': {
      'en': 'All queued profile updates synced!',
      'fil': 'Lahat ng naka-queue na update sa profile ay na-sync!',
    },

    // ─── FORGOT PASSWORD ───
    'forgot_pw.title': {
      'en': 'Forgot Password?',
      'fil': 'Nakalimutan ang Password?',
    },
    'forgot_pw.description': {
      'en':
          "Enter your email address and we'll send you a verification code to reset your password.",
      'fil':
          'Ilagay ang iyong email address at magpapadala kami ng verification code para i-reset ang iyong password.',
    },
    'forgot_pw.email_label': {'en': 'Email Address', 'fil': 'Email Address'},
    'forgot_pw.email_hint': {
      'en': 'your-email@example.com',
      'fil': 'iyong-email@example.com',
    },
    'forgot_pw.enter_email': {
      'en': 'Please enter your email address',
      'fil': 'Mangyaring ilagay ang iyong email address',
    },
    'forgot_pw.valid_email': {
      'en': 'Please enter a valid email address',
      'fil': 'Mangyaring maglagay ng wastong email address',
    },
    'forgot_pw.code_sent': {
      'en': 'Verification code sent!',
      'fil': 'Naipadala ang verification code!',
    },
    'forgot_pw.failed_send': {
      'en': 'Failed to send code',
      'fil': 'Nabigo ang pagpapadala ng code',
    },
    'forgot_pw.send_code': {
      'en': 'Send Verification Code',
      'fil': 'Magpadala ng Verification Code',
    },
    'forgot_pw.back_to_login': {
      'en': 'Back to Login',
      'fil': 'Bumalik sa Pag-login',
    },

    // ─── CAMERA / CAPTURE ───
    'camera.title': {'en': 'Camera', 'fil': 'Camera'},
    'camera.take_photo': {'en': 'Take Photo', 'fil': 'Kumuha ng Larawan'},
    'camera.gallery': {
      'en': 'Choose from Gallery',
      'fil': 'Pumili mula sa Gallery',
    },

    // ─── KNOWLEDGE ───
    'knowledge.title': {'en': 'Knowledge Base', 'fil': 'Base ng Kaalaman'},

    // ─── NOTIFICATIONS ───
    'notifications.title': {'en': 'Notifications', 'fil': 'Mga Notipikasyon'},
    'notifications.empty': {
      'en': 'No notifications yet',
      'fil': 'Wala pang notipikasyon',
    },

    // ─── FEEDBACK ───
    'feedback.title': {'en': 'Feedback', 'fil': 'Feedback'},
    'feedback.submit': {'en': 'Submit Feedback', 'fil': 'Ipasa ang Feedback'},
    'feedback.success': {
      'en': 'Feedback submitted successfully!',
      'fil': 'Matagumpay na naipasa ang feedback!',
    },

    // ─── SURVEY ───
    'survey.title': {'en': 'Survey', 'fil': 'Survey'},

    // ─── RESULTS ───
    'results.title': {'en': 'Results', 'fil': 'Mga Resulta'},
    'results.pest_detected': {'en': 'Pest Detected', 'fil': 'Natukoy na Peste'},
    'results.no_pest': {
      'en': 'No Pest Detected',
      'fil': 'Walang Natukoy na Peste',
    },
    'results.management': {
      'en': 'Management Strategies',
      'fil': 'Mga Estratehiya sa Pamamahala',
    },

    // ─── COMMON ───
    'common.save': {'en': 'Save', 'fil': 'I-save'},
    'common.cancel': {'en': 'Cancel', 'fil': 'Kanselahin'},
    'common.delete': {'en': 'Delete', 'fil': 'Burahin'},
    'common.close': {'en': 'Close', 'fil': 'Isara'},
    'common.confirm': {'en': 'Confirm', 'fil': 'Kumpirmahin'},
    'common.error': {'en': 'Error', 'fil': 'Error'},
    'common.success': {'en': 'Success', 'fil': 'Tagumpay'},
    'common.loading': {'en': 'Loading...', 'fil': 'Naglo-load...'},
    'common.retry': {'en': 'Retry', 'fil': 'Subukan Muli'},
    'common.yes': {'en': 'Yes', 'fil': 'Oo'},
    'common.no': {'en': 'No', 'fil': 'Hindi'},
    'common.ok': {'en': 'OK', 'fil': 'OK'},
    'common.unknown_location': {
      'en': 'Unknown Location',
      'fil': 'Hindi Alam na Lokasyon',
    },

    // ─── CONTACT ───
    'contact.title': {'en': 'Contact Us', 'fil': 'Makipag-ugnayan'},

    // ─── SPLASH ───
    'splash.tagline': {
      'en': 'Smart Coconut Pest Detection',
      'fil': 'Matalinong Pagtukoy ng Peste sa Niyog',
    },

    // ─── TWO-FACTOR AUTH ───
    'two_factor.title': {'en': 'Two-Factor Authentication', 'fil': 'Dalawang-Hakbang na Pagpapatunay'},
    'two_factor.subtitle': {'en': 'Add an extra layer of security', 'fil': 'Magdagdag ng karagdagang seguridad'},
    'two_factor.status': {'en': 'Current Status', 'fil': 'Kasalukuyang Kalagayan'},
    'two_factor.status_enabled': {'en': 'Enabled', 'fil': 'Naka-enable'},
    'two_factor.status_disabled': {'en': 'Disabled', 'fil': 'Naka-disable'},
    'two_factor.email_label': {'en': 'Email', 'fil': 'Email'},
    'two_factor.how_it_works': {'en': 'How it works', 'fil': 'Paano ito gumagana'},
    'two_factor.step1': {'en': 'When you login, a 6-digit code is sent to your email', 'fil': 'Kapag nag-login ka, may 6-digit code na ipapadala sa iyong email'},
    'two_factor.step2': {'en': 'Enter the code to verify your identity', 'fil': 'Ilagay ang code upang mapatunayan ang iyong pagkakakilanlan'},
    'two_factor.step3': {'en': 'Only you can access your account', 'fil': 'Ikaw lang ang makaka-access sa iyong account'},
    'two_factor.enable_btn': {'en': 'Enable Two-Factor Auth', 'fil': 'I-enable ang 2FA'},
    'two_factor.disable_btn': {'en': 'Disable Two-Factor Auth', 'fil': 'I-disable ang 2FA'},
    'two_factor.disable_title': {'en': 'Disable 2FA?', 'fil': 'I-disable ang 2FA?'},
    'two_factor.disable_confirm': {'en': 'Are you sure you want to disable two-factor authentication? Your account will be less secure.', 'fil': 'Sigurado ka bang gusto mong i-disable ang 2FA? Magiging mas mahina ang seguridad ng iyong account.'},
    'two_factor.enabled_success': {'en': '2FA enabled successfully!', 'fil': 'Matagumpay na na-enable ang 2FA!'},
    'two_factor.disabled_success': {'en': '2FA has been disabled', 'fil': 'Na-disable na ang 2FA'},
    'two_factor.code_sent': {'en': 'Verification code sent to your email', 'fil': 'Naipadala na ang verification code sa iyong email'},
    'two_factor.enter_code': {'en': 'Enter Verification Code', 'fil': 'Ilagay ang Verification Code'},
    'two_factor.code_sent_desc': {'en': 'A 6-digit code has been sent to your registered email address.', 'fil': 'Naipadala na ang 6-digit code sa iyong email address.'},
    'two_factor.enter_6_digit': {'en': 'Please enter the 6-digit code', 'fil': 'Mangyaring ilagay ang 6-digit code'},
    'two_factor.verify_enable': {'en': 'Verify & Enable', 'fil': 'Patunayan at I-enable'},
    'two_factor.login_title': {'en': 'Verify Your Identity', 'fil': 'Patunayan ang Iyong Pagkakakilanlan'},
    'two_factor.verify_identity': {'en': 'Two-Factor Verification', 'fil': 'Dalawang-Hakbang na Pagpapatunay'},
    'two_factor.code_sent_to_email': {'en': 'A verification code has been sent to your registered email address.', 'fil': 'Naipadala na ang verification code sa iyong email address.'},
    'two_factor.verify_btn': {'en': 'Verify Code', 'fil': 'Patunayan ang Code'},
    'two_factor.resend_code': {'en': 'Resend Code', 'fil': 'Ipadala Muli ang Code'},
    'two_factor.back_to_login': {'en': 'Back to Login', 'fil': 'Bumalik sa Login'},
    'two_factor.invalid_code': {'en': 'Invalid or expired code', 'fil': 'Hindi wasto o nag-expire na ang code'},

    // ─── DELETE ACCOUNT ───
    'delete_account.title': {'en': 'Delete Account', 'fil': 'Burahin ang Account'},
    'delete_account.subtitle': {'en': 'Permanently delete your account', 'fil': 'Permanenteng burahin ang iyong account'},
    'delete_account.warning': {'en': 'This action is permanent and cannot be undone. All your data will be permanently deleted.', 'fil': 'Ang aksyon na ito ay permanente at hindi na mababawi. Lahat ng iyong data ay permanenteng mabubura.'},
    'delete_account.what_deleted': {'en': 'What will be deleted:', 'fil': 'Ang mabubura:'},
    'delete_account.item_profile': {'en': 'Your profile and personal information', 'fil': 'Ang iyong profile at personal na impormasyon'},
    'delete_account.item_scans': {'en': 'All scan history and images', 'fil': 'Lahat ng scan history at mga larawan'},
    'delete_account.item_settings': {'en': 'App settings and preferences', 'fil': 'Mga settings at preferences ng app'},
    'delete_account.item_feedback': {'en': 'Submitted feedback', 'fil': 'Mga isinumiteng feedback'},
    'delete_account.password_label': {'en': 'Enter your password to confirm', 'fil': 'Ilagay ang iyong password upang kumpirmahin'},
    'delete_account.password_hint': {'en': 'Current password', 'fil': 'Kasalukuyang password'},
    'delete_account.enter_password': {'en': 'Please enter your password', 'fil': 'Mangyaring ilagay ang iyong password'},
    'delete_account.must_confirm': {'en': 'Please confirm that you understand', 'fil': 'Mangyaring kumpirmahin na naintindihan mo'},
    'delete_account.confirm_text': {'en': 'I understand that this action is permanent and all my data will be deleted', 'fil': 'Naiintindihan ko na permanente ang aksyon na ito at mabubura ang lahat ng aking data'},
    'delete_account.final_title': {'en': 'Final Confirmation', 'fil': 'Huling Kumpirmasyon'},
    'delete_account.final_message': {'en': 'This is your last chance. Once deleted, your account and all data cannot be recovered.', 'fil': 'Ito na ang iyong huling pagkakataon. Kapag nabura na, hindi na mababawi ang iyong account at data.'},
    'delete_account.delete_btn': {'en': 'Delete My Account', 'fil': 'Burahin ang Aking Account'},
    'delete_account.success': {'en': 'Account deleted successfully', 'fil': 'Matagumpay na nabura ang account'},

    // ─── FEEDBACK HISTORY ───
    'feedback_history.title': {'en': 'My Feedback', 'fil': 'Aking Feedback'},
    'feedback_history.empty': {'en': 'No feedback yet', 'fil': 'Wala pang feedback'},
    'feedback_history.empty_desc': {'en': 'Your submitted feedback will appear here', 'fil': 'Dito lalabas ang iyong mga isinumite na feedback'},
  };
}

/// Global shortcut function for translations
String tr(String key, [String? fallback]) {
  return TranslationService.instance.t(key, fallback);
}
