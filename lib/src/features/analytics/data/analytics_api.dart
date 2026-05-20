import '../../../core/api/dio_client.dart';

class AnalyticsSummary {
  final double revenue;
  final int orderCount;
  final String period;
  final DateTime? startDate;

  AnalyticsSummary({
    required this.revenue,
    required this.orderCount,
    required this.period,
    this.startDate,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      revenue: double.tryParse(json['revenue'].toString()) ?? 0,
      orderCount: int.tryParse(json['orderCount'].toString()) ?? 0,
      period: json['period']?.toString() ?? 'month',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
    );
  }
}

class ProductAnalytics {
  final String productName;
  final int totalSold;
  final double totalRevenue;

  ProductAnalytics({
    required this.productName,
    required this.totalSold,
    required this.totalRevenue,
  });

  factory ProductAnalytics.fromJson(Map<String, dynamic> json) {
    return ProductAnalytics(
      productName: json['product_name'] ?? '',
      totalSold: int.tryParse(json['total_sold'].toString()) ?? 0,
      totalRevenue: double.tryParse(json['total_revenue'].toString()) ?? 0,
    );
  }
}

class AnalyticsApi {
  static Future<AnalyticsSummary> summary() async {
    final res = await ApiClient.dio.get('/vendors/analytics/sales');

    return AnalyticsSummary.fromJson(
      Map<String, dynamic>.from(res.data),
    );
  }

  static Future<List<ProductAnalytics>> products() async {
    final res = await ApiClient.dio.get('/vendors/analytics/products');

    if (res.data is! List) return [];

    return (res.data as List)
        .map((e) => ProductAnalytics.fromJson(
              Map<String, dynamic>.from(e),
            ))
        .toList();
  }
}
