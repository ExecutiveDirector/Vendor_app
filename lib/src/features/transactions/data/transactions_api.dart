import '../../../core/api/dio_client.dart';
class TransactionsApi {
  static Future<List<dynamic>> list() async {
    final res = await ApiClient.dio.get('/vendor/transactions');
    return res.data;
  }
}
