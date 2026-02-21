import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/demo_config.dart';
import '../../../core/constants/colors.dart';
import '../../../data/repositories/user_repository.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_stat_info_card.dart';
import '../subscription/subscription_upgrade_screen.dart';
import '../progress/progress_screen.dart';
import '../inbody/inbody_input_screen.dart';
import '../profile/profile_edit_screen.dart';
import '../settings/notification_settings_screen.dart';
import 'payment_management_screen.dart';

class AccountScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const AccountScreen({super.key, this.onBack});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _activeTab = 'profile';
  bool _workoutReminders = true;
  bool _coachMessages = true;
  bool _nutritionTracking = false;
  bool _promotions = true;
  bool _coachNewAssignments = true;
  bool _coachSessionReminders = true;
  bool _coachPaymentAlerts = true;
  bool _adminSystemAlerts = true;
  bool _adminUserReports = true;
  bool _adminCoachApplications = true;
  bool _adminPaymentIssues = true;
  bool _adminSecurityAlerts = true;

  String _coachBio =
      'Certified fitness coach focused on personalized training and sustainable results.';
  String _coachYearsExperience = '8';
  final List<String> _coachCertifications = [
    'NASM Certified Personal Trainer',
    'Precision Nutrition Level 1',
    'Functional Movement Screen',
  ];
  final List<String> _coachSpecializations = [
    'Strength Training',
    'Nutrition',
    'Weight Loss',
    'Muscle Gain',
  ];

  String _adminRole = 'System Administrator';
  String _adminDepartment = 'Platform Operations';
  final String _adminEmployeeId = 'ADM-001';
  final List<String> _adminPermissions = [
    'User Management',
    'Coach Management',
    'Content Management',
    'System Settings',
    'Analytics',
  ];

  bool get _showUserProfilePendingCards => DemoConfig.isDemo;
  bool get _showHelpCenter => DemoConfig.isDemo;
  bool get _showContactUs => DemoConfig.isDemo;
  bool get _showTerms => DemoConfig.isDemo;
  bool get _showPrivacy => DemoConfig.isDemo;

  bool _roleProfileLoading = false;
  String? _roleProfileError;
  Map<String, dynamic>? _coachProfileData;
  Map<String, dynamic>? _adminProfileData;

  @override
  void initState() {
    super.initState();
    if (!DemoConfig.isDemo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadRoleProfile();
      });
    }
  }

  Future<void> _handleBack() async {
    final didPop = await Navigator.of(context).maybePop();
    if (!didPop) {
      widget.onBack?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isArabic = languageProvider.isArabic;
    final user = authProvider.user;
    final role = (user?.role ?? 'user').toLowerCase();

    final tabOptions = <_AccountTabOption>[
      _AccountTabOption('profile', Icons.person, languageProvider.t('account_tab_profile')),
      if (role == 'user')
        _AccountTabOption('health', Icons.favorite, languageProvider.t('account_tab_health')),
      if (role == 'user')
        _AccountTabOption('subscription', Icons.credit_card, languageProvider.t('account_tab_subscription')),
      _AccountTabOption('notifications', Icons.notifications, languageProvider.t('account_tab_notifications')),
      _AccountTabOption('settings', Icons.settings, languageProvider.t('account_tab_settings')),
    ];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/placeholders/splash_onboarding/workout_onboarding.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  color: AppColors.primary,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _handleBack(),
                            icon: Icon(
                              isArabic ? Icons.arrow_forward : Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  languageProvider.t('account'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  languageProvider.t('account_manage_profile'),
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              child: Text(
                                user?.name.substring(0, 1).toUpperCase() ?? 'U',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.name ?? languageProvider.t('user'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?.email ?? user?.phoneNumber ?? '',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                role == 'coach'
                                    ? languageProvider.t('coach')
                                    : role == 'admin'
                                        ? languageProvider.t('admin')
                                        : user?.subscriptionTier ?? 'Freemium',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTabSelector(tabOptions),
                        const SizedBox(height: 16),
                        if (_activeTab == 'profile')
                          _buildProfileSection(languageProvider, isArabic, role),
                        if (_activeTab == 'health')
                          _buildHealthSection(languageProvider, isArabic),
                        if (_activeTab == 'subscription')
                          _buildSubscriptionSection(languageProvider, isArabic),
                        if (_activeTab == 'notifications')
                          _buildNotificationsSection(languageProvider, isArabic, role),
                        if (_activeTab == 'settings')
                          _buildSettingsSection(context, languageProvider, themeProvider, authProvider, isArabic),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector(List<_AccountTabOption> options) {
    return CustomCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _activeTab,
            isExpanded: true,
            icon: const Icon(Icons.expand_more),
            items: options
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option.id,
                    child: Row(
                      children: [
                        Icon(option.icon, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(option.label),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() => _activeTab = value);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(LanguageProvider languageProvider, bool isArabic, String role) {
    final isCoach = role == 'coach';
    final isAdmin = role == 'admin';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(languageProvider.t('account_section_personal_info')),
        const SizedBox(height: 12),
        CustomInfoCard(
          title: languageProvider.t('account_section_personal_info'),
          subtitle: languageProvider.t('account_personal_info_subtitle'),
          icon: Icons.person,
          iconColor: AppColors.primary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
            );
          },
        ),
        if (!isCoach && !isAdmin) ...[
          if (_showUserProfilePendingCards) ...[
            const SizedBox(height: 12),
            CustomInfoCard(
              title: languageProvider.t('account_fitness_goals'),
              subtitle: languageProvider.t('account_fitness_goals_subtitle'),
              icon: Icons.flag,
              iconColor: AppColors.secondary,
              onTap: () => _showComingSoon(isArabic),
            ),
            const SizedBox(height: 12),
            CustomInfoCard(
              title: languageProvider.t('account_injuries'),
              subtitle: languageProvider.t('account_injuries_subtitle'),
              icon: Icons.healing,
              iconColor: AppColors.warning,
              onTap: () => _showComingSoon(isArabic),
            ),
          ],
        ],
        if (isCoach && DemoConfig.isDemo) ...[
          const SizedBox(height: 24),
          _buildSectionTitle(languageProvider.t('account_coach_profile')),
          const SizedBox(height: 12),
          _buildCoachBioCard(languageProvider),
          const SizedBox(height: 12),
          _buildCoachExperienceCard(languageProvider),
          const SizedBox(height: 12),
          _buildCoachListCard(
            languageProvider.t('account_certifications'),
            _coachCertifications,
            Icons.workspace_premium,
          ),
          const SizedBox(height: 12),
          _buildCoachListCard(
            languageProvider.t('account_specializations'),
            _coachSpecializations,
            Icons.star,
          ),
        ],
        if (isCoach && !DemoConfig.isDemo) ...[
          const SizedBox(height: 24),
          _buildSectionTitle(languageProvider.t('account_coach_profile')),
          const SizedBox(height: 12),
          _buildRoleProfileStatusCard(),
          if (_coachProfileData != null) ...[
            const SizedBox(height: 12),
            _buildCoachBackendProfileCard(languageProvider),
          ],
        ],
        if (isAdmin && DemoConfig.isDemo) ...[
          const SizedBox(height: 24),
          _buildSectionTitle(languageProvider.t('account_admin_profile')),
          const SizedBox(height: 12),
          _buildAdminInfoCard(languageProvider),
          const SizedBox(height: 12),
          _buildAdminPermissionsCard(languageProvider),
          const SizedBox(height: 12),
          _buildAdminStatsCard(languageProvider, isArabic),
        ],
        if (isAdmin && !DemoConfig.isDemo) ...[
          const SizedBox(height: 24),
          _buildSectionTitle(languageProvider.t('account_admin_profile')),
          const SizedBox(height: 12),
          _buildRoleProfileStatusCard(),
          if (_adminProfileData != null) ...[
            const SizedBox(height: 12),
            _buildAdminBackendProfileCard(),
          ],
        ],
      ],
    );
  }

  Widget _buildHealthSection(LanguageProvider languageProvider, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(languageProvider.t('account_section_progress_health')),
        const SizedBox(height: 12),
        CustomInfoCard(
          title: languageProvider.t('account_inbody_measurements'),
          subtitle: languageProvider.t('account_inbody_subtitle'),
          icon: Icons.monitor_weight_outlined,
          iconColor: AppColors.accent,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const InBodyInputScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        CustomInfoCard(
          title: languageProvider.t('account_progress'),
          subtitle: languageProvider.t('account_progress_subtitle'),
          icon: Icons.trending_up,
          iconColor: AppColors.primary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProgressScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSubscriptionSection(LanguageProvider languageProvider, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(languageProvider.t('account_section_subscription')),
        const SizedBox(height: 12),
        CustomInfoCard(
          title: languageProvider.t('account_manage_subscription'),
          subtitle: languageProvider.t('account_manage_subscription_subtitle'),
          icon: Icons.card_membership,
          iconColor: AppColors.primary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SubscriptionUpgradeScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        CustomInfoCard(
          title: languageProvider.t('account_payment_history'),
          subtitle: languageProvider.t('account_payment_history_subtitle'),
          icon: Icons.payment,
          iconColor: AppColors.secondary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaymentManagementScreen()),
            );
          },
        ),
      ],
    );
  }

  Future<void> _loadRoleProfile() async {
    final authProvider = context.read<AuthProvider>();
    final userRepository = context.read<UserRepository>();
    final role = (authProvider.user?.role ?? '').toLowerCase();
    if (role != 'coach' && role != 'admin') return;

    setState(() {
      _roleProfileLoading = true;
      _roleProfileError = null;
    });

    try {
      if (role == 'coach') {
        final coach = await userRepository.getCoachProfileSettings();
        if (!mounted) return;
        setState(() {
          _coachProfileData = coach;
        });
      } else if (role == 'admin') {
        final admin = await userRepository.getAdminProfileSettings();
        if (!mounted) return;
        setState(() {
          _adminProfileData = admin;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _roleProfileError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _roleProfileLoading = false;
        });
      }
    }
  }

  Widget _buildNotificationsSection(
    LanguageProvider languageProvider,
    bool isArabic,
    String role,
  ) {
    final isCoach = role == 'coach';
    final isAdmin = role == 'admin';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(languageProvider.t('account_section_notifications')),
        const SizedBox(height: 12),
        CustomCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              if (!isCoach && !isAdmin) ...[
                SwitchListTile(
                  secondary: const Icon(Icons.fitness_center, color: AppColors.primary),
                  title: Text(languageProvider.t('account_notification_workout_reminders')),
                  value: _workoutReminders,
                  onChanged: (value) => setState(() => _workoutReminders = value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.chat_bubble_outline, color: AppColors.accent),
                  title: Text(languageProvider.t('account_notification_coach_messages')),
                  value: _coachMessages,
                  onChanged: (value) => setState(() => _coachMessages = value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.restaurant_menu, color: AppColors.success),
                  title: Text(languageProvider.t('account_notification_nutrition_tracking')),
                  value: _nutritionTracking,
                  onChanged: (value) => setState(() => _nutritionTracking = value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.local_offer, color: AppColors.warning),
                  title: Text(languageProvider.t('account_notification_promotions')),
                  value: _promotions,
                  onChanged: (value) => setState(() => _promotions = value),
                ),
              ],
              if (isCoach) ...[
                SwitchListTile(
                  secondary: const Icon(Icons.group_add, color: AppColors.primary),
                  title: Text(languageProvider.t('account_notification_new_assignments')),
                  value: _coachNewAssignments,
                  onChanged: (value) => setState(() => _coachNewAssignments = value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.chat, color: AppColors.accent),
                  title: Text(languageProvider.t('account_notification_client_messages')),
                  value: _coachMessages,
                  onChanged: (value) => setState(() => _coachMessages = value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.calendar_month, color: AppColors.secondary),
                  title: Text(languageProvider.t('account_notification_session_reminders')),
                  value: _coachSessionReminders,
                  onChanged: (value) => setState(() => _coachSessionReminders = value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.payments, color: AppColors.success),
                  title: Text(languageProvider.t('account_notification_payment_alerts')),
                  value: _coachPaymentAlerts,
                  onChanged: (value) => setState(() => _coachPaymentAlerts = value),
                ),
              ],
              if (isAdmin) ...[
                SwitchListTile(
                  secondary: const Icon(Icons.warning_amber, color: AppColors.warning),
                  title: Text(languageProvider.t('account_notification_system_alerts')),
                  value: _adminSystemAlerts,
                  onChanged: (value) => setState(() => _adminSystemAlerts = value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.report, color: AppColors.accent),
                  title: Text(languageProvider.t('account_notification_user_reports')),
                  value: _adminUserReports,
                  onChanged: (value) => setState(() => _adminUserReports = value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.verified_user, color: AppColors.primary),
                  title: Text(languageProvider.t('account_notification_coach_applications')),
                  value: _adminCoachApplications,
                  onChanged: (value) => setState(() => _adminCoachApplications = value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.payment, color: AppColors.secondary),
                  title: Text(languageProvider.t('account_notification_payment_issues')),
                  value: _adminPaymentIssues,
                  onChanged: (value) => setState(() => _adminPaymentIssues = value),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.security, color: AppColors.error),
                  title: Text(languageProvider.t('account_notification_security_alerts')),
                  value: _adminSecurityAlerts,
                  onChanged: (value) => setState(() => _adminSecurityAlerts = value),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    LanguageProvider languageProvider,
    ThemeProvider themeProvider,
    AuthProvider authProvider,
    bool isArabic,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(languageProvider.t('account_section_settings')),
        const SizedBox(height: 12),
        CustomCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.language, color: AppColors.primary),
                title: Text(languageProvider.t('account_language')),
                subtitle: Text(isArabic ? languageProvider.t('arabic') : languageProvider.t('english')),
                trailing: Icon(isArabic ? Icons.chevron_left : Icons.chevron_right),
                onTap: () => _showLanguageDialog(context, languageProvider, isArabic),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode, color: AppColors.accent),
                title: Text(languageProvider.t('account_dark_mode')),
                subtitle: Text(
                  languageProvider.t('account_dark_mode_subtitle'),
                ),
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications, color: AppColors.warning),
                title: Text(languageProvider.t('account_notification_settings')),
                subtitle: Text(languageProvider.t('account_notification_settings_subtitle')),
                trailing: Icon(isArabic ? Icons.chevron_left : Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
        if (_showHelpCenter) ...[
          const SizedBox(height: 16),
          CustomInfoCard(
            title: languageProvider.t('account_help_center'),
            subtitle: languageProvider.t('account_help_center_subtitle'),
            icon: Icons.help_outline,
            iconColor: AppColors.primary,
            onTap: () => _showComingSoon(isArabic),
          ),
        ],
        if (_showContactUs) ...[
          const SizedBox(height: 12),
          CustomInfoCard(
            title: languageProvider.t('account_contact_us'),
            subtitle: languageProvider.t('account_contact_us_subtitle'),
            icon: Icons.email,
            iconColor: AppColors.secondary,
            onTap: () => _showComingSoon(isArabic),
          ),
        ],
        const SizedBox(height: 12),
        CustomInfoCard(
          title: languageProvider.t('account_about'),
          subtitle: 'FitCoach+ v2.0.0',
          icon: Icons.info_outline,
          iconColor: AppColors.accent,
          onTap: () {
            _showAboutDialog(context, isArabic);
          },
        ),
        if (_showTerms) ...[
          const SizedBox(height: 12),
          CustomInfoCard(
            title: languageProvider.t('account_terms'),
            icon: Icons.article,
            iconColor: AppColors.textSecondary,
            onTap: () => _showComingSoon(isArabic),
          ),
        ],
        if (_showPrivacy) ...[
          const SizedBox(height: 12),
          CustomInfoCard(
            title: languageProvider.t('account_privacy'),
            icon: Icons.privacy_tip,
            iconColor: AppColors.textSecondary,
            onTap: () => _showComingSoon(isArabic),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _logout(context, authProvider, isArabic),
            icon: const Icon(Icons.logout, color: AppColors.error),
            label: Text(
              languageProvider.t('account_logout'),
              style: const TextStyle(color: AppColors.error),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleProfileStatusCard() {
    if (_roleProfileLoading) {
      return const CustomCard(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_roleProfileError != null) {
      return CustomCard(
        child: Text(
          _roleProfileError!,
          style: const TextStyle(color: AppColors.error),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCoachBackendProfileCard(LanguageProvider languageProvider) {
    final coach = _coachProfileData ?? const <String, dynamic>{};
    final specializations =
        (coach['specializations'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[];
    final certifications =
        (coach['certifications'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[];
    final experience = coach['years_of_experience']?.toString() ??
        coach['experience_years']?.toString() ??
        '-';

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            coach['full_name']?.toString() ?? languageProvider.t('coach'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            coach['bio']?.toString() ?? '-',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '${languageProvider.t('account_experience')}: $experience',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (specializations.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${languageProvider.t('account_specializations')}: ${specializations.join(', ')}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
          if (certifications.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${languageProvider.t('account_certifications')}: ${certifications.join(', ')}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdminBackendProfileCard() {
    final admin = _adminProfileData ?? const <String, dynamic>{};
    final permissions =
        (admin['permissions'] as List?)?.map((e) => e.toString()).join(', ') ?? '-';

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            admin['full_name']?.toString() ?? 'Admin',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            admin['email']?.toString() ?? '-',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Role: ${admin['role']?.toString() ?? '-'}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Permissions: $permissions',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachBioCard(LanguageProvider languageProvider) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                languageProvider.t('account_professional_bio'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () => _editCoachBio(languageProvider),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _coachBio,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachExperienceCard(LanguageProvider languageProvider) {
    return CustomCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                languageProvider.t('account_experience'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                '$_coachYearsExperience ${languageProvider.t('account_years')}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: () => _editCoachExperience(languageProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachListCard(String title, List<String> items, IconData icon) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(item, style: const TextStyle(fontSize: 12)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminInfoCard(LanguageProvider languageProvider) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                languageProvider.t('account_admin_info'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () => _editAdminInfo(languageProvider),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            languageProvider.t('account_admin_role'),
            _adminRole,
          ),
          _buildDetailRow(
            languageProvider.t('account_admin_department'),
            _adminDepartment,
          ),
          _buildDetailRow(
            languageProvider.t('account_admin_employee_id'),
            _adminEmployeeId,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminPermissionsCard(LanguageProvider languageProvider) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            languageProvider.t('account_admin_permissions'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          ..._adminPermissions.map(
            (permission) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(child: Text(permission)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminStatsCard(LanguageProvider languageProvider, bool isArabic) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            languageProvider.t('account_admin_stats'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatPill(
                  '1,247',
                  languageProvider.t('account_admin_total_users'),
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatPill(
                  '43',
                  languageProvider.t('account_admin_active_coaches'),
                  AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatPill(
                  '87',
                  languageProvider.t('account_admin_actions_week'),
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatPill(
                  '12',
                  languageProvider.t('account_admin_pending_reviews'),
                  AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _editCoachBio(LanguageProvider languageProvider) {
    final controller = TextEditingController(text: _coachBio);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.t('account_professional_bio')),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(languageProvider.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _coachBio = controller.text);
              Navigator.pop(context);
            },
            child: Text(languageProvider.t('save')),
          ),
        ],
      ),
    );
  }

  void _editCoachExperience(LanguageProvider languageProvider) {
    final controller = TextEditingController(text: _coachYearsExperience);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.t('account_experience')),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(languageProvider.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _coachYearsExperience = controller.text);
              Navigator.pop(context);
            },
            child: Text(languageProvider.t('save')),
          ),
        ],
      ),
    );
  }

  void _editAdminInfo(LanguageProvider languageProvider) {
    final roleController = TextEditingController(text: _adminRole);
    final deptController = TextEditingController(text: _adminDepartment);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.t('account_admin_info')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: roleController,
              decoration: InputDecoration(
                labelText: languageProvider.t('account_admin_role'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: deptController,
              decoration: InputDecoration(
                labelText: languageProvider.t('account_admin_department'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(languageProvider.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _adminRole = roleController.text;
                _adminDepartment = deptController.text;
              });
              Navigator.pop(context);
            },
            child: Text(languageProvider.t('save')),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showComingSoon(bool isArabic) {
    final languageProvider = context.read<LanguageProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(languageProvider.t('account_coming_soon')),
      ),
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    LanguageProvider provider,
    bool isArabic,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(provider.t('account_choose_language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                provider.currentLanguage == 'en'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: Text(provider.t('english')),
              onTap: () {
                provider.setLanguage('en');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                provider.currentLanguage == 'ar'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: Text(provider.t('arabic')),
              onTap: () {
                provider.setLanguage('ar');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context, bool isArabic) {
    final languageProvider = context.read<LanguageProvider>();
    showAboutDialog(
      context: context,
      applicationName: 'FitCoach+',
      applicationVersion: '2.0.0',
      applicationLegalese: languageProvider.t('account_about_legalese'),
      children: [
        const SizedBox(height: 16),
        Text(
          languageProvider.t('account_about_description'),
        ),
      ],
    );
  }

  Future<void> _logout(
    BuildContext context,
    AuthProvider authProvider,
    bool isArabic,
  ) async {
    final languageProvider = context.read<LanguageProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.t('account_logout')),
        content: Text(
          languageProvider.t('account_logout_confirm'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(languageProvider.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              languageProvider.t('account_logout'),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await authProvider.logout();
    }
  }
}

class _AccountTabOption {
  const _AccountTabOption(this.id, this.icon, this.label);

  final String id;
  final IconData icon;
  final String label;
}
