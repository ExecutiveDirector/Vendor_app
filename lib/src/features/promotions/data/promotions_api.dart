import '../../../core/api/dio_client.dart';

class PromotionsApi {
  static Future<List<dynamic>> list() async {
    final res = await ApiClient.dio.get('/vendor/promotions');
    return res.data;
  }
  static Future<void> upsert(Map<String, dynamic> payload) async {
    await ApiClient.dio.post('/vendor/promotions', data: payload);
  }
  static Future<void> pause(String id, bool paused) async {
    await ApiClient.dio.post('/vendor/promotions/$id/pause', data: {'paused': paused});
  }
}
