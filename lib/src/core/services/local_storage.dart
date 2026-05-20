// import 'package:hive_flutter/hive_flutter.dart';

// class LocalStorage {
//   static late Box _box;

//   /// Initialize Hive and open the storage box
//   static Future<void> init() async {
//     _box = await Hive.openBox('vendor_box');
//   }

//   /// Store auth token
//   static Future<void> setToken(String value) async {
//     await _box.put('token', value);
//   }

//   /// Get auth token
//   static String? getToken() {
//     return _box.get('token');
//   }

//   /// Store a string with custom key
//   static Future<void> setString(String key, String value) async {
//     await _box.put(key, value);
//   }

//   /// Get a string with custom key
//   static String? getString(String key) {
//     return _box.get(key);
//   }

//   /// Clear all data
//   static Future<void> clear() async {
//     await _box.clear();
//   }
// }
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static SharedPreferences? _prefs;

  /// Initialize shared preferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('LocalStorage not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ==================== Token Management ====================

  /// Store authentication token
  static Future<bool> setToken(String token) async {
    return await prefs.setString('auth_token', token);
  }

  /// Get authentication token
  static Future<String?> getToken() async {
    return prefs.getString('auth_token');
  }

  /// Remove authentication token
  static Future<bool> removeToken() async {
    return await prefs.remove('auth_token');
  }

  // ==================== Vendor Info ====================

  /// Store vendor ID
  static Future<bool> setVendorId(String vendorId) async {
    return await prefs.setString('vendor_id', vendorId);
  }

  /// Get vendor ID
  static Future<String?> getVendorId() async {
    return prefs.getString('vendor_id');
  }

  /// Store business name
  static Future<bool> setBusinessName(String name) async {
    return await prefs.setString('business_name', name);
  }

  /// Get business name
  static Future<String?> getBusinessName() async {
    return prefs.getString('business_name');
  }

  /// Store vendor email
  static Future<bool> setVendorEmail(String email) async {
    return await prefs.setString('vendor_email', email);
  }

  /// Get vendor email
  static Future<String?> getVendorEmail() async {
    return prefs.getString('vendor_email');
  }

  // ==================== User Preferences ====================

  /// Store remembered email for login
  static Future<bool> setRememberedEmail(String email) async {
    return await prefs.setString('remembered_email', email);
  }

  /// Get remembered email
  static Future<String?> getRememberedEmail() async {
    return prefs.getString('remembered_email');
  }

  /// Store theme preference
  static Future<bool> setThemeMode(String mode) async {
    return await prefs.setString('theme_mode', mode);
  }

  /// Get theme preference
  static Future<String?> getThemeMode() async {
    return prefs.getString('theme_mode');
  }

  /// Store language preference
  static Future<bool> setLanguage(String lang) async {
    return await prefs.setString('language', lang);
  }

  /// Get language preference
  static Future<String?> getLanguage() async {
    return prefs.getString('language');
  }

  // ==================== Generic Methods ====================

  /// Store string value
  static Future<bool> setString(String key, String value) async {
    return await prefs.setString(key, value);
  }

  /// Get string value
  static Future<String?> getString(String key) async {
    return prefs.getString(key);
  }

  /// Store integer value
  static Future<bool> setInt(String key, int value) async {
    return await prefs.setInt(key, value);
  }

  /// Get integer value
  static Future<int?> getInt(String key) async {
    return prefs.getInt(key);
  }

  /// Store boolean value
  static Future<bool> setBool(String key, bool value) async {
    return await prefs.setBool(key, value);
  }

  /// Get boolean value
  static Future<bool?> getBool(String key) async {
    return prefs.getBool(key);
  }

  /// Store double value
  static Future<bool> setDouble(String key, double value) async {
    return await prefs.setDouble(key, value);
  }

  /// Get double value
  static Future<double?> getDouble(String key) async {
    return prefs.getDouble(key);
  }

  /// Store list of strings
  static Future<bool> setStringList(String key, List<String> value) async {
    return await prefs.setStringList(key, value);
  }

  /// Get list of strings
  static Future<List<String>?> getStringList(String key) async {
    return prefs.getStringList(key);
  }

  // ==================== Utility Methods ====================

  /// Check if key exists
  static Future<bool> containsKey(String key) async {
    return prefs.containsKey(key);
  }

  /// Remove specific key
  static Future<bool> remove(String key) async {
    return await prefs.remove(key);
  }

  /// Clear all stored data
  static Future<bool> clearAll() async {
    return await prefs.clear();
  }

  /// Get all keys
  static Future<Set<String>> getAllKeys() async {
    return prefs.getKeys();
  }

  /// Reload preferences from disk
  static Future<void> reload() async {
    await prefs.reload();
  }

  // ==================== Session Management ====================

  /// Check if user session is valid
  static Future<bool> hasValidSession() async {
    final token = await getToken();
    final vendorId = await getVendorId();
    return token != null && vendorId != null;
  }

  /// Clear session data (logout)
  static Future<void> clearSession() async {
    await removeToken();
    await remove('vendor_id');
    await remove('business_name');
    await remove('vendor_email');
  }

  /// Store complete vendor session
  static Future<void> setVendorSession({
    required String token,
    required String vendorId,
    required String businessName,
    String? email,
  }) async {
    await setToken(token);
    await setVendorId(vendorId);
    await setBusinessName(businessName);
    if (email != null) await setVendorEmail(email);
  }

  /// Get vendor session info
  static Future<Map<String, String?>> getVendorSession() async {
    return {
      'token': await getToken(),
      'vendor_id': await getVendorId(),
      'business_name': await getBusinessName(),
      'email': await getVendorEmail(),
    };
  }
}
