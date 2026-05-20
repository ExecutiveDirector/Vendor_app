import 'package:dio/dio.dart';
import '../config.dart';
import '../services/local_storage.dart';

class ApiClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout:
          const Duration(seconds: 60), // ✅ Render cold start can take 30–60s
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await LocalStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // ✅ Retry once on timeout — handles Render cold-start spin-up
          final isTimeout = error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout;

          final alreadyRetried = error.requestOptions.extra['retried'] == true;

          if (isTimeout && !alreadyRetried) {
            try {
              error.requestOptions.extra['retried'] = true;

              final retryResponse = await _dio.fetch(error.requestOptions);
              return handler.resolve(retryResponse);
            } catch (retryError) {
              // Retry also failed — pass through the original error
              return handler.next(error);
            }
          }

          return handler.next(error);
        },
      ),
    );

  static Dio get dio => _dio;
}
