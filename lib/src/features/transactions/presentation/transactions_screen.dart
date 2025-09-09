import 'package:flutter/material.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: ListView.separated(
        itemBuilder: (_, i) => ListTile(
          leading: const Icon(Icons.payments),
          title: Text('TX-${2000+i}'),
          subtitle: const Text('Order payment • \$24.90'),
          trailing: const Text('Success'),
        ),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: 12,
      ),
    );
  }
}
