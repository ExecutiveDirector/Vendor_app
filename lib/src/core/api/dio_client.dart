import 'package:dio/dio.dart';
import '../config.dart';
import '../services/local_storage.dart';

class ApiClient {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 30),
  ))
  ..interceptors.add(InterceptorsWrapper(onRequest: (o, h) async {
    final token = await LocalStorage.getToken();
    if (token != null) o.headers['Authorization'] = 'Bearer $token';
    return h.next(o);
  }));

  static Dio get dio => _dio;
}
