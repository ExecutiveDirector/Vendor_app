// inventory_screen.dart
// Main inventory screen. Owns all state; delegates rendering to modular widgets.
//
// Architecture:
//   InventoryScreen (state owner)
//     ├─ InventoryHeader  (search + filter chips)
//     ├─ TabBar           (All / Low Stock / Out of Stock / Expiring)
//     └─ TabBarView
//          ├─ InventoryList (All)        ← shows InventorySummary as header
//          ├─ InventoryList (Low Stock)
//          ├─ InventoryList (Out of Stock)
//          └─ InventoryList (Expiring Soon)
//
// Filtering is pure in-memory — no extra API calls when the user changes
// search/filter/sort.  Data is refreshed via pull-to-refresh or the menu.

import 'package:flutter/material.dart';
import 'inventory_models.dart';
import 'inventory_service.dart';
import 'inventory_header.dart';
import 'inventory_list.dart';
import 'inventory_summary.dart';
import 'inventory_dialogs.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────────────
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // ── State ────────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  bool _isUpdating = false; // spinner for individual stock updates
  String? _error;

  // ── Filter state ─────────────────────────────────────────────────────────────
  int? _selectedOutletId;
  String? _selectedCategory;
  String _sortBy = 'product_name';
  bool _sortDescending = false;

  // ── Data ─────────────────────────────────────────────────────────────────────
  List<VendorInventory> _allItems = [];
  List<VendorOutlet> _outlets = [];
  List<ProductCategory> _categories = [];

  final InventoryService _service = InventoryService();

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────────────────────────

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.fetchInventory(),
        _service.fetchOutlets(),
        _service.fetchCategories(),
      ]);
      if (!mounted) return;
      setState(() {
        _allItems = results[0] as List<VendorInventory>;
        _outlets = results[1] as List<VendorOutlet>;
        _categories = results[2] as List<ProductCategory>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshInventory() async {
    try {
      final items = await _service.fetchInventory();
      if (!mounted) return;
      setState(() => _allItems = items);
    } catch (e) {
      _showSnack('Failed to refresh: $e', isError: true);
    }
  }

  // ── Stock update ─────────────────────────────────────────────────────────────

  Future<void> _updateStock(int inventoryId, int newStock) async {
    setState(() => _isUpdating = true);
    try {
      await _service.updateStock(inventoryId, newStock);
      // Optimistically update in-memory list without a full network reload.
      setState(() {
        _allItems = _allItems.map((item) {
          if (item.inventoryId == inventoryId) {
            return item.copyWith(currentStock: newStock);
          }
          return item;
        }).toList();
      });
      _showSnack('Stock updated successfully');
    } catch (e) {
      _showSnack('Error updating stock: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  // ── Filtering ────────────────────────────────────────────────────────────────

  List<VendorInventory> get _filteredItems {
    final query = _searchController.text.toLowerCase().trim();

    var result = _allItems.where((item) {
      final matchesQuery = query.isEmpty ||
          item.productName.toLowerCase().contains(query) ||
          item.sku.toLowerCase().contains(query) ||
          item.categoryName.toLowerCase().contains(query);

      final matchesOutlet =
          _selectedOutletId == null || item.outletId == _selectedOutletId;

      final matchesCategory = _selectedCategory == null ||
          _selectedCategory!.isEmpty ||
          item.categoryName == _selectedCategory;

      return matchesQuery && matchesOutlet && matchesCategory;
    }).toList();

    result.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case 'current_stock':
          cmp = a.currentStock.compareTo(b.currentStock);
          break;
        case 'price':
          cmp = a.costPrice.compareTo(b.sellingPrice);
          break;
        case 'expiry_date':
          final aDate = a.expiryDate ?? DateTime(9999);
          final bDate = b.expiryDate ?? DateTime(9999);
          cmp = aDate.compareTo(bDate);
          break;
        default:
          cmp = a.productName
              .toLowerCase()
              .compareTo(b.productName.toLowerCase());
      }
      return _sortDescending ? -cmp : cmp;
    });

    return result;
  }

  List<VendorInventory> get _lowStockItems =>
      _filteredItems.where((i) => i.isLowStock).toList();

  List<VendorInventory> get _outOfStockItems =>
      _filteredItems.where((i) => i.isOutOfStock).toList();

  List<VendorInventory> get _expiringItems =>
      _filteredItems.where((i) => i.isExpiringSoon).toList();

  String get _sortDisplayName {
    switch (_sortBy) {
      case 'current_stock':
        return 'Stock${_sortDescending ? ' ↓' : ' ↑'}';
      case 'price':
        return 'Price${_sortDescending ? ' ↓' : ' ↑'}';
      case 'expiry_date':
        return 'Expiry${_sortDescending ? ' ↓' : ' ↑'}';
      default:
        return 'Name${_sortDescending ? ' Z→A' : ' A→Z'}';
    }
  }

  // ── Menu actions ─────────────────────────────────────────────────────────────

  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        _loadInitialData();
        break;
      case 'export':
        _exportReport();
        break;
      case 'bulk_update':
        showBulkUpdateDialog(context, onBulkUpdated: _refreshInventory);
        break;
    }
  }

  Future<void> _exportReport() async {
    try {
      await _service.exportInventoryReport();
      _showSnack('Export started — check your downloads');
    } catch (e) {
      _showSnack('Export failed: $e', isError: true);
    }
  }

  // ── Dialog openers ────────────────────────────────────────────────────────────

  void _openFilterDialog() => showFilterDialog(
        context,
        outlets: _outlets,
        categories: _categories,
        selectedOutletId: _selectedOutletId,
        selectedCategory: _selectedCategory,
        sortBy: _sortBy,
        sortDescending: _sortDescending,
        onApply: (outletId, category, sortBy, desc) => setState(() {
          _selectedOutletId = outletId;
          _selectedCategory = category;
          _sortBy = sortBy;
          _sortDescending = desc;
        }),
      );

  void _openAddProductDialog() => showAddProductDialog(
        context,
        categories: _categories,
        outlets: _outlets,
        onAdded: (payload) async {
          try {
            await _service.addProduct(payload);
            _showSnack('Product added');
            await _refreshInventory();
          } catch (e) {
            _showSnack('Failed to add product: $e', isError: true);
          }
        },
      );

  void _openStockUpdateDialog(VendorInventory item) => showStockUpdateDialog(
        context,
        item,
        onUpdated: (newStock) => _updateStock(item.inventoryId, newStock),
      );

  void _openProductDetails(VendorInventory item) =>
      showProductDetailsDialog(context, item);

  // ── UI helpers ────────────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red[700] : null,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _loadInitialData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Pre-compute filtered lists once so tab labels stay in sync.
    final filtered = _filteredItems;
    final lowStock = _lowStockItems;
    final outOfStock = _outOfStockItems;
    final expiring = _expiringItems;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(filtered, lowStock, outOfStock, expiring),
      body: Stack(
        children: [
          Column(
            children: [
              InventoryHeader(
                searchController: _searchController,
                outlets: _outlets,
                categories: _categories,
                selectedOutletId: _selectedOutletId,
                selectedCategory: _selectedCategory,
                sortDisplayName: _sortDisplayName,
                onClearSearch: () => setState(() {}),
                onSearchChanged: () => setState(() {}),
                onOpenOutletSelector: () => showOutletSelectorDialog(
                  context,
                  outlets: _outlets,
                  selectedId: _selectedOutletId,
                  onSelected: (id) => setState(() => _selectedOutletId = id),
                ),
                onOpenCategorySelector: () => showCategorySelectorDialog(
                  context,
                  categories: _categories,
                  selected: _selectedCategory,
                  onSelected: (c) => setState(() => _selectedCategory = c),
                ),
                onOpenSortDialog: () => showSortDialog(
                  context,
                  currentSortBy: _sortBy,
                  currentDescending: _sortDescending,
                  onSelected: (sortBy, desc) => setState(() {
                    _sortBy = sortBy;
                    _sortDescending = desc;
                  }),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // All items — shows summary card at the top
                    InventoryList(
                      items: filtered,
                      onRefresh: _refreshInventory,
                      onUpdateStock: _openStockUpdateDialog,
                      onShowDetails: _openProductDetails,
                      header: InventorySummary(items: _allItems),
                    ),
                    InventoryList(
                      items: lowStock,
                      onRefresh: _refreshInventory,
                      onUpdateStock: _openStockUpdateDialog,
                      onShowDetails: _openProductDetails,
                    ),
                    InventoryList(
                      items: outOfStock,
                      onRefresh: _refreshInventory,
                      onUpdateStock: _openStockUpdateDialog,
                      onShowDetails: _openProductDetails,
                    ),
                    InventoryList(
                      items: expiring,
                      onRefresh: _refreshInventory,
                      onUpdateStock: _openStockUpdateDialog,
                      onShowDetails: _openProductDetails,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Loading overlay for individual stock updates
          if (_isUpdating)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddProductDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    List<VendorInventory> filtered,
    List<VendorInventory> lowStock,
    List<VendorInventory> outOfStock,
    List<VendorInventory> expiring,
  ) {
    return AppBar(
      title: const Text('Inventory'),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0.5,
      actions: [
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.filter_list),
              if (_selectedOutletId != null || _selectedCategory != null)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: _openFilterDialog,
          tooltip: 'Filter',
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'refresh',
              child: Row(children: [
                Icon(Icons.refresh, size: 20),
                SizedBox(width: 8),
                Text('Refresh'),
              ]),
            ),
            PopupMenuItem(
              value: 'export',
              child: Row(children: [
                Icon(Icons.download, size: 20),
                SizedBox(width: 8),
                Text('Export Report'),
              ]),
            ),
            PopupMenuItem(
              value: 'bulk_update',
              child: Row(children: [
                Icon(Icons.edit_note, size: 20),
                SizedBox(width: 8),
                Text('Bulk Update'),
              ]),
            ),
          ],
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey[600],
        indicatorSize: TabBarIndicatorSize.tab,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: [
          Tab(text: 'All (${filtered.length})'),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (lowStock.isNotEmpty)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                Text('Low Stock (${lowStock.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (outOfStock.isNotEmpty)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                Text('Out of Stock (${outOfStock.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (expiring.isNotEmpty)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                Text('Expiring (${expiring.length})'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
