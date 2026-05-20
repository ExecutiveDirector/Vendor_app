import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/dio_client.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen>
    with TickerProviderStateMixin {
  bool loading = true;
  bool refreshing = false;
  Map<String, dynamic> stats = {};
  Map<String, dynamic> vendorInfo = {};
  List<dynamic> recentOrders = [];
  List<dynamic> lowStockProducts = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadDashboardData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => loading = true);
      await Future.wait([
        _loadStats(),
        _loadVendorInfo(),
        _loadRecentOrders(),
        _loadLowStock(),
      ]);
      _animationController.forward();
    } catch (e) {
      if (mounted) _showError('Error loading dashboard: ${e.toString()}');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loadStats() async {
    try {
      // ✅ FIX: /vendor/dashboard/stats → /vendors/dashboard/stats
      final res = await ApiClient.dio.get('/vendors/dashboard/stats');
      if (mounted) setState(() => stats = res.data ?? {});
    } catch (e) {
      // Handle silently — dashboard still loads other sections
    }
  }

  Future<void> _loadVendorInfo() async {
    try {
      // ✅ FIX: /vendor/profile → /auth/profile (unified profile endpoint)
      final res = await ApiClient.dio.get('/auth/profile');
      // Profile returns { account, profile (vendor fields), role }
      final profile = res.data?['profile'] as Map<String, dynamic>? ?? {};
      if (mounted) setState(() => vendorInfo = profile);
    } catch (e) {
      // Handle silently
    }
  }

  Future<void> _loadRecentOrders() async {
    try {
      // ✅ FIX: /vendor/orders → /vendors/orders
      final res = await ApiClient.dio.get(
        '/vendors/orders',
        queryParameters: {'limit': 5, 'page': 1},
      );
      if (mounted) setState(() => recentOrders = res.data ?? []);
    } catch (e) {
      // Handle silently
    }
  }

  Future<void> _loadLowStock() async {
    try {
      // ✅ FIX: /vendor/inventory/low-stock → /vendors/inventory/low-stock
      final res = await ApiClient.dio.get(
        '/vendors/inventory/low-stock',
        queryParameters: {'threshold': 10, 'limit': 5},
      );
      if (mounted) setState(() => lowStockProducts = res.data ?? []);
    } catch (e) {
      // Handle silently
    }
  }

  Future<void> _refreshData() async {
    if (refreshing) return;
    setState(() => refreshing = true);
    await _loadDashboardData();
    setState(() => refreshing = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFE53E3E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8A00)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: const Color(0xFFFF8A00),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatsGrid(),
                              const SizedBox(height: 24),
                              _buildQuickActions(),
                              const SizedBox(height: 24),
                              _buildRecentOrders(),
                              const SizedBox(height: 24),
                              _buildLowStockAlerts(),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFFFF8A00),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF8A00), Color(0xFFE65100)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            (vendorInfo['business_name'] ?? 'V')[0]
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF8A00),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vendorInfo['business_name'] ?? 'Your Business',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (vendorInfo['rating'] != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Color(0xFFFFD700), size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(vendorInfo['rating'] ?? 0.0).toStringAsFixed(1)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.push('/settings'),
                        icon: const Icon(Icons.settings_outlined,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(
          title: 'Total Orders',
          value: _formatNumber(stats['totalOrders'] ?? 0),
          icon: Icons.shopping_cart_outlined,
          color: const Color(0xFF10B981),
        ),
        _StatCard(
          title: 'Revenue',
          value: 'KES ${_formatCurrency(stats['revenue'] ?? 0)}',
          icon: Icons.trending_up_outlined,
          color: const Color(0xFF3B82F6),
        ),
        _StatCard(
          title: 'Products',
          value: _formatNumber(stats['totalProducts'] ?? 0),
          icon: Icons.inventory_2_outlined,
          color: const Color(0xFF8B5CF6),
        ),
        _StatCard(
          title: 'Pending',
          value: _formatNumber(stats['pendingOrders'] ?? 0),
          icon: Icons.pending_outlined,
          color: const Color(0xFFFF8A00),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _QuickActionCard(
              title: 'My Outlets',
              icon: Icons.storefront_outlined,
              onTap: () => context.push('/outlets'),
              color: const Color(0xFF10B981),
            ),
            _QuickActionCard(
              title: 'Orders',
              icon: Icons.receipt_long_outlined,
              onTap: () => context.push('/orders'),
              color: const Color(0xFF3B82F6),
            ),
            _QuickActionCard(
              title: 'Products',
              icon: Icons.inventory_2_outlined,
              onTap: () => context.push('/products'),
              color: const Color(0xFF8B5CF6),
            ),
            _QuickActionCard(
              title: 'Analytics',
              icon: Icons.analytics_outlined,
              onTap: () => context.push('/analytics'),
              color: const Color(0xFFFF8A00),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentOrders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Recent Orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.push('/orders'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        recentOrders.isEmpty
            ? _buildEmptyState('No recent orders', Icons.shopping_bag_outlined)
            : Column(
                children: recentOrders
                    .take(3)
                    .map((order) => _buildOrderCard(order))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status =
        (order['order_status'] ?? order['status'] ?? 'pending').toString();
    final statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.shopping_bag, color: statusColor, size: 20),
        ),
        title: Text(
          'Order #${order['order_id']}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(_formatDateTime(order['created_at'])),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ),
        onTap: () => context.push('/orders/${order['order_id']}'),
      ),
    );
  }

  Widget _buildLowStockAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Low Stock Alerts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        lowStockProducts.isEmpty
            ? Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF10B981)),
                    SizedBox(width: 12),
                    Text('All products are well stocked!'),
                  ],
                ),
              )
            : Column(
                children: lowStockProducts
                    .take(3)
                    .map((item) => _buildLowStockCard(item))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildLowStockCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFBF00)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFBF00).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                const Icon(Icons.warning, color: Color(0xFFFFBF00), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['product_name'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Only ${item['current_stock']} left',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'LOW',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return NavigationBar(
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFFF8A00).withOpacity(0.1),
      selectedIndex: 0,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: 'Products',
        ),
        NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront),
          label: 'Outlets',
        ),
      ],
      onDestinationSelected: (i) {
        final routes = ['/dashboard', '/orders', '/products', '/outlets'];
        if (i != 0) context.go(routes[i]);
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      case 'processing':
      case 'confirmed':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFFFF8A00);
    }
  }

  String _formatNumber(num n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  String _formatCurrency(num amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  String _formatDateTime(String? dt) {
    if (dt == null) return 'Unknown';
    try {
      final date = DateTime.parse(dt);
      final diff = DateTime.now().difference(date);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 14, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
