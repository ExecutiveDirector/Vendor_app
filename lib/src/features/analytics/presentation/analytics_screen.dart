import 'package:flutter/material.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/widgets/shared_widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic>? _stats;
  List<dynamic> _topProducts = [];
  bool _loading = true;
  String? _error;
  String _period = 'month';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiClient.dio.get('/vendors/dashboard/stats'),
        ApiClient.dio.get('/vendors/analytics/sales',
            queryParameters: {'period': _period}),
        ApiClient.dio.get('/vendors/analytics/products'),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0].data is Map ? results[0].data : {};
          final sales = results[1].data;
          final products = results[2].data;
          _topProducts = products is List ? products.take(5).toList() : [];
          if (sales is Map) {
            _stats!.addAll(sales);
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _period,
            onSelected: (v) => setState(() {
              _period = v;
              _load();
            }),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'week', child: Text('Last 7 days')),
              PopupMenuItem(value: 'month', child: Text('This Month')),
              PopupMenuItem(value: 'year', child: Text('This Year')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Text(_periodLabel, style: const TextStyle(fontSize: 13)),
                const Icon(Icons.arrow_drop_down),
              ]),
            ),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const AppLoading()
          : _error != null
              ? AppError(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // KPI grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.4,
                        children: [
                          _KpiCard(
                            icon: Icons.receipt_long,
                            label: 'Total Orders',
                            value:
                                '${_stats?['totalOrders'] ?? _stats?['orderCount'] ?? 0}',
                            color: cs.primary,
                          ),
                          _KpiCard(
                            icon: Icons.pending_outlined,
                            label: 'Pending',
                            value: '${_stats?['pendingOrders'] ?? 0}',
                            color: Colors.orange,
                          ),
                          _KpiCard(
                            icon: Icons.payments_outlined,
                            label: 'Revenue',
                            value: 'KES ${_formatNum(_stats?['revenue'] ?? 0)}',
                            color: Colors.teal,
                          ),
                          _KpiCard(
                            icon: Icons.inventory_2_outlined,
                            label: 'Products',
                            value: '${_stats?['totalProducts'] ?? 0}',
                            color: Colors.purple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Period comparison
                      if (_stats != null) ...[
                        const SectionHeader(title: 'Period Summary'),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(children: [
                              _SummaryRow(
                                label: 'Period',
                                value: _periodLabel,
                                icon: Icons.calendar_today,
                              ),
                              const Divider(height: 20),
                              _SummaryRow(
                                label: 'Revenue',
                                value:
                                    'KES ${_formatNum(_stats?['revenue'] ?? _stats?['totalRevenue'] ?? 0)}',
                                icon: Icons.trending_up,
                                valueColor: Colors.teal,
                              ),
                              const Divider(height: 20),
                              _SummaryRow(
                                label: 'Orders Completed',
                                value:
                                    '${_stats?['orderCount'] ?? _stats?['totalOrders'] ?? 0}',
                                icon: Icons.check_circle_outline,
                                valueColor: Colors.green,
                              ),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Top products
                      if (_topProducts.isNotEmpty) ...[
                        const SectionHeader(title: 'Top Selling Products'),
                        ..._topProducts.asMap().entries.map((e) {
                          final i = e.key;
                          final p = e.value;
                          final sold = p['total_sold'] ?? 0;
                          final revenue = p['total_revenue'] ?? 0;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: cs.primary.withOpacity(0.1),
                                child: Text('${i + 1}',
                                    style: TextStyle(
                                        color: cs.primary,
                                        fontWeight: FontWeight.bold)),
                              ),
                              title: Text(p['product_name'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                              subtitle: Text('${sold} units sold'),
                              trailing: Text(
                                'KES ${_formatNum(revenue)}',
                                style: TextStyle(
                                    color: cs.primary,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  String get _periodLabel {
    switch (_period) {
      case 'week':
        return 'Last 7 Days';
      case 'year':
        return 'This Year';
      default:
        return 'This Month';
    }
  }

  String _formatNum(dynamic v) {
    final n = (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _KpiCard({
    required this.icon,
    required this.label,
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 24),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
      ]),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18, color: Colors.grey),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(color: Colors.grey)),
      const Spacer(),
      Text(value,
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 15, color: valueColor)),
    ]);
  }
}
