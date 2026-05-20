import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VendorAnalyticsScreen extends StatefulWidget {
  const VendorAnalyticsScreen({super.key});

  @override
  State<VendorAnalyticsScreen> createState() => _VendorAnalyticsScreenState();
}

class _VendorAnalyticsScreenState extends State<VendorAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = '7d';
  bool _isLoading = true;
  String? _error;

  // Analytics data
  Map<String, dynamic> _dashboardStats = {};
  List<dynamic> _recentOrders = [];
  Map<String, dynamic> _salesAnalytics = {};
  List<dynamic> _productAnalytics = [];
  List<dynamic> _lowStockAlerts = [];
  List<dynamic> _inventory = [];

  final List<Map<String, String>> _periods = [
    {'value': '7d', 'label': 'Last 7 Days'},
    {'value': '30d', 'label': 'Last 30 Days'},
    {'value': '90d', 'label': 'Last 3 Months'},
  ];

  final String baseUrl =
      'https://your-api-base-url.com/api'; // Replace with your API URL

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final headers = await _getHeaders();

      // Load all analytics data concurrently
      final results = await Future.wait([
        _fetchDashboardStats(headers),
        _fetchRecentOrders(headers),
        _fetchSalesAnalytics(headers),
        _fetchProductAnalytics(headers),
        _fetchLowStockAlerts(headers),
        _fetchInventory(headers),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _fetchDashboardStats(Map<String, String> headers) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vendor/dashboard/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _dashboardStats = data['data'] ?? data;
        });
      }
    } catch (e) {
      print('Error fetching dashboard stats: $e');
    }
  }

  Future<void> _fetchRecentOrders(Map<String, String> headers) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vendor/orders/recent?limit=10'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _recentOrders = data['data'] ?? data;
        });
      }
    } catch (e) {
      print('Error fetching recent orders: $e');
    }
  }

  Future<void> _fetchSalesAnalytics(Map<String, String> headers) async {
    try {
      final period = _selectedPeriod.replaceAll('d', '');
      final response = await http.get(
        Uri.parse('$baseUrl/vendor/analytics/sales?period=${period}d'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _salesAnalytics = data['data'] ?? data;
        });
      }
    } catch (e) {
      print('Error fetching sales analytics: $e');
    }
  }

  Future<void> _fetchProductAnalytics(Map<String, String> headers) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vendor/analytics/products'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _productAnalytics = data['data'] ?? data;
        });
      }
    } catch (e) {
      print('Error fetching product analytics: $e');
    }
  }

  Future<void> _fetchLowStockAlerts(Map<String, String> headers) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vendor/inventory/low-stock'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _lowStockAlerts = data['data'] ?? data;
        });
      }
    } catch (e) {
      print('Error fetching low stock alerts: $e');
    }
  }

  Future<void> _fetchInventory(Map<String, String> headers) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/vendor/inventory'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _inventory = data['data'] ?? data;
        });
      }
    } catch (e) {
      print('Error fetching inventory: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Analytics Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF64748B)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: PopupMenuButton<String>(
              initialValue: _selectedPeriod,
              onSelected: (String period) {
                setState(() => _selectedPeriod = period);
                _loadAnalytics();
              },
              itemBuilder: (context) => _periods.map((period) {
                return PopupMenuItem(
                  value: period['value'],
                  child: Text(period['label']!),
                );
              }).toList(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _periods.firstWhere(
                        (p) => p['value'] == _selectedPeriod,
                        orElse: () => _periods.first,
                      )['label']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down,
                        color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF3B82F6),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF3B82F6),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Sales'),
            Tab(text: 'Products'),
            Tab(text: 'Inventory'),
          ],
        ),
      ),
      body: _isLoading
          ? const _LoadingWidget()
          : _error != null
              ? _ErrorWidget(error: _error!, onRetry: _loadAnalytics)
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildSalesTab(),
                      _buildProductsTab(),
                      _buildInventoryTab(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildStatsCards(),
        const SizedBox(height: 24),
        _buildQuickActions(),
        const SizedBox(height: 24),
        _buildRecentActivity(),
      ],
    );
  }

  Widget _buildStatsCards() {
    final stats = [
      {
        'title': 'Total Orders',
        'value': _dashboardStats['totalOrders']?.toString() ?? '0',
        'change': '+12.5%',
        'isPositive': true,
        'icon': Icons.shopping_cart_outlined,
        'color': const Color(0xFF3B82F6),
        'bgColor': const Color(0xFFF0F9FF),
      },
      {
        'title': 'Revenue',
        'value': 'KES ${(_dashboardStats['revenue'] ?? 0).toStringAsFixed(0)}',
        'change': '+8.2%',
        'isPositive': true,
        'icon': Icons.attach_money,
        'color': const Color(0xFF10B981),
        'bgColor': const Color(0xFFF0FDF4),
      },
      {
        'title': 'Pending Orders',
        'value': _dashboardStats['pendingOrders']?.toString() ?? '0',
        'change': '-2.1%',
        'isPositive': false,
        'icon': Icons.pending_outlined,
        'color': const Color(0xFFF59E0B),
        'bgColor': const Color(0xFFFFFBEB),
      },
      {
        'title': 'Products',
        'value': _dashboardStats['totalProducts']?.toString() ?? '0',
        'change': '+0.3',
        'isPositive': true,
        'icon': Icons.inventory_outlined,
        'color': const Color(0xFF8B5CF6),
        'bgColor': const Color(0xFFFAF5FF),
      },
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _MetricCard(data: stats[0])),
            const SizedBox(width: 16),
            Expanded(child: _MetricCard(data: stats[1])),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _MetricCard(data: stats[2])),
            const SizedBox(width: 16),
            Expanded(child: _MetricCard(data: stats[3])),
          ],
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
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.inventory_2_outlined,
                label: 'Manage Inventory',
                color: const Color(0xFF3B82F6),
                onTap: () => _tabController.animateTo(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.local_offer_outlined,
                label: 'View Products',
                color: const Color(0xFF10B981),
                onTap: () => _tabController.animateTo(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.analytics_outlined,
                label: 'Sales Report',
                color: const Color(0xFF8B5CF6),
                onTap: () => _tabController.animateTo(1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Orders',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E293B).withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: _recentOrders.take(5).map((order) {
              return _buildOrderItem(order);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order) {
    final statusColor =
        _getStatusColor(order['order_status'] ?? order['status']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              _getStatusIcon(order['order_status'] ?? order['status']),
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order['order_id']?.toString().substring(0, 8) ?? 'N/A'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order['customer']?['full_name'] ?? 'Customer',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'KES ${(order['order_value'] ?? 0).toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order['order_status'] ?? order['status'] ?? 'pending',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'cancelled':
        return const Color(0xFFEF4444);
      case 'preparing':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return Icons.check_circle_outline;
      case 'pending':
        return Icons.schedule;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'preparing':
        return Icons.restaurant;
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildSalesTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSalesOverview(),
        const SizedBox(height: 24),
        _buildSalesChart(),
      ],
    );
  }

  Widget _buildSalesOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          _buildSalesStat(
            'Total Revenue',
            'KES ${(_salesAnalytics['revenue'] ?? 0).toStringAsFixed(0)}',
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 16),
          _buildSalesStat(
            'Order Count',
            '${_salesAnalytics['orderCount'] ?? 0}',
            const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 16),
          _buildSalesStat(
            'Avg Order Value',
            'KES ${(_salesAnalytics['avgOrderValue'] ?? 0).toStringAsFixed(0)}',
            const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesStat(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildSalesChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(show: true),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateSampleSpots(),
                    isCurved: true,
                    color: const Color(0xFF3B82F6),
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateSampleSpots() {
    // Replace with actual data from backend
    return [
      const FlSpot(1, 1500),
      const FlSpot(2, 2300),
      const FlSpot(3, 1800),
      const FlSpot(4, 2800),
      const FlSpot(5, 2200),
      const FlSpot(6, 3200),
      const FlSpot(7, 2900),
    ];
  }

  Widget _buildProductsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Top Performing Products',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        ..._productAnalytics.map((product) => _buildProductItem(product)),
      ],
    );
  }

  Widget _buildProductItem(Map<String, dynamic> product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.local_cafe,
              color: Color(0xFF64748B),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] ?? product['product_name'] ?? 'Product',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product['total_sold'] ?? 0} sold',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'KES ${(product['total_revenue'] ?? product['price'] ?? 0).toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF10B981),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_lowStockAlerts.isNotEmpty) ...[
          _buildLowStockAlerts(),
          const SizedBox(height: 24),
        ],
        _buildInventoryList(),
      ],
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
            fontWeight: FontWeight.w700,
            color: Color(0xFFEF4444),
          ),
        ),
        const SizedBox(height: 16),
        ..._lowStockAlerts.map((item) => _buildAlertItem(item)),
      ],
    );
  }

  Widget _buildAlertItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning,
            color: Color(0xFFEF4444),
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '${item['name'] ?? item['product_name']} - ${item['stock'] ?? item['current_stock']} left',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Inventory Status',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        ..._inventory.map((item) => _buildInventoryItem(item)),
      ],
    );
  }

  Widget _buildInventoryItem(Map<String, dynamic> item) {
    final stock = item['stock'] ?? item['current_stock'] ?? 0;
    final stockColor = stock < 10
        ? const Color(0xFFEF4444)
        : stock < 50
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? item['product_name'] ?? 'Product',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'KES ${(item['price'] ?? item['selling_price'] ?? 0).toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: stockColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$stock in stock',
              style: TextStyle(
                color: stockColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _MetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: data['bgColor'],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  data['icon'],
                  color: data['color'],
                  size: 24,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (data['isPositive']
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444))
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      data['isPositive']
                          ? Icons.trending_up
                          : Icons.trending_down,
                      size: 12,
                      color: data['isPositive']
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      data['change'],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: data['isPositive']
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data['title'],
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data['value'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E293B).withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading analytics...',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Color(0xFFEF4444),
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Unable to load analytics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There was a problem loading your analytics data. Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF64748B),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
