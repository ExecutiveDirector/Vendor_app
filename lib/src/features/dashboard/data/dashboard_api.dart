import '../../../core/api/dio_client.dart';

class DashboardApi {
  static Future<Map<String, dynamic>> summary() async {
    final res = await ApiClient.dio.get('/vendor/analytics/summary');
    return res.data;
  }
}
