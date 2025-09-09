import 'package:flutter/material.dart';

class OrderDetailScreen extends StatelessWidget {
  final String id;
  const OrderDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order #$id')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(title: Text('Customer'), subtitle: Text('Jane Doe')),
          const ListTile(title: Text('Items'), subtitle: Text('2x Burger, 1x Fries')),
          const ListTile(title: Text('Total'), subtitle: Text('\$28.90')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ElevatedButton(onPressed: () {}, child: const Text('Accept'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Reject'))),
          ]),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: () {}, child: const Text('Assign Rider')),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () {}, child: const Text('Mark as Ready')),
        ],
      ),
    );
  }
}
