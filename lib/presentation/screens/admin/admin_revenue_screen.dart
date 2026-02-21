import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/colors.dart';
import '../../providers/language_provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/custom_card.dart';

class AdminRevenueScreen extends StatefulWidget {
  const AdminRevenueScreen({super.key});

  @override
  State<AdminRevenueScreen> createState() => _AdminRevenueScreenState();
}

class _AdminRevenueScreenState extends State<AdminRevenueScreen> {
  String _selectedPeriod = 'month';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRevenue();
    });
  }

  void _loadRevenue() {
    final adminProvider = context.read<AdminProvider>();
    adminProvider.loadRevenueAnalytics(period: _selectedPeriod);
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final adminProvider = context.watch<AdminProvider>();
    final lang = languageProvider;
    final revenue = adminProvider.revenueAnalytics;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('admin_revenue_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRevenue,
          ),
        ],
      ),
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : adminProvider.error != null || revenue == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(
                        adminProvider.error ?? lang.t('admin_load_failed'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRevenue,
                        child: Text(lang.t('retry')),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _loadRevenue(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Total Revenue Card
                        CustomCard(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.attach_money,
                                        color: AppColors.success,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            lang.t('admin_total_revenue'),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '\$${revenue.total.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatItem(
                                      lang.t('admin_transactions'),
                                      '${revenue.transactionCount}',
                                      Icons.receipt_long,
                                      AppColors.primary,
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: AppColors.textDisabled,
                                    ),
                                    _buildStatItem(
                                      lang.t('admin_avg_transaction'),
                                      revenue.transactionCount > 0
                                          ? '\$${(revenue.total / revenue.transactionCount).toStringAsFixed(0)}'
                                          : '\$0',
                                      Icons.trending_up,
                                      AppColors.accent,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Period Selector
                        Text(
                          lang.t('admin_time_period'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        CustomCard(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: SegmentedButton<String>(
                              segments: [
                                ButtonSegment(
                                  value: 'day',
                                  label: Text(lang.t('admin_period_day')),
                                  icon: const Icon(Icons.today, size: 18),
                                ),
                                ButtonSegment(
                                  value: 'week',
                                  label: Text(lang.t('admin_period_week')),
                                  icon: const Icon(Icons.calendar_view_week, size: 18),
                                ),
                                ButtonSegment(
                                  value: 'month',
                                  label: Text(lang.t('admin_period_month')),
                                  icon: const Icon(Icons.calendar_month, size: 18),
                                ),
                              ],
                              selected: {_selectedPeriod},
                              onSelectionChanged: (Set<String> selected) {
                                setState(() {
                                  _selectedPeriod = selected.first;
                                });
                                _loadRevenue();
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Revenue Chart
                        if (revenue.byPeriod.isNotEmpty) ...[
                          Text(
                            lang.t('admin_revenue_by_period'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          CustomCard(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: SizedBox(
                                height: 250,
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                          interval: 1,
                                          getTitlesWidget: (value, meta) {
                                            if (value.toInt() >= revenue.byPeriod.length) {
                                              return const SizedBox();
                                            }
                                            final period = revenue.byPeriod[value.toInt()].period;
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Text(
                                                '${period.month}/${period.day}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 50,
                                          getTitlesWidget: (value, meta) {
                                            return Text(
                                              '\$${value.toInt()}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: AppColors.textSecondary,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border.all(
                                        color: AppColors.textDisabled.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    minX: 0,
                                    maxX: (revenue.byPeriod.length - 1).toDouble(),
                                    minY: 0,
                                    maxY: _getMaxRevenue(revenue.byPeriod) * 1.2,
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: revenue.byPeriod.asMap().entries.map((e) {
                                          return FlSpot(e.key.toDouble(), e.value.revenue);
                                        }).toList(),
                                        isCurved: true,
                                        color: AppColors.success,
                                        barWidth: 3,
                                        isStrokeCapRound: true,
                                        dotData: const FlDotData(show: true),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: AppColors.success.withValues(alpha: 0.1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Revenue by Tier
                        Text(
                          lang.t('admin_revenue_by_tier'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        CustomCard(
                          child: Column(
                            children: revenue.byTier.map((tier) {
                              final percentage = revenue.total > 0
                                  ? (tier.revenue / revenue.total * 100)
                                  : 0.0;
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: _getTierColor(tier.subscriptionTier).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            _getTierIcon(tier.subscriptionTier),
                                            color: _getTierColor(tier.subscriptionTier),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tier.subscriptionTier,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${tier.count} ${lang.t('admin_subscriptions_label')}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                  value: percentage / 100,
                                                  backgroundColor: AppColors.textDisabled.withValues(alpha: 0.2),
                                                  valueColor: AlwaysStoppedAnimation(
                                                    _getTierColor(tier.subscriptionTier),
                                                  ),
                                                  minHeight: 6,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '\$${tier.revenue.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.success,
                                              ),
                                            ),
                                            Text(
                                              '${percentage.toStringAsFixed(1)}%',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (revenue.byTier.last != tier)
                                    const Divider(height: 1),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  double _getMaxRevenue(List<dynamic> periods) {
    if (periods.isEmpty) return 100;
    return periods.map((p) => p.revenue as double).reduce((a, b) => a > b ? a : b);
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'smart premium':
      case 'smart_premium':
        return AppColors.accent;
      case 'premium':
        return AppColors.primary;
      case 'freemium':
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getTierIcon(String tier) {
    switch (tier.toLowerCase()) {
      case 'smart premium':
      case 'smart_premium':
        return Icons.workspace_premium;
      case 'premium':
        return Icons.star;
      case 'freemium':
      default:
        return Icons.account_circle;
    }
  }
}
