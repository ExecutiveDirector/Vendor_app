import '../../../core/api/dio_client.dart';
import 'order_model.dart';

class OrdersApi {
  static Future<List<Order>> list({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    final res = await ApiClient.dio.get(
      '/vendors/orders',
      queryParameters: params,
    );
    final data = res.data;
    if (data is List) return data.map((e) => Order.fromJson(e)).toList();
    return [];
  }

  static Future<Order> byId(String id) async {
    final res = await ApiClient.dio.get('/vendors/orders/$id');
    final data = res.data;
    if (data is Map) return Order.fromJson(data as Map<String, dynamic>);
    return Order.fromJson(data);
  }

  static Future<void> updateStatus(String orderId, String status) async {
    await ApiClient.dio.put(
      '/vendors/orders/$orderId/status',
      data: {'status': status},
    );
  }

  static Future<void> assignRider(String orderId, String riderId) async {
    await ApiClient.dio.put(
      '/orders/$orderId/assign-rider',
      data: {'rider_id': riderId},
    );
  }
}
