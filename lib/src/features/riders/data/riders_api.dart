import '../../../core/api/dio_client.dart';

class VendorRidersApi {
  static Future<List<dynamic>> list() async {
    final res = await ApiClient.dio.get('/vendor/riders');
    return res.data;
  }
  static Future<void> invite(String phoneOrEmail) async {
    await ApiClient.dio.post('/vendor/riders/invite', data: {'contact': phoneOrEmail});
  }
  static Future<void> setStatus(String riderId, String status) async {
    await ApiClient.dio.post('/vendor/riders/$riderId/status', data: {'status': status});
  }
}
