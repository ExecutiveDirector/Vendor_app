import '../../../core/api/dio_client.dart';

class InventoryItem {
  final String inventoryId;
  final String productId;
  final String productName;
  final String? sku;
  final String? outletName;
  final int currentStock;
  final int reservedStock;
  final int minimumStockLevel;
  final int? reorderPoint;
  final double sellingPrice;
  final double? costPrice;
  final bool isAvailable;
  final String? categoryName;
  final String? lastRestockedAt;

  const InventoryItem({
    required this.inventoryId,
    required this.productId,
    required this.productName,
    this.sku,
    this.outletName,
    required this.currentStock,
    this.reservedStock = 0,
    this.minimumStockLevel = 5,
    this.reorderPoint,
    required this.sellingPrice,
    this.costPrice,
    this.isAvailable = true,
    this.categoryName,
    this.lastRestockedAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        inventoryId: json['inventory_id']?.toString() ?? '',
        productId: json['product_id']?.toString() ?? '',
        productName: json['product_name'] ?? '',
        sku: json['sku'] ?? json['product_code'],
        outletName: json['outlet_name'],
        currentStock: (json['current_stock'] as num?)?.toInt() ?? 0,
        reservedStock: (json['reserved_stock'] as num?)?.toInt() ?? 0,
        minimumStockLevel: (json['minimum_stock_level'] as num?)?.toInt() ?? 5,
        reorderPoint: (json['reorder_point'] as num?)?.toInt(),
        sellingPrice: (json['selling_price'] as num?)?.toDouble() ?? 0.0,
        costPrice: (json['cost_price'] as num?)?.toDouble(),
        isAvailable: json['is_available'] == true || json['is_available'] == 1,
        categoryName: json['category_name'],
        lastRestockedAt: json['last_restocked_at'],
      );

  bool get isLowStock => currentStock > 0 && currentStock <= minimumStockLevel;
  bool get isOutOfStock => currentStock == 0;
}

class InventoryApi {
  static Future<List<InventoryItem>> list() async {
    final res = await ApiClient.dio.get('/vendors/inventory');
    final data = res.data;
    if (data is List)
      return data.map((e) => InventoryItem.fromJson(e)).toList();
    return [];
  }

  static Future<void> updateStock(String inventoryId, int newStock) async {
    await ApiClient.dio.put('/vendors/inventory/$inventoryId',
        data: {'current_stock': newStock});
  }

  static Future<void> adjustStock(String inventoryId, int delta,
      {String reason = 'manual'}) async {
    await ApiClient.dio.post('/vendors/inventory/$inventoryId/adjust',
        data: {'delta': delta, 'reason': reason});
  }

  static Future<List<dynamic>> movements(String inventoryId) async {
    final res =
        await ApiClient.dio.get('/vendors/inventory/$inventoryId/movements');
    return res.data is List ? res.data : [];
  }

  static Future<String> exportReport() async {
    final res = await ApiClient.dio.get('/vendors/inventory/export');
    return res.data.toString();
  }
}
