class OrderItem {
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const OrderItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        productName: json['product_name'] ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
        totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      );
}

class Order {
  final String orderId;
  final String orderNumber;
  final String orderStatus;
  final String paymentStatus;
  final double totalAmount;
  final double deliveryFee;
  final String? deliveryAddress;
  final String? deliveryContact;
  final String? customerNote;
  final String? riderName;
  final String? vendorName;
  final String createdAt;
  final String? deliveredAt;
  final List<OrderItem> items;

  const Order({
    required this.orderId,
    required this.orderNumber,
    required this.orderStatus,
    required this.paymentStatus,
    required this.totalAmount,
    this.deliveryFee = 0,
    this.deliveryAddress,
    this.deliveryContact,
    this.customerNote,
    this.riderName,
    this.vendorName,
    required this.createdAt,
    this.deliveredAt,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        orderId: json['order_id']?.toString() ?? json['id']?.toString() ?? '',
        orderNumber: json['order_number'] ?? '#—',
        orderStatus: json['order_status'] ?? 'pending',
        paymentStatus: json['payment_status'] ?? 'pending',
        totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
        deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
        deliveryAddress: json['delivery_address'],
        deliveryContact: json['delivery_contact'],
        customerNote: json['customer_note'],
        riderName: json['rider']?['name'] ?? json['rider']?['full_name'],
        vendorName: json['vendor_name'],
        createdAt: json['created_at']?.toString() ?? '',
        deliveredAt: json['delivered_at']?.toString(),
        items: (json['order_items'] as List? ?? [])
            .map((e) => OrderItem.fromJson(e))
            .toList(),
      );

  String get displayStatus {
    switch (orderStatus.toLowerCase()) {
      case 'draft':
        return 'Draft';
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready';
      case 'dispatched':
        return 'Dispatched';
      case 'delivered':
        return 'Delivered';
      case 'canceled':
      case 'cancelled':
        return 'Cancelled';
      default:
        return orderStatus;
    }
  }
}
