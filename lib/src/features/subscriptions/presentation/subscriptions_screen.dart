import 'package:flutter/material.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscriptions')),
      body: ListView.builder(
        itemCount: 3,
        itemBuilder: (_, i) => Card(
          child: ListTile(
            title: Text('Plan ${i+1}'),
            subtitle: const Text('Features • Limits • Price'),
            trailing: ElevatedButton(onPressed: () {}, child: const Text('Choose')),
          ),
        ),
      ),
    );
  }
}
