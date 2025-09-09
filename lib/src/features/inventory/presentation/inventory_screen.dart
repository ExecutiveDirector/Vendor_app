import 'package:flutter/material.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: ListView.builder(
        itemCount: 8,
        itemBuilder: (_, i) => Card(
          child: ListTile(
            title: Text('SKU-${100+i}'),
            subtitle: const Text('Outlet: Main • Qty: 42'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.remove), SizedBox(width: 8), Icon(Icons.add)]),
          ),
        ),
      ),
    );
  }
}
