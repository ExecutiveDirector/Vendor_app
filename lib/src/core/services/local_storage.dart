import 'package:hive_flutter/hive_flutter.dart';

class LocalStorage {
  static late Box _box;

  static Future<void> init() async {
    _box = await Hive.openBox('vendor_box');
  }

  // Token helpers
  static Future<void> setToken(String v) async => _box.put('token', v);
  static Future<String?> getToken() async => _box.get('token');

  // Generic string helpers (used by login screen etc.)
  static Future<void> setString(String key, String value) async =>
      _box.put(key, value);
  static Future<String?> getString(String key) async => _box.get(key);
  static Future<void> remove(String key) async => _box.delete(key);

  // Full clear
  static Future<void> clear() async => _box.clear();
}
