import '../../../core/api/dio_client.dart';

class DashboardApi {
  /// Fetches vendor dashboard stats.
  /// Maps to vendorController.getDashboardStats → GET /vendors/dashboard/stats
  static Future<Map<String, dynamic>> summary() async {
    //vendor/analytics/summary → /vendors/dashboard/stats
    final res = await ApiClient.dio.get('/vendors/dashboard/stats');
    return res.data as Map<String, dynamic>? ?? {};
  }
}
