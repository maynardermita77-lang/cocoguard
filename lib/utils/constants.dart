// ════════════════════════════════════════════════════════════════════════════════
// lib/utils/constants.dart
// ════════════════════════════════════════════════════════════════════════════════

class AppConstants {
  // App Information
  static const String appName = 'CocoGuard';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'THE NEW ERA OF AGRICULTURE';
  static const String appDescription =
      'Guarding Coconut Farms with the Power of AI';

  // API Configuration
  // Base URL is dynamically detected by ApiService based on platform/network
  // This constant is kept for reference only - actual URL comes from ApiService
  static const String baseUrl = ''; // Dynamically set by ApiService
  static const String apiVersion = 'v1';

  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String detectPestEndpoint = '/detect/pest';
  static const String submitSurveyEndpoint = '/survey/submit';
  static const String getHistoryEndpoint = '/history';
  static const String getAdvisoryEndpoint = '/advisory';
  static const String getUserProfileEndpoint = '/user/profile';

  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userIdKey = 'user_id';
  static const String userDataKey = 'user_data';
  static const String isLoggedInKey = 'is_logged_in';

  // Pest Types
  static const List<String> pestTypes = [
    'APW Adult',
    'APW Larvae',
    'Brontispa',
    'Brontispa Pupa',
    'Rhinoceros Beetle',
    'Slug Caterpillar',
    'White Grub',
    'Out-of-Scope Pest Instance',
  ];

  // Barangay List (Region IV-A)
  static const List<String> barangayList = [
    'Barangay 1',
    'Barangay 2',
    'Barangay 3',
    'Barangay 4',
    'Barangay 5',
    // Add more barangays as needed
  ];

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 20;

  // Image Settings
  static const int imageQuality = 85;
  static const double maxImageWidth = 1920;
  static const double maxImageHeight = 1080;

  // Request Timeouts
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 30);
}
// ════════════════════════════════════════════════════════════════════════════════
// USAGE IN main.dart
// ════════════════════════════════════════════════════════════════════════════════

/*
import 'utils/theme.dart';

void main() {
  runApp(const CocoGuardApp());
}

class CocoGuardApp extends StatelessWidget {
  const CocoGuardApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
*/
