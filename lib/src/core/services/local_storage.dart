import 'package:hive_flutter/hive_flutter.dart';

class LocalStorage {
  static late Box _box;
  static Future init() async { _box = await Hive.openBox('vendor_box'); }
  static Future setToken(String v) async => _box.put('token', v);
  static Future<String?> getToken() async => _box.get('token');
  static Future clear() async => _box.clear();
}
