// inventory_service.dart
// All vendor inventory API calls, mapped exactly to the backend routes
// defined in vendorController.js and outletController.js.
//
// Endpoint map:
//   GET    /vendor/inventory              → getInventory (vendorController)
//   PUT    /vendor/inventory/:id          → updateInventory
//   GET    /vendor/outlets                → getOutlets
//   GET    /vendor/categories             → getProductCategories
//   POST   /vendor/inventory/:id/adjust   → adjustStock (InventoryApi shape)
//   GET    /vendor/inventory/:id/movements→ movements
//   POST   /vendor/products              → createProduct
//
// The backend returns arrays directly (not wrapped in {data:…}) for most
// vendor routes, but we handle both shapes defensively.

import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import 'inventory_models.dart';

class InventoryService {
  final Dio _dio = ApiClient.dio;

  // ── Inventory ──────────────────────────────────────────────────────────────

  /// Fetch full inventory list for the authenticated vendor.
  Future<List<VendorInventory>> fetchInventory() async {
    try {
      final res = await _dio.get('/vendor/inventory');
      final raw = _unwrap(res.data);
      return (raw as List)
          .map((e) => VendorInventory.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _friendlyError('fetch inventory', e);
    }
  }

  /// Update a single inventory item's stock to an absolute value.
  /// Maps to: PUT /vendor/inventory/:inventoryId
  Future<void> updateStock(int inventoryId, int newStock) async {
    try {
      await _dio.put(
        '/vendor/inventory/$inventoryId',
        data: {'current_stock': newStock},
      );
    } on DioException catch (e) {
      throw _friendlyError('update stock', e);
    }
  }

  /// Adjust stock by a signed delta (+/-).
  /// Maps to: POST /vendor/inventory/:inventoryId/adjust
  Future<void> adjustStock(
    String inventoryId,
    int delta, {
    String reason = 'manual',
  }) async {
    try {
      await _dio.post(
        '/vendor/inventory/$inventoryId/adjust',
        data: {'delta': delta, 'reason': reason},
      );
    } on DioException catch (e) {
      throw _friendlyError('adjust stock', e);
    }
  }

  /// Fetch stock movement history for one inventory item.
  Future<List<Map<String, dynamic>>> fetchMovements(String inventoryId) async {
    try {
      final res = await _dio.get('/vendor/inventory/$inventoryId/movements');
      final raw = _unwrap(res.data);
      return (raw as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _friendlyError('fetch movements', e);
    }
  }

  // ── Outlets ────────────────────────────────────────────────────────────────

  /// Fetch all outlets belonging to the authenticated vendor.
  Future<List<VendorOutlet>> fetchOutlets() async {
    try {
      final res = await _dio.get('/vendor/outlets');
      final raw = _unwrap(res.data);
      return (raw as List)
          .map((e) => VendorOutlet.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _friendlyError('fetch outlets', e);
    }
  }

  // ── Categories ─────────────────────────────────────────────────────────────

  /// Fetch product categories (shared catalogue, vendor-visible).
  Future<List<ProductCategory>> fetchCategories() async {
    try {
      // vendorController.getProductCategories → GET /vendor/categories
      final res = await _dio.get('/vendor/categories');
      final raw = _unwrap(res.data);
      return (raw as List)
          .map((e) => ProductCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _friendlyError('fetch categories', e);
    }
  }

  // ── Products ───────────────────────────────────────────────────────────────

  /// Add a new product and initial inventory record.
  /// Maps to: POST /vendor/products (vendorController.createProduct)
  Future<void> addProduct(Map<String, dynamic> payload) async {
    try {
      await _dio.post('/vendor/products', data: payload);
    } on DioException catch (e) {
      throw _friendlyError('add product', e);
    }
  }

  // ── Reports ────────────────────────────────────────────────────────────────

  /// Trigger a CSV/PDF export. Backend logs the request; actual file
  /// delivery depends on your server implementation.
  Future<void> exportInventoryReport() async {
    try {
      await _dio.get('/vendor/inventory/export');
    } on DioException catch (e) {
      // Export is best-effort — surface as a warning, not a crash.
      throw _friendlyError('export report', e);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Normalise backend responses that may be:
  ///   • A raw List
  ///   • A Map with a 'data' key  → {"data": [...]}
  ///   • A JSON string
  dynamic _unwrap(dynamic raw) {
    if (raw is String) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {}
    }
    if (raw is Map && raw.containsKey('data')) return raw['data'];
    return raw;
  }

  String _friendlyError(String op, DioException e) {
    final status = e.response?.statusCode;
    final msg = e.response?.data is Map
        ? e.response!.data['error'] ?? e.response!.data['message']
        : null;
    if (msg != null) return 'Failed to $op: $msg';
    if (status != null) return 'Failed to $op (HTTP $status)';
    return 'Failed to $op: ${e.message}';
  }
}
