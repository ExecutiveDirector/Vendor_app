import '../../../core/api/dio_client.dart';

class OrdersApi {
  static Future<List<dynamic>> list({String status = 'pending'}) async {
    final res = await ApiClient.dio.get('/vendor/orders', queryParameters: {'status': status});
    return res.data;
  }
  static Future<Map<String, dynamic>> byId(String id) async {
    final res = await ApiClient.dio.get('/vendor/orders/$id');
    return res.data;
  }
  static Future<void> assignRider(String orderId, String riderId) async {
    await ApiClient.dio.post('/vendor/orders/$orderId/assign', data: {'rider_id': riderId});
  }
  static Future<void> updateStatus(String orderId, String status) async {
    await ApiClient.dio.post('/vendor/orders/$orderId/status', data: {'status': status});
  }
}
