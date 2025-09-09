import 'package:flutter/material.dart';

class PromotionsScreen extends StatelessWidget {
  const PromotionsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Promotions')),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add_card)),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (_, i) => SwitchListTile(
          value: i % 2 == 0,
          onChanged: (_) {},
          title: Text('Promo ${i+1} • 10% OFF'),
          subtitle: const Text('Usage: 124 • Active'),
        ),
      ),
    );
  }
}
