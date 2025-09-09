import 'package:flutter/material.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add)),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (_, i) => ListTile(
          leading: const Icon(Icons.fastfood),
          title: Text('Product ${i+1}'),
          subtitle: const Text('\$9.99 • In Stock'),
          trailing: const Icon(Icons.edit),
          onTap: () {},
        ),
      ),
    );
  }
}
