import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';

class SubscriptionsApi {
  static Future<List<dynamic>> getPlans() async {
    final res = await ApiClient.dio.get('/vendor/subscription/plans');
    if (res.statusCode == 200 && res.data is List) {
      return res.data;
    }
    throw Exception('Failed to load plans');
  }

  static Future<Map<String, dynamic>?> getCurrent() async {
    final res = await ApiClient.dio.get('/vendor/subscription/current');
    return res.data is Map<String, dynamic> ? res.data : null;
  }

  static Future<void> subscribe(String planId) async {
    await ApiClient.dio
        .post('/vendor/subscription/subscribe', data: {'plan_id': planId});
  }

  /// ✅ Change/upgrade an existing subscription
  static Future<void> changeSubscription(
      int subscriptionId, int newPlanId) async {
    await ApiClient.dio.post('/vendor/subscription/change', data: {
      'subscription_id': subscriptionId,
      'new_plan_id': newPlanId,
    });
  }

  static Future<void> cancel() async {
    await ApiClient.dio.post('/vendor/subscription/cancel');
  }
}
