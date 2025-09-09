import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: ListView.builder(
        itemCount: 12,
        itemBuilder: (_, i) => Card(
          child: ListTile(
            title: Text('Order #${1000+i}'),
            subtitle: const Text('pending • 3 items • \$42.50'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/orders/${1000+i}'),
          ),
        ),
      ),
    );
  }
}
