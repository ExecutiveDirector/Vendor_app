import '../../../core/api/dio_client.dart';
class SubscriptionsApi {
  static Future<List<dynamic>> plans() async {
    final res = await ApiClient.dio.get('/vendor/subscription/plans');
    return res.data;
  }
  static Future<void> subscribe(String planId) async {
    await ApiClient.dio.post('/vendor/subscription/subscribe', data: {'plan_id': planId});
  }
}
