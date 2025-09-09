import '../../../core/api/dio_client.dart';
class SupportApi {
  static Future<List<dynamic>> tickets() async {
    final res = await ApiClient.dio.get('/vendor/support/tickets');
    return res.data;
  }
  static Future<void> create(String subject, String body) async {
    await ApiClient.dio.post('/vendor/support/tickets', data: {'subject': subject, 'body': body});
  }
}
