import '../../../core/api/dio_client.dart';

class InventoryApi {
  static Future<List<dynamic>> list() async {
    final res = await ApiClient.dio.get('/vendor/inventory');
    return res.data;
  }
  static Future<void> adjust(String inventoryId, int delta, {String reason = 'manual'}) async {
    await ApiClient.dio.post('/vendor/inventory/$inventoryId/adjust', data: {'delta': delta, 'reason': reason});
  }
  static Future<List<dynamic>> movements(String inventoryId) async {
    final res = await ApiClient.dio.get('/vendor/inventory/$inventoryId/movements');
    return res.data;
  }
}
