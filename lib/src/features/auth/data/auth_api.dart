import '../../../core/api/dio_client.dart';

class AuthApi {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await ApiClient.dio.post('/vendor/auth/login', data: {'email': email, 'password': password});
    return res.data;
  }
}
