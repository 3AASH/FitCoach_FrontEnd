import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/demo_config.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/appointment.dart';
import '../../../data/models/message.dart';
import '../../providers/language_provider.dart';
import '../../providers/messaging_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quota_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/video_call_provider.dart';
import '../../providers/coach_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/animated_reveal.dart';
import '../../widgets/quota_indicator.dart';
import '../booking/appointment_detail_screen.dart';
import '../booking/video_booking_screen.dart';
import '../video_call/video_call_screen.dart';
import 'coach_intro_screen.dart';
import '../coach/public_coach_profile_screen.dart';

class CoachMessagingScreen extends StatefulWidget {
  final int initialTabIndex;

  const CoachMessagingScreen({super.key, this.initialTabIndex = 0});

  @override
  State<CoachMessagingScreen> createState() => _CoachMessagingScreenState();
}

class _CoachMessagingScreenState extends State<CoachMessagingScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _conversationSearchController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  bool _showIntro = false;
  bool _introLoaded = false;
  String? _joiningAppointmentId;
  String _conversationQuery = '';
  String? _pendingConversationId;

  @override
  void initState() {
    super.initState();
    _conversationSearchController.addListener(_handleConversationSearch);
    _loadIntroFlag();
    final provider = context.read<MessagingProvider>();
    final isArabic = context.read<LanguageProvider>().isArabic;
    final role = context.read<AuthProvider>().user?.role ?? 'user';
    final isCoach = role == 'coach';
    provider.loadConversations(
      isArabic: isArabic,
      isCoach: isCoach,
      currentUserId: context.read<AuthProvider>().user?.id,
    );
    provider.connectSocket();
    unawaited(_loadUserAppointments());
    unawaited(_ensureCoachClients());
    unawaited(_refreshUserProfileAndData());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _conversationSearchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadIntroFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final seenIntro = prefs.getBool('coach_intro_seen') ?? false;
    if (mounted) {
      setState(() {
        _showIntro = !seenIntro;
        _introLoaded = true;
      });
    }
  }

  Future<void> _loadUserAppointments({bool refresh = false}) async {
    final authProvider = context.read<AuthProvider>();
    final appointmentProvider = context.read<AppointmentProvider>();
    final userId = authProvider.user?.id;
    if (userId == null || userId.isEmpty) {
      return;
    }
    await appointmentProvider.loadUserAppointments(
        userId: userId, refresh: refresh);
  }

  void _handleConversationSearch() {
    setState(() {
      _conversationQuery = _conversationSearchController.text.trim();
    });
  }

  Future<void> _ensureCoachClients() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user?.role != 'coach') {
      return;
    }
    final coachProvider = context.read<CoachProvider>();
    final coachId = authProvider.user?.id;
    if (coachId == null || coachProvider.clients.isNotEmpty) {
      return;
    }
    await coachProvider.loadClients(coachId: coachId);
  }

  Future<void> _refreshAppointments() async {
    await _loadUserAppointments(refresh: true);
  }

  Future<void> _completeIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('coach_intro_seen', true);
    if (mounted) {
      setState(() {
        _showIntro = false;
      });
    }
  }

  Future<void> _refreshUserProfileAndData() async {
    if (DemoConfig.isDemo) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    await authProvider.refreshUserProfile(notify: false);
    if (!mounted) return;

    final languageProvider = context.read<LanguageProvider>();
    final role = authProvider.user?.role ?? 'user';
    final isCoach = role == 'coach';
    final messagingProvider = context.read<MessagingProvider>();

    await messagingProvider.loadConversations(
      isArabic: languageProvider.isArabic,
      isCoach: isCoach,
      currentUserId: authProvider.user?.id,
    );
    await _loadUserAppointments(refresh: true);
    await _ensureCoachClients();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final messagingProvider = context.watch<MessagingProvider>();
    final quotaProvider = context.watch<QuotaProvider>();
    final authProvider = context.watch<AuthProvider>();
    final appointmentProvider = context.watch<AppointmentProvider>();
    final coachProvider = context.watch<CoachProvider>();
    final tier = authProvider.user?.subscriptionTier ?? 'Freemium';
    final canAttach = tier == 'Smart Premium';
    final isArabic = languageProvider.isArabic;
    final isCoach = (authProvider.user?.role ?? 'user') == 'coach';

    if (!_introLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_showIntro) {
      return CoachIntroScreen(onGetStarted: _completeIntro);
    }

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.8,
                child: Image.asset(
                  'assets/placeholders/splash_onboarding/coach_onboarding.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  AnimatedReveal(
                    offset: Offset(isArabic ? 0.16 : -0.16, 0),
                    initialScale: 0.96,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF4338CA), Color(0xFF6D28D9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                                icon: Icon(
                                  isArabic
                                      ? Icons.arrow_forward
                                      : Icons.arrow_back,
                                  color: Colors.white,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      languageProvider.t('coach_messaging'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      languageProvider
                                          .t('coach_messaging_subtitle'),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.videocam,
                                    color: Colors.white),
                                onPressed: quotaProvider.canMakeVideoCall()
                                    ? _openVideoBooking
                                    : null,
                                tooltip: languageProvider.t('book_video_call'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          AnimatedReveal(
                            delay: const Duration(milliseconds: 140),
                            offset: const Offset(0, 0.12),
                            initialScale: 0.97,
                            child:
                                _buildCoachInfoCard(languageProvider, isArabic),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        AnimatedReveal(
                          delay: const Duration(milliseconds: 120),
                          offset: const Offset(0, 0.12),
                          initialScale: 0.97,
                          child: const QuotaBanner(type: 'message'),
                        ),
                        const SizedBox(height: 6),
                        AnimatedReveal(
                          delay: const Duration(milliseconds: 180),
                          offset: const Offset(0, 0.12),
                          initialScale: 0.97,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                QuotaIndicator(
                                    type: 'message', showDetails: false),
                                SizedBox(width: 16),
                                QuotaIndicator(
                                    type: 'videoCall', showDetails: false),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedReveal(
                          delay: const Duration(milliseconds: 240),
                          offset: const Offset(0, 0.12),
                          initialScale: 0.97,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: TabBar(
                              labelColor: AppColors.primary,
                              unselectedLabelColor: AppColors.textSecondary,
                              indicatorColor: AppColors.primary,
                              indicatorWeight: 3,
                              tabs: [
                                Tab(text: languageProvider.t('messages')),
                                Tab(text: languageProvider.t('sessions')),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: AnimatedReveal(
                      delay: const Duration(milliseconds: 320),
                      offset: const Offset(0, 0.08),
                      initialScale: 0.99,
                      child: TabBarView(
                        children: [
                          _buildMessagesTab(
                            languageProvider,
                            messagingProvider,
                            quotaProvider,
                            canAttach,
                            coachProvider,
                            authProvider,
                            isCoach,
                          ),
                          _buildSessionsTab(
                            languageProvider,
                            quotaProvider,
                            appointmentProvider,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesTab(
    LanguageProvider lang,
    MessagingProvider messagingProvider,
    QuotaProvider quotaProvider,
    bool canAttach,
    CoachProvider coachProvider,
    AuthProvider authProvider,
    bool isCoach,
  ) {
    final filteredConversations = _filteredConversations(
      messagingProvider,
      coachProvider,
      authProvider,
      lang,
      isCoach,
    );
    final isArabic = lang.isArabic;
    final isThreadLoading = messagingProvider.isLoading &&
        (messagingProvider.messages.isEmpty ||
            (_pendingConversationId != null));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
          child: _buildConversationHeader(
            lang,
            messagingProvider,
            isCoach,
          ),
        ),
        _buildConversationRail(
          lang,
          messagingProvider,
          coachProvider,
          filteredConversations,
          authProvider,
          isCoach,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: isThreadLoading
              ? const Center(child: CircularProgressIndicator())
              : messagingProvider.messages.isEmpty
                  ? _buildEmptyState(lang, isArabic)
                  : _buildMessagesList(
                      messagingProvider,
                      lang,
                      isArabic,
                    ),
        ),
        _buildMessageInput(
          lang,
          messagingProvider,
          quotaProvider,
          isArabic,
          canAttach,
        ),
      ],
    );
  }

  Widget _buildConversationHeader(
    LanguageProvider lang,
    MessagingProvider messagingProvider,
    bool isCoach,
  ) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _conversationSearchController,
            decoration: InputDecoration(
              hintText: lang.t('coach_search_hint'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _conversationQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _conversationSearchController.clear();
                        _handleConversationSearch();
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: lang.t('coach_refresh_inbox'),
          onPressed: _refreshUserProfileAndData,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _buildConversationRail(
    LanguageProvider lang,
    MessagingProvider messagingProvider,
    CoachProvider coachProvider,
    List<Conversation> conversations,
    AuthProvider authProvider,
    bool isCoach,
  ) {
    if (messagingProvider.isLoading && conversations.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (conversations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: CustomCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang.t('coach_no_conversations_title'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                lang.t('coach_no_conversations_desc'),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 138,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: conversations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          return _buildConversationChip(
            conversation,
            lang,
            messagingProvider,
            coachProvider,
            authProvider,
            isCoach,
          );
        },
      ),
    );
  }

  Widget _buildConversationChip(
    Conversation conversation,
    LanguageProvider lang,
    MessagingProvider provider,
    CoachProvider coachProvider,
    AuthProvider authProvider,
    bool isCoach,
  ) {
    final isActive = provider.activeConversation?.id == conversation.id;
    final displayName = _resolveConversationName(
      conversation,
      coachProvider,
      lang,
      authProvider,
      isCoach,
    );
    final initials = _conversationInitials(displayName);
    final snippet = _conversationSnippet(conversation, lang);
    final subtitle = _conversationSubtitle(conversation, lang);
    final isLoading =
        _pendingConversationId == conversation.id && provider.isLoading;

    return GestureDetector(
      onTap: () => _handleConversationSelection(conversation, provider, lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 230,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (conversation.unreadCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${conversation.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Text(
                snippet,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isActive
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            if (isLoading) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(minHeight: 3),
            ],
          ],
        ),
      ),
    );
  }

  List<Conversation> _filteredConversations(
    MessagingProvider provider,
    CoachProvider coachProvider,
    AuthProvider authProvider,
    LanguageProvider lang,
    bool isCoach,
  ) {
    if (_conversationQuery.isEmpty) {
      return provider.conversations;
    }
    final query = _conversationQuery.toLowerCase();
    return provider.conversations.where((conversation) {
      final name = _resolveConversationNameForFilter(
        conversation,
        coachProvider,
        authProvider,
        lang,
        isCoach,
      );
      final snippet = conversation.lastMessageContent?.toLowerCase() ?? '';
      return (name?.toLowerCase().contains(query) ?? false) ||
          snippet.contains(query);
    }).toList();
  }

  String _assignedCoachName(LanguageProvider lang, AuthProvider authProvider) {
    if (DemoConfig.isDemo) {
      return lang.t('coach_demo_name');
    }
    return lang.t('coach');
  }

  String _resolveConversationName(
    Conversation conversation,
    CoachProvider coachProvider,
    LanguageProvider lang,
    AuthProvider authProvider,
    bool isCoach,
  ) {
    if (!isCoach) {
      return _assignedCoachName(lang, authProvider);
    }
    return _resolveClientName(conversation.userId, coachProvider, lang);
  }

  String? _resolveConversationNameForFilter(
    Conversation conversation,
    CoachProvider coachProvider,
    AuthProvider authProvider,
    LanguageProvider lang,
    bool isCoach,
  ) {
    if (!isCoach) {
      return _assignedCoachName(lang, authProvider);
    }
    return _resolveClientNameForFilter(conversation.userId, coachProvider);
  }

  String _resolveClientName(
    String userId,
    CoachProvider coachProvider,
    LanguageProvider lang,
  ) {
    for (final client in coachProvider.clients) {
      if (client.id == userId) {
        return client.fullName;
      }
    }
    if (DemoConfig.isDemo && userId == DemoConfig.demoUserId) {
      return lang.t('auth_demo_user');
    }
    return lang.t('coach_client_fallback');
  }

  String? _resolveClientNameForFilter(
    String userId,
    CoachProvider coachProvider,
  ) {
    for (final client in coachProvider.clients) {
      if (client.id == userId) {
        return client.fullName;
      }
    }
    return null;
  }

  String _conversationInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _conversationSubtitle(
    Conversation conversation,
    LanguageProvider lang,
  ) {
    final timestamp = conversation.lastMessageAt;
    if (timestamp == null) {
      return lang.t('coach_awaiting_activity');
    }
    final formatter = DateFormat(
      'MMM d \u2022 h:mm a',
      lang.isArabic ? 'ar' : 'en',
    );
    return formatter.format(timestamp);
  }

  String _conversationSnippet(Conversation conversation, LanguageProvider lang) {
    final content = conversation.lastMessageContent;
    if (content == null || content.isEmpty) {
      return lang.t('coach_kickoff_prompt');
    }
    return content;
  }

  Future<void> _handleConversationSelection(
    Conversation conversation,
    MessagingProvider provider,
    LanguageProvider lang,
  ) async {
    setState(() => _pendingConversationId = conversation.id);
    await provider.selectConversation(conversation.id, isArabic: lang.isArabic);
    if (!mounted) return;
    setState(() => _pendingConversationId = null);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildSessionsTab(
    LanguageProvider lang,
    QuotaProvider quotaProvider,
    AppointmentProvider appointmentProvider,
  ) {
    final isArabic = lang.isArabic;
    final upcoming = appointmentProvider.upcomingAppointments;
    final nextSession = appointmentProvider.nextVideoCall;
    final isLoading =
        appointmentProvider.isLoading && !appointmentProvider.hasLoaded;

    return RefreshIndicator(
      onRefresh: _refreshAppointments,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          AnimatedReveal(
            offset: const Offset(0, 0.14),
            initialScale: 0.97,
            child: _buildSessionsHero(lang),
          ),
          const SizedBox(height: 16),
          if (isLoading) ...[
            const SizedBox(height: 80),
            const Center(child: CircularProgressIndicator()),
          ] else ...[
            if (appointmentProvider.error != null)
              AnimatedReveal(
                offset: const Offset(0, 0.14),
                child: CustomCard(
                  padding: EdgeInsets.zero,
                  color: AppColors.error.withValues(alpha: 0.08),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 12),
                      Expanded(child: Text(appointmentProvider.error!)),
                      TextButton(
                        onPressed: _refreshAppointments,
                        child: Text(lang.t('retry')),
                      ),
                    ],
                  ),
                ),
              ),
            if (nextSession != null) ...[
              AnimatedReveal(
                delay: const Duration(milliseconds: 120),
                offset: const Offset(0, 0.12),
                child: _buildNextSessionCard(
                    nextSession, lang, isArabic, appointmentProvider),
              ),
              const SizedBox(height: 16),
            ],
            AnimatedReveal(
              delay: const Duration(milliseconds: 200),
              offset: const Offset(0, 0.12),
              child: _buildUpcomingSessionsList(
                lang,
                isArabic,
                upcoming,
                appointmentProvider,
              ),
            ),
          ],
          const SizedBox(height: 24),
          AnimatedReveal(
            delay: const Duration(milliseconds: 260),
            offset: const Offset(0, 0.14),
            initialScale: 0.97,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    quotaProvider.canMakeVideoCall() ? _openVideoBooking : null,
                icon: const Icon(Icons.calendar_month),
                label: Text(lang.t('book_video_call')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsHero(LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.videocam_outlined,
                color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.t('sessions'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  lang.t('book_video_call_hint'),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextSessionCard(
    Appointment appointment,
    LanguageProvider lang,
    bool isArabic,
    AppointmentProvider provider,
  ) {
    final dateText = _formatSessionDate(appointment, isArabic);
    final countdown = _formatCountdown(appointment, lang);
    final canJoin = provider.canJoin(appointment);
    final isVideo = _isVideoSession(appointment);
    final isJoining = _joiningAppointmentId == appointment.id;
    final joinHint = lang.t('coach_join_hint');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4338CA), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.t('coach_next_video_call'),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            appointment.coachName ?? lang.t('coach'),
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            dateText,
            style: const TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
          ),
          if (countdown != null) ...[
            const SizedBox(height: 4),
            Text(
              countdown,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          CustomButton(
            text: lang.t('join_video_call'),
            onPressed: (isVideo && canJoin && !isJoining)
                ? () => _joinVideoCall(appointment)
                : null,
            isLoading: isJoining,
            fullWidth: true,
            variant: ButtonVariant.secondary,
            size: ButtonSize.large,
          ),
          if (!canJoin && isVideo)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                joinHint,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          TextButton(
            onPressed: () => _openAppointmentDetails(appointment),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: Text(lang.t('coach_session_details')),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingSessionsList(
    LanguageProvider lang,
    bool isArabic,
    List<Appointment> appointments,
    AppointmentProvider provider,
  ) {
    final title = lang.t('coach_upcoming_sessions');
    if (appointments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.event_available_outlined,
                size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              lang.t('coach_no_sessions_title'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              lang.t('book_video_call_hint'),
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        ...appointments.map(
          (appointment) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSessionCard(appointment, lang, isArabic, provider),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(
    Appointment appointment,
    LanguageProvider lang,
    bool isArabic,
    AppointmentProvider provider,
  ) {
    final dateText = _formatSessionDate(appointment, isArabic);
    final typeLabel = _typeLabel(appointment, lang);
    final isVideo = _isVideoSession(appointment);
    final canJoin = provider.canJoin(appointment);
    final isJoining = _joiningAppointmentId == appointment.id;
    final hint = lang.t('coach_join_hint');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  (appointment.coachName ?? lang.t('coach'))
                      .characters
                      .take(2)
                      .toString()
                      .toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.coachName ?? lang.t('coach'),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      typeLabel,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(appointment.status, lang),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            dateText,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: lang.t('join_video_call'),
                  onPressed: (isVideo && canJoin && !isJoining)
                      ? () => _joinVideoCall(appointment)
                      : null,
                  isLoading: isJoining,
                  size: ButtonSize.small,
                  fullWidth: true,
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => _openAppointmentDetails(appointment),
                child: Text(lang.t('details')),
              ),
            ],
          ),
          if (!canJoin && isVideo)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                hint,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, LanguageProvider lang) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        lang.t(status),
        style:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  String _formatSessionDate(Appointment appointment, bool isArabic) {
    final locale = isArabic ? 'ar' : 'en';
    try {
      final date = DateTime.parse(appointment.scheduledAt);
      final formatter = DateFormat('EEEE, MMM d \u2022 h:mm a', locale);
      return formatter.format(date);
    } catch (_) {
      return appointment.scheduledAt;
    }
  }

  String? _formatCountdown(Appointment appointment, LanguageProvider lang) {
    try {
      final date = DateTime.parse(appointment.scheduledAt);
      final diff = date.difference(DateTime.now());
      if (diff.isNegative) return null;
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      if (hours <= 0 && minutes <= 0) {
        return lang.t('coach_starting_now');
      }
      if (hours <= 0) {
        return lang.t('coach_starts_in_minutes', args: {
          'minutes': '$minutes',
        });
      }
      if (minutes > 0) {
        return lang.t('coach_starts_in_hours_minutes', args: {
          'hours': '$hours',
          'minutes': '$minutes',
        });
      }
      return lang.t('coach_starts_in_hours', args: {
        'hours': '$hours',
      });
    } catch (_) {
      return null;
    }
  }

  String _typeLabel(Appointment appointment, LanguageProvider lang) {
    switch ((appointment.type ?? 'video').toLowerCase()) {
      case 'video':
        return lang.t('video_call');
      case 'chat':
        return lang.t('chat');
      case 'assessment':
        return lang.t('assessment');
      default:
        return lang.t('session');
    }
  }

  bool _isVideoSession(Appointment appointment) {
    final type = (appointment.type ?? 'video').toLowerCase();
    return type == 'video';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.textSecondary;
    }
  }

  void _openVideoBooking() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VideoBookingScreen()),
    );
  }

  void _openAppointmentDetails(Appointment appointment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppointmentDetailScreen(appointment: appointment),
      ),
    );
  }

  Future<void> _joinVideoCall(Appointment appointment) async {
    final videoCallProvider = context.read<VideoCallProvider>();
    final languageProvider = context.read<LanguageProvider>();

    setState(() => _joiningAppointmentId = appointment.id);

    try {
      final result = await videoCallProvider.canJoinCall(appointment.id);
      if (result == null || result['canJoin'] != true) {
        final message =
            result?['reason'] ?? languageProvider.t('cannot_join_call');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
        return;
      }

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoCallScreen(
            appointmentId: appointment.id,
            coachId: appointment.coachId,
            coachName: appointment.coachName ?? languageProvider.t('coach'),
            isCoach: false,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(languageProvider.t('error'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _joiningAppointmentId = null);
      }
    }
  }

  Widget _buildCoachInfoCard(LanguageProvider lang, bool isArabic) {
    final authProvider = context.read<AuthProvider>();
    final userCoachId = authProvider.user?.coachId;
    if (!DemoConfig.isDemo && (userCoachId == null || userCoachId.isEmpty)) {
      return const SizedBox.shrink();
    }

    final coachId = DemoConfig.isDemo ? DemoConfig.demoCoachId : userCoachId!;
    final coachName =
        DemoConfig.isDemo ? lang.t('coach_demo_name') : lang.t('coach');
    final coachInitials = DemoConfig.isDemo
        ? lang.t('coach_demo_initials')
        : (coachName.trim().isNotEmpty
            ? coachName.trim().substring(0, 1)
            : 'C');
    final specialties = DemoConfig.isDemo
        ? [
            lang.t('coach_specialty_strength'),
            lang.t('coach_specialty_weight_loss'),
            lang.t('coach_specialty_nutrition'),
          ]
        : const <String>[];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF7E22CE),
                child: Text(
                  coachInitials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coachName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (DemoConfig.isDemo) ...[
                          const Icon(Icons.star,
                              size: 14, color: Color(0xFFFBBF24)),
                          const SizedBox(width: 4),
                          const Text(
                            '4.9',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '•',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '8 ${lang.t('coach_years')}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (specialties.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: specialties
                  .map(
                    (specialty) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        specialty,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PublicCoachProfileScreen(coachId: coachId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.92),
                foregroundColor: const Color(0xFF111827),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: isArabic
                    ? [
                        Text(
                          lang.t('coach_view_profile'),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.star, size: 16),
                      ]
                    : [
                        const Icon(Icons.star, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          lang.t('coach_view_profile'),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(LanguageProvider lang, bool isArabic) {
    return Center(
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
            lang.t('start_conversation_with_coach'),
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            lang.t('ask_questions_about_workouts_nutrition'),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textDisabled,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(
    MessagingProvider provider,
    LanguageProvider lang,
    bool isArabic,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      reverse: true,
      itemCount: provider.messages.length,
      itemBuilder: (context, index) {
        final message = provider.messages[provider.messages.length - 1 - index];
        return _buildMessageBubble(message, lang, isArabic);
      },
    );
  }

  Widget _buildMessageBubble(
    Message message,
    LanguageProvider lang,
    bool isArabic,
  ) {
    final authProvider = context.read<AuthProvider>();
    final isMe = message.senderId == authProvider.user?.id;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Message bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: isMe ? const Radius.circular(4) : null,
                  bottomLeft: !isMe ? const Radius.circular(4) : null,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.type == MessageType.text)
                    Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 15,
                        color: isMe ? Colors.white : AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  if (message.type == MessageType.image &&
                      message.attachmentUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildImageAttachment(message.attachmentUrl!),
                    ),
                  if (message.type == MessageType.video &&
                      message.attachmentUrl != null)
                    Container(
                      width: 200,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (message.type == MessageType.file &&
                      message.attachmentUrl != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.white.withValues(alpha: 0.2)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.insert_drive_file,
                            color: isMe ? Colors.white : AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              message.content,
                              style: TextStyle(
                                color:
                                    isMe ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Timestamp and status
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt, lang),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textDisabled,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.status == 'read'
                        ? Icons.done_all
                        : message.status == 'delivered'
                            ? Icons.done_all
                            : Icons.done,
                    size: 14,
                    color: message.status == 'read'
                        ? AppColors.primary
                        : AppColors.textDisabled,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(
    LanguageProvider lang,
    MessagingProvider messagingProvider,
    QuotaProvider quotaProvider,
    bool isArabic,
    bool canAttach,
  ) {
    final canSend = quotaProvider.canSendMessage();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (canAttach)
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed:
                  canSend ? () => _showAttachmentOptions(lang) : null,
              color: AppColors.textSecondary,
            ),
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: canSend,
              decoration: InputDecoration(
                hintText: lang.t('type_a_message'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: messagingProvider.isSending
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            onPressed: canSend && !messagingProvider.isSending
                ? () => _sendMessage(messagingProvider, quotaProvider)
                : null,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(
    MessagingProvider messagingProvider,
    QuotaProvider quotaProvider,
  ) async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();

    final success = await messagingProvider.sendMessage(
      content,
      type: MessageType.text,
    );

    if (success) {
      quotaProvider.incrementMessageCount();
      _scrollToBottom();
    } else if (messagingProvider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(messagingProvider.error!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }


  void _showAttachmentOptions(LanguageProvider lang) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo, color: AppColors.primary),
              title: Text(lang.t('photo')),
              onTap: () {
                Navigator.pop(context);
                _pickAttachment('image', lang);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: AppColors.secondary),
              title: Text(lang.t('video')),
              onTap: () {
                Navigator.pop(context);
                _pickAttachment('video', lang);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.insert_drive_file, color: AppColors.accent),
              title: Text(lang.t('file')),
              onTap: () {
                Navigator.pop(context);
                _pickAttachment('file', lang);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAttachment(String type, LanguageProvider lang) async {
    final messagingProvider = context.read<MessagingProvider>();
    final quotaProvider = context.read<QuotaProvider>();

    String? filePath;
    String? displayName;
    MessageType messageType = MessageType.file;

    try {
      if (type == 'image') {
        messageType = MessageType.image;
        final picked = await _picker.pickImage(source: ImageSource.gallery);
        filePath = picked?.path;
        displayName = picked?.name;
      } else if (type == 'video') {
        messageType = MessageType.video;
        final picked = await _picker.pickVideo(source: ImageSource.gallery);
        filePath = picked?.path;
        displayName = picked?.name;
      } else {
        messageType = MessageType.file;
        final result = await FilePicker.platform.pickFiles();
        if (result != null && result.files.isNotEmpty) {
          final file = result.files.single;
          filePath = file.path;
          displayName = file.name;

          // Web can return bytes without a usable path.
          if (kIsWeb && filePath == null) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(lang.t('coach_file_unsupported_web')),
              ),
            );
            return;
          }
        }
      }

      if (filePath == null || filePath.isEmpty) {
        return;
      }

      final content = (displayName == null || displayName.isEmpty)
          ? (type == 'image'
              ? lang.t('photo')
              : type == 'video'
                  ? lang.t('video')
                  : lang.t('file'))
          : displayName;

      final success = await messagingProvider.sendMessageWithAttachment(
        content,
        filePath,
        messageType,
      );

      if (success) {
        quotaProvider.incrementMessageCount();
        _scrollToBottom();
      } else if (messagingProvider.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(messagingProvider.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildImageAttachment(String attachmentUrl) {
    final uri = Uri.tryParse(attachmentUrl);
    final isNetwork =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');

    if (isNetwork) {
      return Image.network(
        attachmentUrl,
        width: 200,
        fit: BoxFit.cover,
      );
    }

    // Local file path (mobile/desktop). On web we fall back to Image.network.
    if (!kIsWeb) {
      return Image.file(
        File(attachmentUrl),
        width: 200,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 200,
          height: 120,
          alignment: Alignment.center,
          color: Colors.black12,
          child: const Icon(Icons.broken_image_outlined),
        ),
      );
    }

    return Image.network(
      attachmentUrl,
      width: 200,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 200,
        height: 120,
        alignment: Alignment.center,
        color: Colors.black12,
        child: const Icon(Icons.broken_image_outlined),
      ),
    );
  }

  String _formatTime(DateTime timestamp, LanguageProvider lang) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return lang.t('time_date_short', args: {
        'day': '${timestamp.day}',
        'month': '${timestamp.month}',
      });
    } else if (difference.inHours > 0) {
      return lang.t('time_hours_ago', args: {
        'hours': '${difference.inHours}',
      });
    } else if (difference.inMinutes > 0) {
      return lang.t('time_minutes_ago', args: {
        'minutes': '${difference.inMinutes}',
      });
    } else {
      return lang.t('time_just_now');
    }
  }
}
