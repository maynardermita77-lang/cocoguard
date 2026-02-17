import 'package:hive_flutter/hive_flutter.dart';

class LocalDataService {
  // Save user profile for offline use
  static Future<void> saveUserProfile(
    String username,
    Map<String, dynamic> profile,
  ) async {
    final box = Hive.box('cocoguard');
    final raw = box.get('offline_user_profiles', defaultValue: {});
    final Map<String, dynamic> profiles = Map<String, dynamic>.from(raw as Map);
    profiles[username] = profile;
    await box.put('offline_user_profiles', profiles);
  }

  // Get user profile for offline use
  static Map<String, dynamic>? getUserProfile(String username) {
    final box = Hive.box('cocoguard');
    final raw = box.get('offline_user_profiles', defaultValue: {});
    final Map<String, dynamic> profiles = Map<String, dynamic>.from(raw as Map);
    if (profiles.containsKey(username)) {
      return Map<String, dynamic>.from(profiles[username] as Map);
    }
    return null;
  }

  // Save user credentials (e.g., for offline login)
  static Future<void> saveUserCredentials(
    String username,
    String passwordHash,
    String token,
  ) async {
    final box = Hive.box('cocoguard');
    // Retrieve the map of all offline users, or create a new one
    final raw = box.get('offline_users', defaultValue: {});
    final Map<String, dynamic> users = Map<String, dynamic>.from(raw as Map);
    users[username] = {'passwordHash': passwordHash, 'token': token};
    await box.put('offline_users', users);
  }

  // Retrieve user credentials
  static Map<String, dynamic>? getUserCredentials(String username) {
    final box = Hive.box('cocoguard');
    final raw = box.get('offline_users', defaultValue: {});
    final Map<String, dynamic> users = Map<String, dynamic>.from(raw as Map);
    if (users.containsKey(username)) {
      final user = Map<String, dynamic>.from(users[username] as Map);
      return {
        'username': username,
        'passwordHash': user['passwordHash'],
        'token': user['token'],
      };
    }
    return null;
  }

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox('cocoguard');
  }

  static Future<void> saveData(String key, dynamic value) async {
    final box = Hive.box('cocoguard');
    await box.put(key, value);
  }

  static dynamic getData(String key) {
    final box = Hive.box('cocoguard');
    return box.get(key);
  }

  static Future<void> deleteData(String key) async {
    final box = Hive.box('cocoguard');
    await box.delete(key);
  }
}
