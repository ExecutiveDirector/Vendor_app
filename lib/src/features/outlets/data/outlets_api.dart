import '../../../core/api/dio_client.dart';

class OutletsApi {
  static Future<List<dynamic>> list() async {
    final res = await ApiClient.dio.get('/vendor/outlets');
    return res.data;
  }
  static Future<void> upsert(Map<String, dynamic> payload) async {
    await ApiClient.dio.post('/vendor/outlets', data: payload);
  }
}
