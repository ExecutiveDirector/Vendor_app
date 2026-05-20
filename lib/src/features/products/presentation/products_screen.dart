import 'package:flutter/material.dart';
import '../../../core/api/dio_client.dart';
import 'product_list_widget.dart';
import 'add_edit_product_dialog.dart';
import 'product_details_dialog.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> products = [];
  List<dynamic> categories = [];
  List<dynamic> filteredProducts = [];

  bool loading = true;
  bool _searching = false;
  final _searchController = TextEditingController();
  int? _selectedCategoryId;
  String _sortBy = 'name';

  // ── Computed Stats ────────────────────────────────────────────────────────
  int get totalProducts => products.length;
  int get featuredCount =>
      products.where((p) => p['is_featured'] == true).length;
  int get lowStockCount => products
      .where((p) =>
          (p['stock_quantity'] ?? 0) > 0 && (p['stock_quantity'] ?? 0) < 10)
      .length;
  int get outOfStockCount =>
      products.where((p) => (p['stock_quantity'] ?? 0) == 0).length;
  List<dynamic> get featuredProducts =>
      filteredProducts.where((p) => p['is_featured'] == true).toList();
  List<dynamic> get lowStockProducts =>
      filteredProducts.where((p) => (p['stock_quantity'] ?? 0) < 10).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Data Loading ──────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    try {
      setState(() => loading = true);
      await Future.wait([_loadProducts(), _loadCategories()]);
      _applyFilters();
    } catch (e) {
      _showError('Error loading data: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loadProducts() async {
    final res = await ApiClient.dio.get('/vendor/products');
    if (mounted) setState(() => products = res.data['data'] ?? []);
  }

  Future<void> _loadCategories() async {
    final res = await ApiClient.dio.get('/vendor/product_categories');
    if (mounted) setState(() => categories = res.data['data'] ?? []);
  }

  void _applyFilters() {
    setState(() {
      filteredProducts = products.where((p) {
        final query = _searchController.text.toLowerCase();
        final matchesSearch = query.isEmpty ||
            (p['product_name'] ?? '')
                .toString()
                .toLowerCase()
                .contains(query) ||
            (p['product_code'] ?? '')
                .toString()
                .toLowerCase()
                .contains(query) ||
            (p['brand'] ?? '').toString().toLowerCase().contains(query);
        final matchesCategory = _selectedCategoryId == null ||
            p['category_id'] == _selectedCategoryId;
        return matchesSearch && matchesCategory;
      }).toList();

      filteredProducts.sort((a, b) {
        switch (_sortBy) {
          case 'price':
            return (a['base_price'] ?? 0).compareTo(b['base_price'] ?? 0);
          case 'stock':
            return (b['stock_quantity'] ?? 0)
                .compareTo(a['stock_quantity'] ?? 0);
          default:
            return (a['product_name'] ?? '')
                .toString()
                .compareTo(b['product_name'] ?? '');
        }
      });
    });
  }

  // ── Notifications ─────────────────────────────────────────────────────────
  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor: const Color(0xFFC62828),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 4),
    ));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(msg, style: const TextStyle(fontSize: 13)),
      ]),
      backgroundColor: const Color(0xFF2E7D32),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> _deleteProduct(int productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.delete_forever, color: Colors.red[700], size: 32),
        ),
        title: const Text('Delete Product',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'This product will be permanently removed and cannot be recovered.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiClient.dio.delete('/vendor/products/$productId');
        await _loadData();
        _showSuccess('Product deleted successfully');
      } catch (e) {
        _showError('Error deleting product: $e');
      }
    }
  }

  void _openAddEditDialog({Map<String, dynamic>? product}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddEditProductDialog(
        categories: categories,
        product: product,
        onSave: () async {
          await _loadData();
          _showSuccess(
            product == null
                ? '✅ Product added successfully'
                : '✅ Product updated',
          );
        },
      ),
    );
  }

  void _openProductDetails(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (_) => ProductDetailsDialog(
        product: product,
        onEdit: () => _openAddEditDialog(product: product),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(innerBoxIsScrolled),
        ],
        body: loading
            ? _buildSkeleton()
            : Column(
                children: [
                  _buildSearchBar(),
                  _buildFilterRow(),
                  _buildStatsBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        ProductListWidget(
                          products: filteredProducts,
                          onDelete: _deleteProduct,
                          onEdit: _openAddEditDialog,
                          onTap: _openProductDetails,
                          refresh: _loadData,
                        ),
                        ProductListWidget(
                          products: featuredProducts,
                          onDelete: _deleteProduct,
                          onEdit: _openAddEditDialog,
                          onTap: _openProductDetails,
                          refresh: _loadData,
                        ),
                        ProductListWidget(
                          products: lowStockProducts,
                          onDelete: _deleteProduct,
                          onEdit: _openAddEditDialog,
                          onTap: _openProductDetails,
                          refresh: _loadData,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ── SliverAppBar ──────────────────────────────────────────────────────────
  Widget _buildSliverAppBar(bool collapsed) {
    return SliverAppBar(
      expandedHeight: 110,
      floating: true,
      pinned: true,
      snap: false,
      elevation: collapsed ? 3 : 0,
      backgroundColor: const Color(0xFF1B5E20),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Products',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalProducts products · $outOfStockCount out of stock',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        title: collapsed
            ? const Text(
                'Products',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
            : null,
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(46),
        child: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: [
            Tab(text: 'All (${filteredProducts.length})'),
            Tab(text: 'Featured ($featuredCount)'),
            Tab(text: 'Low Stock ($lowStockCount)'),
          ],
        ),
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: TextField(
        controller: _searchController,
        onChanged: (v) {
          setState(() => _searching = v.isNotEmpty);
          _applyFilters();
        },
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search by name, code, brand…',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded,
              color: Color(0xFF4CAF50), size: 22),
          suffixIcon: _searching
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  color: Colors.grey[500],
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searching = false);
                    _applyFilters();
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF5F7F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // ── Filter Row ────────────────────────────────────────────────────────────
  Widget _buildFilterRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _compactDropdown<int?>(
              value: _selectedCategoryId,
              icon: Icons.category_outlined,
              hint: 'All Categories',
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text('All Categories',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                ),
                ...categories.map<DropdownMenuItem<int?>>(
                    (cat) => DropdownMenuItem<int?>(
                          value: cat['category_id'],
                          child: Text(cat['category_name'] ?? '',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                        )),
              ],
              onChanged: (v) {
                setState(() => _selectedCategoryId = v);
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _compactDropdown<String>(
              value: _sortBy,
              icon: Icons.sort_rounded,
              hint: 'Sort',
              items: const [
                DropdownMenuItem(
                    value: 'name',
                    child: Text('Name', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(
                    value: 'price',
                    child: Text('Price', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(
                    value: 'stock',
                    child: Text('Stock', style: TextStyle(fontSize: 12))),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _sortBy = v);
                  _applyFilters();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactDropdown<T>({
    required T value,
    required IconData icon,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Row(children: [
            Icon(icon, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(hint, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ]),
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          icon: Icon(Icons.expand_more, size: 18, color: Colors.grey[500]),
          style: const TextStyle(color: Colors.black87, fontSize: 12),
        ),
      ),
    );
  }

  // ── Stats Bar ─────────────────────────────────────────────────────────────
  Widget _buildStatsBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          _statChip(
            '$totalProducts',
            'Total',
            const Color(0xFF1565C0),
            Icons.inventory_2_outlined,
          ),
          const SizedBox(width: 8),
          _statChip(
            '$featuredCount',
            'Featured',
            Colors.orange[800]!,
            Icons.star_outline_rounded,
          ),
          const SizedBox(width: 8),
          _statChip(
            '$lowStockCount',
            'Low Stock',
            lowStockCount > 0
                ? const Color(0xFFBF360C)
                : const Color(0xFF2E7D32),
            Icons.warning_amber_outlined,
          ),
          const SizedBox(width: 8),
          _statChip(
            '$outOfStockCount',
            'No Stock',
            outOfStockCount > 0 ? const Color(0xFFC62828) : Colors.grey[500]!,
            Icons.remove_circle_outline,
          ),
        ],
      ),
    );
  }

  Widget _statChip(String count, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 3),
            Text(
              count,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                  fontSize: 9, color: color, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Skeleton Loading ──────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => _skeletonCard(),
    );
  }

  Widget _skeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          _shimmer(90, 90, radius: 12),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmer(16, double.infinity),
                const SizedBox(height: 8),
                _shimmer(12, 120),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _shimmer(26, 80, radius: 8),
                    const SizedBox(width: 8),
                    _shimmer(26, 80, radius: 8),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmer(double h, double w, {double radius = 6}) => Container(
        height: h,
        width: w == double.infinity ? null : w,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(radius),
        ),
      );

  // ── FAB ───────────────────────────────────────────────────────────────────
  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _openAddEditDialog(),
      backgroundColor: const Color(0xFF1B5E20),
      elevation: 5,
      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
      label: const Text(
        'Add Product',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
