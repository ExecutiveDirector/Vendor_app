import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/dio_client.dart';

class OrderDetailScreen extends StatefulWidget {
  final String id;
  const OrderDetailScreen({super.key, required this.id});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic> order = {};
  List<dynamic> orderItems = [];
  bool loading = true;

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

  final Map<String, IconData> statusIcons = {
    'pending': Icons.pending,
    'confirmed': Icons.check_circle_outline,
    'preparing': Icons.kitchen,
    'ready': Icons.done_all,
    'dispatched': Icons.local_shipping,
    'delivered': Icons.check_circle,
    'cancelled': Icons.cancel,
    'refunded': Icons.money_off,
  };

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      setState(() => loading = true);
      final res = await ApiClient.dio
          .get('/vendor/orders/${widget.id}', queryParameters: {
        'include': 'items,customer,delivery,payment',
      });

      setState(() {
        order = res.data ?? {};
        orderItems = order['order_items'] ?? [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading order details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    try {
      await ApiClient.dio.patch('/vendor/orders/${widget.id}', data: {
        'order_status': newStatus,
      });

      await _loadOrderDetails();

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
    if (loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Order #${widget.id}'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final status = order['order_status'] ?? 'pending';
    final statusColor = statusColors[status] ?? Colors.grey;

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order['order_number'] ?? widget.id}'),
        backgroundColor: statusColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadOrderDetails,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrderDetails,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              _buildStatusCard(),
              const SizedBox(height: 16),

              // Customer Information
              _buildCustomerCard(),
              const SizedBox(height: 16),

              // Order Items
              _buildOrderItemsCard(),
              const SizedBox(height: 16),

              // Order Summary
              _buildOrderSummaryCard(),
              const SizedBox(height: 16),

              // Delivery Information
              if (order['delivery_type'] != 'pickup') _buildDeliveryCard(),
              if (order['delivery_type'] != 'pickup')
                const SizedBox(height: 16),

              // Payment Information
              _buildPaymentCard(),
              const SizedBox(height: 16),

              // Action Buttons
              _buildActionButtons(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = order['order_status'] ?? 'pending';
    final statusColor = statusColors[status] ?? Colors.grey;
    final statusIcon = statusIcons[status] ?? Icons.info;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              statusColor.withOpacity(0.1),
              statusColor.withOpacity(0.05)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(statusIcon, color: statusColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Status',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _formatDateTime(order['created_at']),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Customer Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Name', order['customer_name'] ?? 'Walk-in Customer'),
            if (order['customer_phone'] != null)
              _buildInfoRow('Phone', order['customer_phone']),
            if (order['customer_email'] != null)
              _buildInfoRow('Email', order['customer_email']),
            if (order['delivery_address'] != null)
              _buildInfoRow('Delivery Address', order['delivery_address']),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_cart, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Order Items',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...orderItems.map((item) => _buildOrderItem(item)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${item['quantity']}x',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['product_name'] ?? 'Unknown Product',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'KES ${(item['unit_price'] ?? 0).toStringAsFixed(2)} each',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'KES ${(item['total_price'] ?? 0).toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Subtotal', order['subtotal'] ?? 0),
            if ((order['tax_amount'] ?? 0) > 0)
              _buildSummaryRow('Tax', order['tax_amount'] ?? 0),
            if ((order['delivery_fee'] ?? 0) > 0)
              _buildSummaryRow('Delivery Fee', order['delivery_fee'] ?? 0),
            if ((order['discount_amount'] ?? 0) > 0)
              _buildSummaryRow('Discount', -(order['discount_amount'] ?? 0),
                  isDiscount: true),
            const Divider(),
            _buildSummaryRow('Total', order['total_amount'] ?? 0,
                isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.delivery_dining, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Delivery Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
                'Delivery Type',
                (order['delivery_type'] ?? 'home_delivery')
                    .toString()
                    .replaceAll('_', ' ')
                    .toUpperCase()),
            if (order['estimated_delivery_time'] != null)
              _buildInfoRow('Estimated Delivery',
                  _formatDateTime(order['estimated_delivery_time'])),
            if (order['actual_delivery_time'] != null)
              _buildInfoRow('Delivered At',
                  _formatDateTime(order['actual_delivery_time'])),
            if (order['delivery_notes'] != null)
              _buildInfoRow('Delivery Notes', order['delivery_notes']),
            if (order['rider_name'] != null)
              _buildInfoRow('Assigned Rider', order['rider_name']),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Payment Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Payment Status: '),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPaymentStatusColor(order['payment_status'])
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (order['payment_status'] ?? 'pending').toUpperCase(),
                    style: TextStyle(
                      color: _getPaymentStatusColor(order['payment_status']),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (order['payment_method'] != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Payment Method', order['payment_method']),
            ],
            if (order['transaction_id'] != null)
              _buildInfoRow('Transaction ID', order['transaction_id']),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final status = order['order_status'] ?? 'pending';

    List<Widget> buttons = [];

    switch (status) {
      case 'pending':
        buttons = [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateOrderStatus('confirmed'),
              icon: const Icon(Icons.check_circle),
              label: const Text('Accept Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showRejectDialog(),
              icon: const Icon(Icons.cancel),
              label: const Text('Reject Order'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ];
        break;

      case 'confirmed':
        buttons = [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _updateOrderStatus('preparing'),
              icon: const Icon(Icons.kitchen),
              label: const Text('Start Preparing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ];
        break;

      case 'preparing':
        buttons = [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _updateOrderStatus('ready'),
              icon: const Icon(Icons.done_all),
              label: const Text('Mark as Ready'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ];
        break;

      case 'ready':
        if (order['delivery_type'] == 'pickup') {
          buttons = [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _updateOrderStatus('delivered'),
                icon: const Icon(Icons.handshake),
                label: const Text('Customer Picked Up'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ];
        } else {
          buttons = [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAssignRiderDialog(),
                icon: const Icon(Icons.delivery_dining),
                label: const Text('Assign Rider & Dispatch'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ];
        }
        break;

      case 'dispatched':
      case 'delivered':
      case 'cancelled':
      case 'refunded':
        buttons = [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: statusColors[status]!.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColors[status]!.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(statusIcons[status],
                    color: statusColors[status], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Order ${status.toUpperCase()}',
                  style: TextStyle(
                    color: statusColors[status],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ];
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(children: buttons),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, num amount,
      {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? Colors.green : null,
            ),
          ),
          Text(
            'KES ${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isDiscount ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPaymentStatusColor(String? status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'partially_paid':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: const Text(
          'Are you sure you want to reject this order? This action cannot be undone and the customer will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateOrderStatus('cancelled');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject Order'),
          ),
        ],
      ),
    );
  }

  void _showAssignRiderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Rider'),
        content: const Text(
          'This will assign an available rider to this order and mark it as dispatched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateOrderStatus('dispatched');
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
      if (difference.inMinutes < 60)
        return '${difference.inMinutes} minutes ago';
      if (difference.inHours < 24) return '${difference.inHours} hours ago';
      if (difference.inDays == 1)
        return 'Yesterday at ${TimeOfDay.fromDateTime(dateTime).format(context)}';

      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${TimeOfDay.fromDateTime(dateTime).format(context)}';
    } catch (e) {
      return 'Unknown';
    }
  }
}
