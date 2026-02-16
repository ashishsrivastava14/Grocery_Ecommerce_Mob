import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/admin_provider.dart';
import 'widgets/admin_stat_card.dart';
import 'widgets/admin_status_badge.dart';
import 'widgets/admin_common.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(adminDashboardProvider);

    return dashboardAsync.when(
      loading: () => const AdminLoadingState(),
      error: (error, _) => AdminErrorState(
        message: error.toString(),
        onRetry: () => ref.invalidate(adminDashboardProvider),
      ),
      data: (data) => _DashboardContent(data: data),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  final Map<String, dynamic> data;
  const _DashboardContent({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminDashboardProvider);
        ref.invalidate(adminRecentOrdersProvider);
        ref.invalidate(adminTopVendorsProvider);
        ref.invalidate(adminTopProductsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminPageHeader(
              title: 'Dashboard',
              subtitle: 'Welcome back! Here\'s your platform overview.',
            ),
            const SizedBox(height: 24),
            // ─── Stat Cards Row ───────────────────────────────
            _buildStatCards(context),
            const SizedBox(height: 24),
            // ─── Revenue Chart ────────────────────────────────
            _RevenueChartSection(),
            const SizedBox(height: 24),
            // ─── Bottom Grid: Recent Orders + Top Vendors/Products
            LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _RecentOrdersSection()),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: _TopListsSection()),
                  ],
                );
              }
              return Column(
                children: [
                  _RecentOrdersSection(),
                  const SizedBox(height: 24),
                  _TopListsSection(),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final crossCount = constraints.maxWidth > 1100
          ? 4
          : constraints.maxWidth > 700
              ? 3
              : 2;
      return GridView.count(
        crossAxisCount: crossCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          AdminStatCard(
            icon: Icons.currency_rupee_rounded,
            label: 'Total Revenue',
            value: '₹${_fmt(data['total_revenue'])}',
            color: AppColors.success,
            trend: '+${data['new_customers_30d'] ?? 0}',
            trendUp: true,
          ),
          AdminStatCard(
            icon: Icons.shopping_bag_rounded,
            label: 'Total Orders',
            value: '${data['total_orders'] ?? 0}',
            color: AppColors.primary,
          ),
          AdminStatCard(
            icon: Icons.trending_up_rounded,
            label: 'Monthly Revenue',
            value: '₹${_fmt(data['monthly_revenue'])}',
            color: const Color(0xFF9C27B0),
          ),
          AdminStatCard(
            icon: Icons.people_rounded,
            label: 'Total Customers',
            value: '${data['total_customers'] ?? 0}',
            color: AppColors.info,
          ),
          AdminStatCard(
            icon: Icons.store_rounded,
            label: 'Active Vendors',
            value: '${data['active_vendors'] ?? 0}',
            color: AppColors.success,
          ),
          AdminStatCard(
            icon: Icons.pending_actions_rounded,
            label: 'Pending Vendors',
            value: '${data['pending_vendors'] ?? 0}',
            color: AppColors.warning,
          ),
          AdminStatCard(
            icon: Icons.inventory_2_rounded,
            label: 'Total Products',
            value: '${data['total_products'] ?? 0}',
            color: const Color(0xFF00BCD4),
          ),
          AdminStatCard(
            icon: Icons.warning_amber_rounded,
            label: 'Low Stock Items',
            value: '${data['low_stock_count'] ?? 0}',
            color: AppColors.error,
          ),
        ],
      );
    });
  }

  String _fmt(dynamic amount) {
    final num value = amount is num ? amount : 0;
    if (value >= 10000000) return '${(value / 10000000).toStringAsFixed(1)}Cr';
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}

// ════════════════════════════════════════════════════════════════
// Revenue Chart
// ════════════════════════════════════════════════════════════════

class _RevenueChartSection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_RevenueChartSection> createState() =>
      _RevenueChartSectionState();
}

class _RevenueChartSectionState extends ConsumerState<_RevenueChartSection> {
  String _period = 'daily';
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final chartAsync = ref.watch(
        adminRevenueChartProvider((period: _period, days: _days)));

    return AdminCard(
      title: 'Revenue Overview',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ChipButton(
              label: '7D',
              selected: _days == 7,
              onTap: () => setState(() {
                    _days = 7;
                    _period = 'daily';
                  })),
          _ChipButton(
              label: '30D',
              selected: _days == 30 && _period == 'daily',
              onTap: () => setState(() {
                    _days = 30;
                    _period = 'daily';
                  })),
          _ChipButton(
              label: '90D',
              selected: _days == 90,
              onTap: () => setState(() {
                    _days = 90;
                    _period = 'weekly';
                  })),
          _ChipButton(
              label: '1Y',
              selected: _days == 365,
              onTap: () => setState(() {
                    _days = 365;
                    _period = 'monthly';
                  })),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: chartAsync.when(
        loading: () => const SizedBox(
            height: 250,
            child: Center(child: CircularProgressIndicator())),
        error: (e, _) => SizedBox(
            height: 250,
            child: Center(child: Text('Failed to load chart'))),
        data: (chartData) => SizedBox(
          height: 250,
          child: chartData.isEmpty
              ? const Center(
                  child: Text('No revenue data yet',
                      style: TextStyle(color: AppColors.textLight)))
              : _buildChart(chartData),
        ),
      ),
    );
  }

  Widget _buildChart(List<Map<String, dynamic>> data) {
    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['revenue'] as num).toDouble());
    }).toList();

    final commissionSpots = data.asMap().entries.map((e) {
      return FlSpot(
          e.key.toDouble(), (e.value['commission'] as num).toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calcInterval(spots),
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (data.length / 6).ceil().toDouble().clamp(1, 100),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox();
                final period = data[idx]['period'] as String;
                String label;
                try {
                  final dt = DateTime.parse(period);
                  label = DateFormat('MMM d').format(dt);
                } catch (_) {
                  label = period.length > 5 ? period.substring(5, 10) : period;
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(label,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(_shortAmount(value),
                    style:
                        TextStyle(color: Colors.grey.shade500, fontSize: 10));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withAlpha(25),
            ),
          ),
          LineChartBarData(
            spots: commissionSpots,
            isCurved: true,
            color: AppColors.success,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.success.withAlpha(15),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              final color =
                  s.barIndex == 0 ? AppColors.primary : AppColors.success;
              final label = s.barIndex == 0 ? 'Revenue' : 'Commission';
              return LineTooltipItem(
                '$label: ₹${_shortAmount(s.y)}',
                TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  double _calcInterval(List<FlSpot> spots) {
    if (spots.isEmpty) return 1;
    final max = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    if (max <= 0) return 1;
    return (max / 4).ceilToDouble();
  }

  String _shortAmount(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _ChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChipButton(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              )),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Recent Orders Table
// ════════════════════════════════════════════════════════════════

class _RecentOrdersSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminRecentOrdersProvider);
    return AdminCard(
      title: 'Recent Orders',
      trailing: TextButton(
        onPressed: () {},
        child: const Text('View All', style: TextStyle(fontSize: 13)),
      ),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: ordersAsync.when(
        loading: () =>
            const SizedBox(height: 200, child: AdminLoadingState()),
        error: (e, _) => AdminErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(adminRecentOrdersProvider)),
        data: (orders) {
          if (orders.isEmpty) {
            return const AdminEmptyState(
                icon: Icons.shopping_bag_outlined, title: 'No orders yet');
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 44,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 52,
              columnSpacing: 24,
              headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppColors.textSecondary),
              columns: const [
                DataColumn(label: Text('ORDER #')),
                DataColumn(label: Text('CUSTOMER')),
                DataColumn(label: Text('VENDOR')),
                DataColumn(label: Text('AMOUNT')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('DATE')),
              ],
              rows: orders.map((o) {
                String dateStr = '';
                try {
                  final dt = DateTime.parse(o['created_at'] ?? '');
                  dateStr = DateFormat('MMM d, h:mm a').format(dt);
                } catch (_) {
                  dateStr = o['created_at']?.toString().substring(0, 10) ?? '';
                }
                return DataRow(cells: [
                  DataCell(Text(o['order_number'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13))),
                  DataCell(Text(o['customer_name'] ?? 'N/A',
                      style: const TextStyle(fontSize: 13))),
                  DataCell(Text(o['vendor_name'] ?? 'N/A',
                      style: const TextStyle(fontSize: 13))),
                  DataCell(Text('₹${o['total_amount'] ?? 0}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13))),
                  DataCell(AdminStatusBadge(status: o['status'] ?? '')),
                  DataCell(Text(dateStr,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textLight))),
                ]);
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Top Vendors + Top Products
// ════════════════════════════════════════════════════════════════

class _TopListsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Top Vendors
        AdminCard(
          title: 'Top Vendors',
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: ref.watch(adminTopVendorsProvider).when(
                loading: () => const SizedBox(
                    height: 150, child: AdminLoadingState()),
                error: (e, _) => Text('Error: $e'),
                data: (vendors) {
                  if (vendors.isEmpty) {
                    return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No vendor data yet'));
                  }
                  return Column(
                    children: vendors.asMap().entries.map((e) {
                      final v = e.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text('${e.key + 1}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: AppColors.primary)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(v['store_name'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  Text(
                                      '${v['total_orders'] ?? 0} orders',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textLight)),
                                ],
                              ),
                            ),
                            Text('₹${_shortAmount(v['total_revenue'] ?? 0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppColors.success)),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
        ),
        const SizedBox(height: 16),
        // Top Products
        AdminCard(
          title: 'Top Products',
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: ref.watch(adminTopProductsProvider).when(
                loading: () => const SizedBox(
                    height: 150, child: AdminLoadingState()),
                error: (e, _) => Text('Error: $e'),
                data: (products) {
                  if (products.isEmpty) {
                    return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No product data yet'));
                  }
                  return Column(
                    children: products.asMap().entries.map((e) {
                      final p = e.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFF9C27B0).withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text('${e.key + 1}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: Color(0xFF9C27B0))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p['name'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          size: 12,
                                          color: AppColors.starYellow),
                                      const SizedBox(width: 2),
                                      Text(
                                          '${(p['avg_rating'] ?? 0).toStringAsFixed(1)}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textLight)),
                                      const SizedBox(width: 8),
                                      Text('${p['total_sold'] ?? 0} sold',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textLight)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text('₹${p['price'] ?? 0}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
        ),
      ],
    );
  }

  String _shortAmount(dynamic v) {
    final num value = v is num ? v : 0;
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}
