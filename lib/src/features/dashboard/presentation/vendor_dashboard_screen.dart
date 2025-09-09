import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VendorDashboardScreen extends StatelessWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: const [
            Expanded(child: _MetricCard(title: 'Today Orders', value: '58')),
            SizedBox(width: 8),
            Expanded(child: _MetricCard(title: 'Revenue', value: '\$3,240')),
            SizedBox(width: 8),
            Expanded(child: _MetricCard(title: 'Avg. Rating', value: '4.6')),
          ]),
          const SizedBox(height: 12),
          Card(child: ListTile(title: const Text('Manage Orders'), onTap: () => context.go('/orders'))),
          Card(child: ListTile(title: const Text('Products & Inventory'), onTap: () => context.go('/products'))),
          Card(child: ListTile(title: const Text('Outlets'), onTap: () => context.go('/outlets'))),
          Card(child: ListTile(title: const Text('Riders'), onTap: () => context.go('/riders'))),
          Card(child: ListTile(title: const Text('Promotions'), onTap: () => context.go('/promotions'))),
          Card(child: ListTile(title: const Text('Transactions'), onTap: () => context.go('/transactions'))),
          Card(child: ListTile(title: const Text('Analytics'), onTap: () => context.go('/analytics'))),
          Card(child: ListTile(title: const Text('Support'), onTap: () => context.go('/support'))),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.inventory), label: 'Products'),
          NavigationDestination(icon: Icon(Icons.store), label: 'Outlets'),
        ],
        selectedIndex: 0,
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/dashboard'); break;
            case 1: context.go('/orders'); break;
            case 2: context.go('/products'); break;
            case 3: context.go('/outlets'); break;
          }
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  const _MetricCard({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
