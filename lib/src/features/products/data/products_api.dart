import '../../../core/api/dio_client.dart';

class ProductsApi {
  static Future<List<dynamic>> list() async {
    final res = await ApiClient.dio.get('/vendor/products');
    return res.data;
  }
  static Future<void> upsert(Map<String, dynamic> payload) async {
    await ApiClient.dio.post('/vendor/products', data: payload);
  }
  static Future<void> delete(String id) async {
    await ApiClient.dio.delete('/vendor/products/$id');
  }
  static Future<List<dynamic>> categories() async {
    final res = await ApiClient.dio.get('/vendor/product_categories');
    return res.data;
  }
}
