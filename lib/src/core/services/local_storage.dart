import 'package:hive_flutter/hive_flutter.dart';

class LocalStorage {
  static late Box _box;
  static Future<void> init() async {
    _box = await Hive.openBox('vendor_box');
  }

  static Future<void> setToken(String v) async => _box.put('token', v);
  static Future<String?> getToken() async => _box.get('token');
  static Future<void> setVendorId(String v) async => _box.put('vendor_id', v);
  static Future<String?> getVendorId() async => _box.get('vendor_id');
  static Future<void> clear() async => _box.clear();
}
