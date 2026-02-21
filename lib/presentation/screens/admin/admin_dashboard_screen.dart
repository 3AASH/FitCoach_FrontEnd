import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../providers/language_provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_stat_info_card.dart';
import '../account/account_screen.dart';
import 'admin_users_screen.dart';
import 'admin_coaches_screen.dart';
import 'admin_revenue_screen.dart';
import 'admin_audit_logs_screen.dart';
import 'store_management_screen.dart';
import 'subscription_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  void _loadDashboardData() {
    final adminProvider = context.read<AdminProvider>();
    adminProvider.loadDashboardAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final isArabic = languageProvider.isArabic;
    
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardTab(languageProvider, isArabic),
          const AdminUsersScreen(),
          const AdminCoachesScreen(),
          const AdminRevenueScreen(),
          const SubscriptionManagementScreen(),
          const StoreManagementScreen(),
          const AdminAuditLogsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textDisabled,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: languageProvider.t('admin_tab_dashboard'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people),
            label: languageProvider.t('admin_tab_users'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.sports),
            label: languageProvider.t('admin_tab_coaches'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.attach_money),
            label: languageProvider.t('admin_tab_revenue'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.credit_card),
            label: languageProvider.t('admin_tab_subscriptions'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.store),
            label: languageProvider.t('admin_tab_store'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: languageProvider.t('admin_tab_logs'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDashboardTab(LanguageProvider languageProvider, bool isArabic) {
    final adminProvider = context.watch<AdminProvider>();
    final analytics = adminProvider.analytics;
    final isLoading = adminProvider.isLoading;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => _loadDashboardData(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languageProvider.t('admin_dashboard_title'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          languageProvider.t('admin_dashboard_subtitle'),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.account_circle),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AccountScreen()),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadDashboardData,
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Key metrics
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (analytics != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: CustomStatCard(
                        title: languageProvider.t('admin_metric_total_users'),
                        value: '${analytics.users.total}',
                        icon: Icons.people,
                        color: AppColors.primary,
                        onTap: () {
                          setState(() => _selectedIndex = 1);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomStatCard(
                        title: languageProvider.t('admin_metric_active_users'),
                        value: '${analytics.users.active}',
                        icon: Icons.people_alt,
                        color: AppColors.success,
                        onTap: () {
                          setState(() => _selectedIndex = 1);
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: CustomStatCard(
                        title: languageProvider.t('admin_metric_total_coaches'),
                        value: '${analytics.coaches.total}',
                        icon: Icons.sports,
                        color: AppColors.secondary,
                        onTap: () {
                          setState(() => _selectedIndex = 2);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomStatCard(
                        title: languageProvider.t('admin_metric_active_coaches'),
                        value: '${analytics.coaches.active}',
                        icon: Icons.fitness_center,
                        color: AppColors.accent,
                        onTap: () {
                          setState(() => _selectedIndex = 2);
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: CustomStatCard(
                        title: languageProvider.t('admin_metric_revenue_30d'),
                        value: '\$${analytics.revenue.last30Days.toStringAsFixed(0)}',
                        icon: Icons.attach_money,
                        color: AppColors.success,
                        onTap: () {
                          setState(() => _selectedIndex = 3);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomStatCard(
                        title: languageProvider.t('admin_metric_new_users_7d'),
                        value: '+${analytics.growth.newUsersLast7Days}',
                        icon: Icons.trending_up,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Subscription Distribution
                Text(
                  languageProvider.t('admin_subscription_distribution'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                CustomCard(
                  child: Column(
                    children: analytics.subscriptions.map((sub) {
                      final percentage = analytics.users.total > 0
                          ? (sub.count / analytics.users.total * 100)
                          : 0.0;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getTierColor(sub.subscriptionTier),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sub.subscriptionTier,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: percentage / 100,
                                          backgroundColor: AppColors.textDisabled.withValues(alpha: 0.2),
                                          valueColor: AlwaysStoppedAnimation(
                                            _getTierColor(sub.subscriptionTier),
                                          ),
                                          minHeight: 6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${sub.count}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
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
                          if (analytics.subscriptions.last != sub)
                            const Divider(height: 1),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Sessions Today
                CustomCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calendar_today,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                languageProvider.t('admin_sessions_today'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${analytics.sessions.today}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getTierColor(String tier) {
    switch (tier) {
      case 'Basic':
        return AppColors.primary;
      case 'Premium':
        return AppColors.secondary;
      case 'Pro':
        return AppColors.accent;
      default:
        return AppColors.textSecondary;
    }
  }
  
  // ignore: unused_element
  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(
        time,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textDisabled,
        ),
      ),
    );
  }
  
  // ignore: unused_element
  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
