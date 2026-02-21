import '../../widgets/error_banner.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/config/demo_config.dart';
import '../../../data/demo/demo_data.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/coach_provider.dart';
import '../../../data/models/coach_client.dart';
import '../../providers/quota_provider.dart';
import '../../providers/video_call_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/animated_reveal.dart';
import '../../widgets/custom_stat_info_card.dart';
import '../../widgets/quota_indicator.dart';
import '../../../data/models/appointment.dart';
import '../account/account_screen.dart';
import 'coach_clients_screen.dart';
import 'coach_calendar_screen.dart';
import 'workout_plan_builder_screen.dart';
import 'nutrition_plan_builder_screen.dart';
import '../video_call/video_call_screen.dart';
import 'coach_schedule_session_sheet.dart';
import 'coach_client_detail_screen.dart';

enum _UpcomingFilter { all, video }

class CoachDashboardScreen extends StatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  State<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _ClientSpotlightEntry {
  final String id;
  final String name;
  final String? goal;
  final double momentum;
  final bool needsAttention;
  final int activityDaysAgo;

  const _ClientSpotlightEntry({
    required this.id,
    required this.name,
    this.goal,
    required this.momentum,
    required this.needsAttention,
    required this.activityDaysAgo,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class _CoachDashboardScreenState extends State<CoachDashboardScreen> {
  int _selectedIndex = 0;
  String? _joiningAppointmentId;
  _UpcomingFilter _upcomingFilter = _UpcomingFilter.video;

  ({String id, String name})? _resolveDefaultClient(LanguageProvider lang) {
    if (DemoConfig.isDemo) {
      final demoClient = DemoData.coachClients().isNotEmpty
          ? DemoData.coachClients().first
          : null;
      if (demoClient != null) {
        return (id: demoClient.id, name: demoClient.fullName);
      }
      return (id: 'demo-client', name: lang.t('auth_demo_user'));
    }

    final coachProvider = context.read<CoachProvider>();
    if (coachProvider.clients.isNotEmpty) {
      final client = coachProvider.clients.first;
      return (id: client.id, name: client.fullName);
    }
    return null;
  }

  void _openWorkoutPlanBuilder(LanguageProvider lang) {
    final client = _resolveDefaultClient(lang);
    if (client == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.t('coach_clients_load_first'),
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      setState(() => _selectedIndex = 1);
      return;
    }
    Navigator.of(context).push(
      _createSmoothRoute(
        WorkoutPlanBuilderScreen(
          clientId: client.id,
          clientName: client.name,
        ),
      ),
    );
  }

  void _openNutritionPlanBuilder(LanguageProvider lang) {
    final client = _resolveDefaultClient(lang);
    if (client == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.t('coach_clients_load_first'),
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      setState(() => _selectedIndex = 1);
      return;
    }
    Navigator.of(context).push(
      _createSmoothRoute(
        NutritionPlanBuilderScreen(
          clientId: client.id,
          clientName: client.name,
        ),
      ),
    );
  }

  void _openQuickSchedule(LanguageProvider lang) {
    final client = _resolveDefaultClient(lang);
    if (client == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.t('coach_clients_load_first'),
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      setState(() => _selectedIndex = 1);
      return;
    }
    showCoachScheduleSessionSheet(
      context,
      clientId: client.id,
      clientName: client.name,
    );
  }

  void _openClientDetail(String clientId) {
    Navigator.of(context).push(
      _createSmoothRoute(
        CoachClientDetailScreen(clientId: clientId),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalytics();
      _loadQuota();
    });
  }

  void _loadAnalytics() {
    final authProvider = context.read<AuthProvider>();
    final coachProvider = context.read<CoachProvider>();

    if (authProvider.user?.id != null) {
      coachProvider.loadAnalytics(authProvider.user!.id);
      // Also load today's appointments for the schedule
      final now = DateTime.now();
      coachProvider.loadAppointments(
        coachId: authProvider.user!.id,
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 14)),
      );
    }
  }

  void _loadQuota() {
    final authProvider = context.read<AuthProvider>();
    final quotaProvider = context.read<QuotaProvider>();
    if (authProvider.user?.id != null) {
      quotaProvider.loadQuota(authProvider.user!.id);
    }
  }

  Route _createSmoothRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(curved);
        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutQuad,
          reverseCurve: Curves.easeInQuad,
        );
        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isArabic = languageProvider.isArabic;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardTab(languageProvider, authProvider, isArabic),
          const CoachClientsScreen(),
          const CoachCalendarScreen(),
          _buildMessagesTab(languageProvider),
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
            label: languageProvider.t('coach_tab_dashboard'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people),
            label: languageProvider.t('coach_tab_clients'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_month),
            label: languageProvider.t('coach_tab_calendar'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat),
            label: languageProvider.t('coach_tab_messages'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(
    LanguageProvider lang,
    AuthProvider auth,
    bool isArabic,
  ) {
    final coachProvider = context.watch<CoachProvider>();
    final analytics = coachProvider.analytics;
    final isAnalyticsLoading = coachProvider.isAnalyticsLoading;
    final isAppointmentsLoading = coachProvider.isAppointmentsLoading;
    final todayAppointmentCount = coachProvider.appointments.length;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          _loadAnalytics();
          _loadQuota();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error banners
              Builder(
                builder: (context) {
                  final quotaError = context.watch<QuotaProvider>().error;
                  final coachProvider = context.watch<CoachProvider>();
                  final analyticsError = coachProvider.error;
                  return Column(
                    children: [
                      if (quotaError != null && quotaError.isNotEmpty)
                        ErrorBanner(
                          message: quotaError,
                          onRetry: _loadQuota,
                        ),
                      if (analyticsError != null && analyticsError.isNotEmpty)
                        ErrorBanner(
                          message: analyticsError,
                          onRetry: _loadAnalytics,
                        ),
                    ],
                  );
                },
              ),
              // Header
              AnimatedReveal(
                offset: const Offset(-0.12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.t(
                              'coach_greeting',
                              args: {'name': auth.user?.name ?? ''},
                            ),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lang.t('coach_dashboard_title'),
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
                              _createSmoothRoute(const AccountScreen()),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            _loadAnalytics();
                            _loadQuota();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // Quota indicators
              AnimatedReveal(
                delay: const Duration(milliseconds: 120),
                offset: const Offset(0.1, 0.08),
                child: Row(
                  children: [
                    Expanded(child: QuotaIndicator(type: 'message')),
                    const SizedBox(width: 12),
                    Expanded(child: QuotaIndicator(type: 'videoCall')),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick stats
              if (isAnalyticsLoading)
                const Center(child: CircularProgressIndicator())
              else if (analytics != null) ...[
                AnimatedReveal(
                  delay: const Duration(milliseconds: 180),
                  offset: const Offset(-0.1, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomStatCard(
                          title: lang.t('coach_metric_active_clients'),
                          value: '${analytics.activeClients}',
                          icon: Icons.people,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomStatCard(
                          title: lang.t('coach_metric_upcoming'),
                          value: '${analytics.upcomingAppointments}',
                          icon: Icons.video_call,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedReveal(
                  delay: const Duration(milliseconds: 260),
                  offset: const Offset(0.1, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomStatCard(
                          title: lang.t('coach_metric_new_messages'),
                          value: '${analytics.unreadMessages}',
                          icon: Icons.message,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomStatCard(
                          title: lang.t('coach_metric_today_sessions'),
                          value: '$todayAppointmentCount',
                          icon: Icons.today,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              if (coachProvider.clients.isNotEmpty) ...[
                AnimatedReveal(
                  delay: const Duration(milliseconds: 300),
                  offset: const Offset(-0.08, 0.04),
                  child: _buildClientSpotlight(lang, coachProvider.clients),
                ),
                const SizedBox(height: 24),
              ],
              // Today's schedule
              AnimatedReveal(
                delay: const Duration(milliseconds: 320),
                offset: const Offset(0, -0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lang.t('coach_schedule_today'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedIndex = 2; // Calendar tab
                        });
                      },
                      child: Text(lang.t('coach_view_all')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (isAppointmentsLoading)
                const Center(child: CircularProgressIndicator())
              else
                AnimatedReveal(
                  delay: const Duration(milliseconds: 360),
                  offset: const Offset(-0.06, 0.08),
                  child: _buildTodaySchedule(coachProvider, lang, isArabic),
                ),

              const SizedBox(height: 24),

              AnimatedReveal(
                delay: const Duration(milliseconds: 420),
                offset: const Offset(0, 0.12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          lang.t('coach_upcoming_sessions'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedIndex = 2;
                            });
                          },
                          child: Text(lang.t('coach_view_all')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildUpcomingFilterChips(lang),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (coachProvider.appointments.isEmpty && isAppointmentsLoading)
                const Center(child: CircularProgressIndicator())
              else
                AnimatedReveal(
                  delay: const Duration(milliseconds: 470),
                  offset: const Offset(0.08, 0),
                  child: _buildUpcomingSessions(coachProvider, lang, isArabic),
                ),

              const SizedBox(height: 24),

              // Quick actions
              AnimatedReveal(
                delay: const Duration(milliseconds: 520),
                offset: const Offset(-0.08, 0),
                child: Text(
                  lang.t('coach_quick_actions'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              AnimatedReveal(
                delay: const Duration(milliseconds: 560),
                offset: const Offset(0, 0.12),
                child: CustomInfoCard(
                  title: lang.t('coach_quick_action_message_clients_title'),
                  subtitle: lang.t('coach_quick_action_message_clients_subtitle'),
                  icon: Icons.chat_bubble_outline,
                  iconColor: AppColors.accent,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
              ),

              const SizedBox(height: 12),

              AnimatedReveal(
                delay: const Duration(milliseconds: 600),
                offset: const Offset(-0.05, 0.12),
                child: CustomInfoCard(
                  title: lang.t('coach_quick_action_quick_schedule_title'),
                  subtitle: lang.t('coach_quick_action_quick_schedule_subtitle'),
                  icon: Icons.video_call,
                  iconColor: AppColors.secondary,
                  onTap: () => _openQuickSchedule(lang),
                ),
              ),

              const SizedBox(height: 12),

              AnimatedReveal(
                delay: const Duration(milliseconds: 640),
                offset: const Offset(0, 0.12),
                child: CustomInfoCard(
                  title: lang.t('coach_action_workout_plan'),
                  subtitle: lang.t('coach_action_workout_plan_desc'),
                  icon: Icons.fitness_center,
                  iconColor: AppColors.primary,
                  onTap: () {
                    _openWorkoutPlanBuilder(lang);
                  },
                ),
              ),

              const SizedBox(height: 12),

              AnimatedReveal(
                delay: const Duration(milliseconds: 680),
                offset: const Offset(-0.05, 0.12),
                child: CustomInfoCard(
                  title: lang.t('coach_action_nutrition_plan'),
                  subtitle: lang.t('coach_action_nutrition_plan_desc'),
                  icon: Icons.restaurant,
                  iconColor: AppColors.success,
                  onTap: () {
                    _openNutritionPlanBuilder(lang);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingFilterChips(LanguageProvider lang) {
    final videoLabel = lang.t('coach_upcoming_video_calls');
    final allLabel = lang.t('coach_upcoming_all_sessions');
    return Row(
      children: [
        _buildFilterPill(
          label: videoLabel,
          icon: Icons.videocam_outlined,
          selected: _upcomingFilter == _UpcomingFilter.video,
          onTap: () {
            if (_upcomingFilter != _UpcomingFilter.video) {
              setState(() => _upcomingFilter = _UpcomingFilter.video);
            }
          },
        ),
        const SizedBox(width: 12),
        _buildFilterPill(
          label: allLabel,
          icon: Icons.event_available_outlined,
          selected: _upcomingFilter == _UpcomingFilter.all,
          onTap: () {
            if (_upcomingFilter != _UpcomingFilter.all) {
              setState(() => _upcomingFilter = _UpcomingFilter.all);
            }
          },
        ),
      ],
    );
  }

  Widget _buildClientSpotlight(
    LanguageProvider lang,
    List<CoachClient> clients,
  ) {
    final spotlightEntries = _rankClientSpotlight(clients);
    if (spotlightEntries.isEmpty) {
      return const SizedBox.shrink();
    }
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang.t('coach_client_spotlight'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedIndex = 1),
                  child: Text(lang.t('coach_view_all')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...spotlightEntries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openClientDetail(entry.id),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              child: Text(
                                entry.initials,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${entry.goal ?? lang.t('coach_goal_fallback')} • ${_formatActivityAgo(entry.activityDaysAgo, lang)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: entry.needsAttention
                                    ? AppColors.error.withValues(alpha: 0.12)
                                    : AppColors.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                entry.needsAttention ? lang.t('coach_needs_checkin') : lang.t('coach_on_track'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: entry.needsAttention
                                      ? AppColors.error
                                      : AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: entry.momentum.clamp(0, 1),
                          minHeight: 6,
                          color: entry.needsAttention
                              ? AppColors.warning
                              : AppColors.primary,
                          backgroundColor: AppColors.surface,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lang.t('coach_plan_health', args: {'percent': '${(entry.momentum * 100).round()}'}),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_ClientSpotlightEntry> _rankClientSpotlight(
    List<CoachClient> clients,
  ) {
    final now = DateTime.now();
    final entries = clients.map((client) {
      final fitness = (client.fitnessScore ?? 55) / 100;
      final lastTouch = client.lastActivity ??
          client.assignedDate ??
          now.subtract(const Duration(days: 14));
      final inactivityDays = now.difference(lastTouch).inDays;
      final activityScore = (1 - (inactivityDays / 14)).clamp(0.0, 1.0);
      final needsAttention =
          inactivityDays > 5 || (client.fitnessScore ?? 0) < 55;
      final composite = (fitness * 0.6) + (activityScore * 0.4);
      return _ClientSpotlightEntry(
        id: client.id,
        name: client.fullName,
        goal: client.goal,
        momentum: composite,
        needsAttention: needsAttention,
        activityDaysAgo: inactivityDays,
      );
    }).toList();

    entries.sort((a, b) {
      if (a.needsAttention != b.needsAttention) {
        return b.needsAttention ? 1 : -1;
      }
      return b.momentum.compareTo(a.momentum);
    });

    return entries.take(3).toList();
  }

  String _formatActivityAgo(int days, LanguageProvider lang) {
    if (days <= 0) return lang.t('coach_active_today');
    if (days == 1) return lang.t('coach_active_yesterday');
    return lang.t('coach_active_days_ago', args: {'days': '$days'});
  }

  Widget _buildFilterPill({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final Color activeColor =
        selected ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.textDisabled.withValues(alpha: 0.5),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: activeColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: activeColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionItem({
    required Appointment appointment,
    required LanguageProvider lang,
    required bool isArabic,
    bool showDate = false,
    bool canJoin = false,
    bool isJoining = false,
    VoidCallback? onJoin,
  }) {
    final scheduledDate = _parseAppointmentDate(appointment);
    final clientName =
        appointment.userName ?? appointment.coachName ?? lang.t('coach');
    final timeLabel =
        scheduledDate != null ? _formatTimeLabel(scheduledDate) : '--:--';
    final dateLabel = (showDate && scheduledDate != null)
        ? '${_formatDateLabel(scheduledDate, isArabic)} • '
        : '';
    final typeDisplay = _getTypeDisplayName(appointment.type, lang);
    final subtitleText = '$dateLabel$timeLabel • $typeDisplay';
    final showJoinButton = onJoin != null;
    final readyHint = lang.t('coach_ready_to_join_now');
    final joinHint = lang.t('coach_join_hint');

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person,
          color: AppColors.primary,
        ),
      ),
      title: Text(clientName),
      subtitle: Text(subtitleText),
      trailing: showJoinButton
          ? Tooltip(
              message: canJoin ? readyHint : joinHint,
              child: ElevatedButton(
                onPressed: (canJoin && !isJoining) ? onJoin : null,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: isJoining
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(lang.t('coach_join')),
              ),
            )
          : null,
    );
  }

  Widget _buildTodaySchedule(
    CoachProvider coachProvider,
    LanguageProvider lang,
    bool isArabic,
  ) {
    final today = DateTime.now();
    final todayAppointments = coachProvider.appointments.where((appointment) {
      final scheduledDate = _parseAppointmentDate(appointment);
      if (scheduledDate == null) {
        return false;
      }
      return scheduledDate.year == today.year &&
          scheduledDate.month == today.month &&
          scheduledDate.day == today.day;
    }).toList()
      ..sort((a, b) {
        final aDate = _parseAppointmentDate(a);
        final bDate = _parseAppointmentDate(b);
        if (aDate == null || bDate == null) {
          return 0;
        }
        return aDate.compareTo(bDate);
      });

    if (todayAppointments.isEmpty) {
      return CustomCard(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.event_busy,
                  size: 48,
                  color: AppColors.textDisabled,
                ),
                const SizedBox(height: 12),
                Text(
                  lang.t('coach_no_appointments'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return CustomCard(
      child: Column(
        children: todayAppointments.asMap().entries.map((entry) {
          final index = entry.key;
          final appointment = entry.value;
          final supportsVideo = _supportsVideoSession(appointment);
          final canJoin = _canJoinAppointment(appointment);
          final isJoining = _joiningAppointmentId == appointment.id;
          return Column(
            children: [
              _buildSessionItem(
                appointment: appointment,
                lang: lang,
                isArabic: isArabic,
                canJoin: canJoin,
                isJoining: isJoining,
                onJoin:
                    supportsVideo ? () => _handleJoinCall(appointment) : null,
              ),
              if (index < todayAppointments.length - 1) const Divider(),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUpcomingSessions(
    CoachProvider coachProvider,
    LanguageProvider lang,
    bool isArabic,
  ) {
    final upcomingAppointments =
        _getUpcomingAppointments(coachProvider.appointments);

    if (upcomingAppointments.isEmpty) {
      return CustomCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              lang.t('coach_no_upcoming_sessions'),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    final filter = _upcomingFilter;
    final filteredAppointments = filter == _UpcomingFilter.video
        ? upcomingAppointments.where(_supportsVideoSession).toList()
        : upcomingAppointments;

    if (filteredAppointments.isEmpty) {
      final emptyMessage = filter == _UpcomingFilter.video
          ? (lang.t('coach_no_upcoming_video_calls'))
          : lang.t('coach_no_upcoming_sessions');
      return CustomCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    final visibleAppointments = filteredAppointments.take(5).toList();

    return CustomCard(
      child: Column(
        children: visibleAppointments.asMap().entries.map((entry) {
          final index = entry.key;
          final appointment = entry.value;
          final supportsVideo = _supportsVideoSession(appointment);
          final canJoin = _canJoinAppointment(appointment);
          final isJoining = _joiningAppointmentId == appointment.id;
          return Column(
            children: [
              _buildSessionItem(
                appointment: appointment,
                lang: lang,
                isArabic: isArabic,
                showDate: true,
                canJoin: canJoin,
                isJoining: isJoining,
                onJoin:
                    supportsVideo ? () => _handleJoinCall(appointment) : null,
              ),
              if (index < visibleAppointments.length - 1) const Divider(),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _getTypeDisplayName(String? type, LanguageProvider lang) {
    switch (type) {
      case 'video':
        return lang.t('video_call');
      case 'chat':
        return lang.t('chat');
      case 'assessment':
        return lang.t('assessment');
      default:
        return lang.t('unknown');
    }
  }

  List<Appointment> _getUpcomingAppointments(List<Appointment> appointments) {
    final now = DateTime.now();
    final todayKey = DateTime(now.year, now.month, now.day);

    final upcoming = appointments.where((appointment) {
      final scheduledDate = _parseAppointmentDate(appointment);
      if (scheduledDate == null) {
        return false;
      }
      final appointmentDay = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
      );
      return appointmentDay.isAfter(todayKey);
    }).toList()
      ..sort((a, b) {
        final aDate = _parseAppointmentDate(a);
        final bDate = _parseAppointmentDate(b);
        if (aDate == null || bDate == null) {
          return 0;
        }
        return aDate.compareTo(bDate);
      });

    return upcoming;
  }

  Future<void> _handleJoinCall(Appointment appointment) async {
    setState(() {
      _joiningAppointmentId = appointment.id;
    });

    final videoCallProvider = context.read<VideoCallProvider>();
    final languageProvider = context.read<LanguageProvider>();
    final authProvider = context.read<AuthProvider>();

    try {
      final result = await videoCallProvider.canJoinCall(appointment.id);
      if (result == null || result['canJoin'] != true) {
        final reason =
            result?['reason'] ?? languageProvider.t('cannot_join_call');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(reason)),
          );
        }
        return;
      }

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        _createSmoothRoute(
          VideoCallScreen(
            appointmentId: appointment.id,
            coachId: authProvider.user?.id ?? appointment.coachId,
            coachName: appointment.userName ?? languageProvider.t('coach'),
            isCoach: true,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(languageProvider.t('error'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _joiningAppointmentId = null;
        });
      }
    }
  }

  DateTime? _parseAppointmentDate(Appointment appointment) {
    try {
      return DateTime.parse(appointment.scheduledAt);
    } catch (_) {
      return null;
    }
  }

  String _formatTimeLabel(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  String _formatDateLabel(DateTime date, bool isArabic) {
    final locale = isArabic ? 'ar' : 'en';
    return DateFormat('EEE, MMM d', locale).format(date);
  }

  bool _supportsVideoSession(Appointment appointment) {
    final type = (appointment.type ?? 'video').toLowerCase();
    return type == 'video';
  }

  bool _canJoinAppointment(Appointment appointment) {
    if (!_supportsVideoSession(appointment)) {
      return false;
    }

    final status = appointment.status.toLowerCase();
    final allowedStatuses = {
      'confirmed',
      'scheduled',
      'in_progress',
    };
    if (!allowedStatuses.contains(status)) {
      return false;
    }

    final scheduledDate = _parseAppointmentDate(appointment);
    if (scheduledDate == null) {
      return false;
    }

    final now = DateTime.now();
    final joinWindowStart = scheduledDate.subtract(const Duration(minutes: 10));
    final meetingLength = appointment.durationMinutes ?? 45;
    final joinWindowEnd =
        scheduledDate.add(Duration(minutes: meetingLength + 15));

    return now.isAfter(joinWindowStart) && now.isBefore(joinWindowEnd);
  }

  Widget _buildMessagesTab(LanguageProvider lang) {
    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('coach_messages')),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 24),
            Text(
              lang.t('coach_messages_coming_soon'),
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
