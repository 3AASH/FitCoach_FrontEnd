import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/error_message.dart';
import '../../providers/language_provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/error_banner.dart';
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
    final lang = context.watch<LanguageProvider>();
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardTab(lang),
          _buildPeopleHub(lang),
          _buildFitnessHub(lang),
          _buildBusinessHub(lang),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: context.palette.surface.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: context.palette.border.withValues(alpha: 0.8),
                ),
                boxShadow: Theme.of(context).brightness == Brightness.dark
                    ? null
                    : [
                        BoxShadow(
                          color:
                              context.palette.primary.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  _buildNavItem(
                      Icons.dashboard, lang.t('admin_tab_dashboard'), 0),
                  _buildNavItem(
                      Icons.people, lang.t('admin_dashboard_users'), 1),
                  _buildNavItem(Icons.fitness_center,
                      lang.t('admin_dashboard_fitness'), 2),
                  _buildNavItem(Icons.business_center,
                      lang.t('admin_dashboard_business'), 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final color =
        isSelected ? context.palette.primary : context.palette.textSecondary;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: () => setState(() => _selectedIndex = index),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.palette.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Icon(icon, size: 20, color: color),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.captionMedium.copyWith(
                      color: color,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardTab(LanguageProvider lang) {
    final adminProvider = context.watch<AdminProvider>();
    final analytics = adminProvider.analytics;
    final isLoading = adminProvider.isLoading;
    // AdminProvider has always tracked `_error`, but this screen only read
    // `analytics` and `isLoading`. A failed load therefore stopped the spinner,
    // left analytics null, and silently rendered nothing -- an admin saw an
    // empty dashboard and no reason why.
    final loadFailed = !isLoading && analytics == null;

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
                          lang.t('admin_dashboard_title'),
                          style: AppTextStyles.h1
                              .copyWith(color: context.palette.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lang.t('admin_dashboard_subtitle'),
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
                        tooltip: lang.t('account'),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const AccountScreen()),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: lang.t('refresh'),
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
              else if (loadFailed)
                ErrorStateView(
                  message: friendlyError(lang, adminProvider.error),
                  onRetry: _loadDashboardData,
                )
              else if (analytics != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: CustomStatCard(
                        title: lang.t('admin_metric_total_users'),
                        value: '${analytics.users.total}',
                        icon: Icons.people,
                        color: context.palette.primary,
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
                        title: lang.t('admin_metric_active_users'),
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
                        title: lang.t('admin_metric_total_coaches'),
                        value: '${analytics.coaches.total}',
                        icon: Icons.sports,
                        color: AppColors.cyan,
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
                        title: lang.t('admin_metric_active_coaches'),
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
                        title: lang.t('admin_metric_revenue_30d'),
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
                        title: lang.t('admin_metric_new_users_7d'),
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
                  lang.t('admin_subscription_distribution'),
                  style: AppTextStyles.h3
                      .copyWith(color: context.palette.textPrimary),
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
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.pill),
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
                                      style: AppTextStyles.h3.copyWith(
                                          color: context.palette.textPrimary),
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
                            color:
                                context.palette.primary.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppRadius.medium),
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            color: context.palette.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.t('admin_sessions_today'),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: context.palette.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${analytics.sessions.today}',
                                style: AppTextStyles.h2.copyWith(
                                    color: context.palette.textPrimary),
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
        return context.palette.primary;
      case 'premium':
        return context.palette.info;
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

  Widget _buildPeopleHub(LanguageProvider lang) {
    return _buildHubTab(
      title: lang.t('admin_hub_people'),
      subtitle: lang.t('admin_hub_people_desc'),
      children: [
        _buildAdminActionTile(
          icon: Icons.person_outline,
          title: lang.t('admin_hub_customers'),
          subtitle: lang.t('admin_hub_customers_desc'),
          color: context.palette.primary,
          onTap: () => _pushAdminScreen(
            const AdminUsersScreen(initialRole: 'customers'),
          ),
        ),
        _buildAdminActionTile(
          icon: Icons.sports,
          title: lang.t('admin_hub_coaches'),
          subtitle: lang.t('admin_hub_coaches_desc'),
          color: AppColors.cyan,
          onTap: () => _pushAdminScreen(
            const AdminUsersScreen(initialRole: 'coaches'),
          ),
        ),
        _buildAdminActionTile(
          icon: Icons.admin_panel_settings,
          title: lang.t('admin_hub_admins'),
          subtitle: lang.t('admin_hub_admins_desc'),
          color: AppColors.accent,
          onTap: () => _pushAdminScreen(
            const AdminUsersScreen(initialRole: 'admins'),
          ),
        ),
      ],
    );
  }

  Widget _buildFitnessHub(LanguageProvider lang) {
    return _buildHubTab(
      title: lang.t('admin_hub_fitness'),
      subtitle: lang.t('admin_hub_fitness_desc'),
      children: [
        _buildAdminActionTile(
          icon: Icons.fitness_center,
          title: lang.t('admin_hub_exercise_library'),
          subtitle: lang.t('admin_hub_exercise_library_desc'),
          color: context.palette.primary,
          onTap: () => _pushAdminScreen(const AdminExercisesScreen()),
        ),
        _buildAdminActionTile(
          icon: Icons.view_week,
          title: lang.t('admin_hub_workout_templates'),
          subtitle: lang.t('admin_hub_workout_templates_desc'),
          color: AppColors.cyan,
          onTap: () => _pushAdminScreen(const AdminWorkoutTemplatesScreen()),
        ),
        _buildAdminActionTile(
          icon: Icons.restaurant_menu,
          title: lang.t('admin_hub_nutrition_templates'),
          subtitle: lang.t('admin_hub_nutrition_templates_desc'),
          color: AppColors.success,
          onTap: () => _pushAdminScreen(const AdminNutritionTemplatesScreen()),
        ),
      ],
    );
  }

  Widget _buildBusinessHub(LanguageProvider lang) {
    return _buildHubTab(
      title: lang.t('admin_hub_business'),
      subtitle: lang.t('admin_hub_business_desc'),
      children: [
        _buildAdminActionTile(
          icon: Icons.credit_card,
          title: lang.t('admin_hub_subscription_plans'),
          subtitle: lang.t('admin_hub_subscription_plans_desc'),
          color: context.palette.primary,
          onTap: () => _pushAdminScreen(const SubscriptionManagementScreen()),
        ),
        _buildAdminActionTile(
          icon: Icons.attach_money,
          title: lang.t('admin_hub_revenue'),
          subtitle: lang.t('admin_hub_revenue_desc'),
          color: AppColors.success,
          onTap: () => _pushAdminScreen(const AdminRevenueScreen()),
        ),
        _buildAdminActionTile(
          icon: Icons.store,
          title: lang.t('admin_hub_store'),
          subtitle: lang.t('admin_hub_store_desc'),
          color: AppColors.cyan,
          onTap: () => _pushAdminScreen(const StoreManagementScreen()),
        ),
        _buildAdminActionTile(
          icon: Icons.history,
          title: lang.t('admin_hub_audit_logs'),
          subtitle: lang.t('admin_hub_audit_logs_desc'),
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
                      style: AppTextStyles.h1
                          .copyWith(color: context.palette.textPrimary),
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
                tooltip: context.watch<LanguageProvider>().t('account'),
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
              borderRadius: BorderRadius.circular(AppRadius.medium),
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
                  style: AppTextStyles.h4
                      .copyWith(color: context.palette.textPrimary),
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
