import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../providers/language_provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_stat_info_card.dart';
import '../account/account_screen.dart';
import 'admin_users_screen.dart';
import 'admin_revenue_screen.dart';
import 'admin_audit_logs_screen.dart';
import 'admin_exercises_screen.dart';
import 'admin_workout_templates_screen.dart';
import 'admin_nutrition_templates_screen.dart';
import 'store_management_screen.dart';
import 'subscription_management_screen.dart';
import '../../../core/theme/app_palette.dart';

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
          _buildPeopleHub(languageProvider),
          _buildFitnessHub(languageProvider),
          _buildBusinessHub(languageProvider),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: context.palette.textDisabled,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: languageProvider.t('admin_tab_dashboard'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people),
            label: isArabic ? 'Users' : 'Users',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.fitness_center),
            label: isArabic ? 'Fitness' : 'Fitness',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.business_center),
            label: isArabic ? 'Business' : 'Business',
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
                          style: TextStyle(
                            fontSize: 14,
                            color: context.palette.textSecondary,
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
                            MaterialPageRoute(
                                builder: (_) => const AccountScreen()),
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
                          _pushAdminScreen(
                            const AdminUsersScreen(initialRole: 'customers'),
                          );
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
                          _pushAdminScreen(
                            const AdminUsersScreen(initialRole: 'customers'),
                          );
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
                          _pushAdminScreen(
                            const AdminUsersScreen(initialRole: 'coaches'),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomStatCard(
                        title:
                            languageProvider.t('admin_metric_active_coaches'),
                        value: '${analytics.coaches.active}',
                        icon: Icons.fitness_center,
                        color: AppColors.accent,
                        onTap: () {
                          _pushAdminScreen(
                            const AdminUsersScreen(initialRole: 'coaches'),
                          );
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
                        value:
                            '\$${analytics.revenue.last30Days.toStringAsFixed(0)}',
                        icon: Icons.attach_money,
                        color: AppColors.success,
                        onTap: () {
                          _pushAdminScreen(const AdminRevenueScreen());
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _displayTier(sub.subscriptionTier),
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
                                          backgroundColor: AppColors
                                              .textDisabled
                                              .withValues(alpha: 0.2),
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
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.palette.textSecondary,
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
                                style: TextStyle(
                                  fontSize: 14,
                                  color: context.palette.textSecondary,
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
    switch (tier.toLowerCase()) {
      case 'basic':
      case 'freemium':
        return AppColors.primary;
      case 'premium':
        return AppColors.secondary;
      case 'pro':
      case 'smart_premium':
        return AppColors.accent;
      default:
        return context.palette.textSecondary;
    }
  }

  String _displayTier(String tier) {
    switch (tier.toLowerCase()) {
      case 'freemium':
        return 'Free';
      case 'premium':
        return 'Premium';
      case 'smart_premium':
        return 'Smart Premium';
      default:
        return tier
            .replaceAll('_', ' ')
            .split(' ')
            .where((part) => part.isNotEmpty)
            .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' ');
    }
  }

  Widget _buildPeopleHub(LanguageProvider languageProvider) {
    return _buildHubTab(
      title: 'Users',
      subtitle: 'Manage customers, coaches, and admin access points.',
      children: [
        _buildAdminActionTile(
          icon: Icons.person_outline,
          title: 'Customers',
          subtitle: 'View, suspend, assign coaches, and edit subscriptions.',
          color: AppColors.primary,
          onTap: () => _pushAdminScreen(
            const AdminUsersScreen(initialRole: 'customers'),
          ),
        ),
        _buildAdminActionTile(
          icon: Icons.sports,
          title: 'Coaches',
          subtitle: 'Approve, create, suspend, and update coach accounts.',
          color: AppColors.secondary,
          onTap: () => _pushAdminScreen(
            const AdminUsersScreen(initialRole: 'coaches'),
          ),
        ),
        _buildAdminActionTile(
          icon: Icons.admin_panel_settings,
          title: 'Admins',
          subtitle: 'Create admin accounts and manage platform admins.',
          color: AppColors.accent,
          onTap: () => _pushAdminScreen(
            const AdminUsersScreen(initialRole: 'admins'),
          ),
        ),
      ],
    );
  }

  Widget _buildFitnessHub(LanguageProvider languageProvider) {
    return _buildHubTab(
      title: 'Fitness Plans',
      subtitle: 'Manage the content used for user workout and nutrition plans.',
      children: [
        _buildAdminActionTile(
          icon: Icons.fitness_center,
          title: 'Exercise Library',
          subtitle: 'Edit exercises, videos, thumbnails, and instructions.',
          color: AppColors.primary,
          onTap: () => _pushAdminScreen(const AdminExercisesScreen()),
        ),
        _buildAdminActionTile(
          icon: Icons.view_week,
          title: 'Workout Templates',
          subtitle: 'Import JSON or edit workout combinations one by one.',
          color: AppColors.secondary,
          onTap: () => _pushAdminScreen(const AdminWorkoutTemplatesScreen()),
        ),
        _buildAdminActionTile(
          icon: Icons.restaurant_menu,
          title: 'Nutrition Templates',
          subtitle:
              'Import JSON or edit meal templates used in generated plans.',
          color: AppColors.success,
          onTap: () => _pushAdminScreen(const AdminNutritionTemplatesScreen()),
        ),
      ],
    );
  }

  Widget _buildBusinessHub(LanguageProvider languageProvider) {
    return _buildHubTab(
      title: 'Business',
      subtitle: 'Manage subscriptions, revenue, store operations, and logs.',
      children: [
        _buildAdminActionTile(
          icon: Icons.credit_card,
          title: 'Subscription Plans',
          subtitle: 'Edit package names, prices, features, and requests.',
          color: AppColors.primary,
          onTap: () => _pushAdminScreen(const SubscriptionManagementScreen()),
        ),
        _buildAdminActionTile(
          icon: Icons.attach_money,
          title: 'Revenue',
          subtitle: 'Review payment and subscription performance.',
          color: AppColors.success,
          onTap: () => _pushAdminScreen(const AdminRevenueScreen()),
        ),
        _buildAdminActionTile(
          icon: Icons.store,
          title: 'Store',
          subtitle: 'Manage store products and order operations.',
          color: AppColors.secondary,
          onTap: () => _pushAdminScreen(const StoreManagementScreen()),
        ),
        _buildAdminActionTile(
          icon: Icons.history,
          title: 'Audit Logs',
          subtitle: 'Review important admin and platform activity.',
          color: AppColors.warning,
          onTap: () => _pushAdminScreen(const AdminAuditLogsScreen()),
        ),
      ],
    );
  }

  Widget _buildHubTab({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.account_circle),
                onPressed: () => _pushAdminScreen(const AccountScreen()),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildAdminActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: context.palette.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.palette.textDisabled),
        ],
      ),
    );
  }

  void _pushAdminScreen(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
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
        style: TextStyle(
          fontSize: 12,
          color: context.palette.textDisabled,
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
