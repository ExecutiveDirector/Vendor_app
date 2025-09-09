import '../../../core/api/dio_client.dart';
class AnalyticsApi {
  static Future<Map<String, dynamic>> summary() async {
    final res = await ApiClient.dio.get('/vendor/analytics/summary');
    return res.data;
  }
  static Future<List<dynamic>> daily() async {
    final res = await ApiClient.dio.get('/vendor/analytics/daily');
    return res.data;
  }
}
