import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/services/local_storage.dart';
import '../../../core/widgets/shared_widgets.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});
  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  Map<String, dynamic>? _stats;
  List<dynamic> _recentOrders = [];
  bool _loading = true;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiClient.dio.get('/vendors/dashboard/stats'),
        ApiClient.dio.get('/vendors/orders',
            queryParameters: {'limit': '5', 'page': '1'}),
      ]);
      if (mounted) {
        setState(() {
          _stats = results[0].data is Map ? results[0].data : {};
          _recentOrders = results[1].data is List ? results[1].data : [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await LocalStorage.clear();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Dashboard'),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => context.go('/notifications')),
          IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.go('/settings')),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _loading
          ? const AppLoading(message: 'Loading dashboard...')
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Metrics row
                  Row(children: [
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.receipt_long,
                        title: 'Total Orders',
                        value: '${_stats?['totalOrders'] ?? 0}',
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.pending,
                        title: 'Pending',
                        value: '${_stats?['pendingOrders'] ?? 0}',
                        color: Colors.orange,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.payments,
                        title: 'Revenue',
                        value: 'KES ${_formatNum(_stats?['revenue'] ?? 0)}',
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.inventory_2,
                        title: 'Products',
                        value: '${_stats?['totalProducts'] ?? 0}',
                        color: Colors.purple,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Quick actions
                  const SectionHeader(title: 'Quick Actions'),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1,
                    children: [
                      _ActionTile(
                          icon: Icons.receipt_long,
                          label: 'Orders',
                          onTap: () => context.go('/orders')),
                      _ActionTile(
                          icon: Icons.fastfood,
                          label: 'Products',
                          onTap: () => context.go('/products')),
                      _ActionTile(
                          icon: Icons.inventory_2,
                          label: 'Inventory',
                          onTap: () => context.go('/inventory')),
                      _ActionTile(
                          icon: Icons.store,
                          label: 'Outlets',
                          onTap: () => context.go('/outlets')),
                      _ActionTile(
                          icon: Icons.delivery_dining,
                          label: 'Riders',
                          onTap: () => context.go('/riders')),
                      _ActionTile(
                          icon: Icons.bar_chart,
                          label: 'Analytics',
                          onTap: () => context.go('/analytics')),
                      _ActionTile(
                          icon: Icons.local_offer,
                          label: 'Promos',
                          onTap: () => context.go('/promotions')),
                      _ActionTile(
                          icon: Icons.payments,
                          label: 'Transactions',
                          onTap: () => context.go('/transactions')),
                      _ActionTile(
                          icon: Icons.support_agent,
                          label: 'Support',
                          onTap: () => context.go('/support')),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Recent orders
                  const SectionHeader(
                    title: 'Recent Orders',
                    trailing: TextButton(
                      onPressed: null,
                      child: Text('View all'),
                    ),
                  ),
                  if (_recentOrders.isEmpty)
                    const AppEmpty(
                      icon: Icons.receipt_long_outlined,
                      message: 'No recent orders',
                    )
                  else
                    ..._recentOrders
                        .take(5)
                        .map((o) => _RecentOrderTile(order: o)),
                  const SizedBox(height: 32),
                ],
              ),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) {
          setState(() => _navIndex = i);
          switch (i) {
            case 0:
              break;
            case 1:
              context.go('/orders');
              break;
            case 2:
              context.go('/products');
              break;
            case 3:
              context.go('/analytics');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Orders'),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Products'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Analytics'),
        ],
      ),
    );
  }

  String _formatNum(dynamic v) {
    final n = (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
            Text(value,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ]),
        ),
      ]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: cs.primary, size: 26),
            const SizedBox(height: 6),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  final dynamic order;
  const _RecentOrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = order['order_status']?.toString() ?? 'pending';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => context.go('/orders/${order['order_id']}'),
        leading: CircleAvatar(
          backgroundColor: cs.primary.withOpacity(0.1),
          child: Icon(Icons.receipt, color: cs.primary, size: 18),
        ),
        title: Text(order['order_number'] ?? '#—',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          'KES ${(order['total_amount'] as num?)?.toStringAsFixed(0) ?? 0}',
          style: TextStyle(color: cs.primary),
        ),
        trailing: StatusBadge(status: status),
      ),
    );
  }
}
