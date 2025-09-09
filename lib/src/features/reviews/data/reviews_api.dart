import '../../../core/api/dio_client.dart';

class ReviewsApi {
  static Future<List<dynamic>> list() async {
    final res = await ApiClient.dio.get('/vendor/reviews');
    return res.data;
  }
  static Future<void> reply(String reviewId, String reply) async {
    await ApiClient.dio.post('/vendor/reviews/$reviewId/reply', data: {'reply': reply});
  }
}
