import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/dio_client.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> orders = [];
  List<dynamic> filteredOrders = [];
  bool loading = true;
  String selectedStatus = 'all';
  String searchQuery = '';

  final List<String> statusTabs = [
    'all',
    'pending',
    'confirmed',
    'preparing',
    'ready',
    'dispatched'
  ];
  final Map<String, Color> statusColors = {
    'pending': Colors.orange,
    'confirmed': Colors.blue,
    'preparing': Colors.purple,
    'ready': Colors.green,
    'dispatched': Colors.teal,
    'delivered': Colors.green[700]!,
    'cancelled': Colors.red,
    'refunded': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: statusTabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        selectedStatus = statusTabs[_tabController.index];
      });
      _filterOrders();
    }
  }

  Future<void> _loadOrders() async {
    try {
      setState(() => loading = true);
      final res = await ApiClient.dio.get('/vendor/orders', queryParameters: {
        'include': 'items,customer',
        'sort': 'created_at',
        'order': 'desc',
      });

      setState(() {
        orders = res.data ?? [];
      });
      _filterOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading orders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _filterOrders() {
    setState(() {
      filteredOrders = orders.where((order) {
        final matchesStatus =
            selectedStatus == 'all' || order['order_status'] == selectedStatus;
        final matchesSearch = searchQuery.isEmpty ||
            order['order_number']
                .toString()
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            (order['customer_name'] ?? '')
                .toString()
                .toLowerCase()
                .contains(searchQuery.toLowerCase());
        return matchesStatus && matchesSearch;
      }).toList();
    });
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await ApiClient.dio.patch('/vendor/orders/$orderId', data: {
        'order_status': newStatus,
      });

      await _loadOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to ${newStatus.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              title: const Text(
                'Orders Management',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  onPressed: _loadOrders,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: statusTabs.map((status) {
                  final count = status == 'all'
                      ? orders.length
                      : orders.where((o) => o['order_status'] == status).length;
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(status.toUpperCase()),
                        if (count > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              count.toString(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search orders by number or customer...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() => searchQuery = '');
                            _filterOrders();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() => searchQuery = value);
                  _filterOrders();
                },
              ),
            ),

            // Orders List
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: _buildOrdersList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    if (filteredOrders.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No orders found',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedStatus == 'all'
                ? 'Orders will appear here when customers place them'
                : 'No ${selectedStatus.toUpperCase()} orders at the moment',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['order_status'] ?? 'pending';
    final statusColor = statusColors[status] ?? Colors.grey;
    final orderItems = order['order_items'] as List? ?? [];
    final totalItems = orderItems.fold<int>(
        0, (sum, item) => sum + (item['quantity'] as int? ?? 0));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/orders/${order['order_id']}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order['order_number'] ?? order['order_id']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order['customer_name'] ?? 'Walk-in Customer',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Order Details Row
              Row(
                children: [
                  _buildDetailChip(
                    Icons.shopping_cart,
                    '$totalItems items',
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildDetailChip(
                    Icons.payments,
                    'KES ${(order['total_amount'] ?? 0).toStringAsFixed(2)}',
                    Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _buildDetailChip(
                    Icons.access_time,
                    _formatDateTime(order['created_at']),
                    Colors.orange,
                  ),
                ],
              ),

              if (order['delivery_type'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      order['delivery_type'] == 'pickup'
                          ? Icons.store
                          : Icons.delivery_dining,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order['delivery_type'].toString().toUpperCase(),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Action Buttons
              _buildActionButtons(order),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> order) {
    final status = order['order_status'] ?? 'pending';

    List<Widget> buttons = [];

    switch (status) {
      case 'pending':
        buttons = [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () =>
                  _updateOrderStatus(order['order_id'].toString(), 'confirmed'),
              icon: const Icon(Icons.check_circle, size: 16),
              label: const Text('Accept'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showRejectDialog(order['order_id'].toString()),
              icon: const Icon(Icons.cancel, size: 16),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ];
        break;

      case 'confirmed':
        buttons = [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () =>
                  _updateOrderStatus(order['order_id'].toString(), 'preparing'),
              icon: const Icon(Icons.kitchen, size: 16),
              label: const Text('Start Preparing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ];
        break;

      case 'preparing':
        buttons = [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () =>
                  _updateOrderStatus(order['order_id'].toString(), 'ready'),
              icon: const Icon(Icons.done_all, size: 16),
              label: const Text('Mark Ready'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ];
        break;

      case 'ready':
        if (order['delivery_type'] == 'pickup') {
          buttons = [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _updateOrderStatus(
                    order['order_id'].toString(), 'delivered'),
                icon: const Icon(Icons.handshake, size: 16),
                label: const Text('Customer Picked Up'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ];
        } else {
          buttons = [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    _showAssignRiderDialog(order['order_id'].toString()),
                icon: const Icon(Icons.delivery_dining, size: 16),
                label: const Text('Assign Rider'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ];
        }
        break;

      case 'dispatched':
        buttons = [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping, color: Colors.teal, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Out for Delivery',
                    style: TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ];
        break;

      default:
        buttons = [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Order ${status.toUpperCase()}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: statusColors[status] ?? Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ];
    }

    return Row(children: buttons);
  }

  void _showRejectDialog(String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: const Text(
          'Are you sure you want to reject this order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateOrderStatus(orderId, 'cancelled');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject Order'),
          ),
        ],
      ),
    );
  }

  void _showAssignRiderDialog(String orderId) {
    // This would typically load available riders from the API
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Rider'),
        content:
            const Text('Rider assignment feature will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateOrderStatus(orderId, 'dispatched');
            },
            child: const Text('Assign & Dispatch'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      if (difference.inDays == 1) return 'Yesterday';
      if (difference.inDays < 7) return '${difference.inDays} days ago';

      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}
