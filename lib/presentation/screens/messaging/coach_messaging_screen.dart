import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/demo_config.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/coach_client.dart';
import '../../../data/models/message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/coach_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/messaging_provider.dart';
import '../../providers/quota_provider.dart';
import '../../widgets/animated_reveal.dart';
import '../../widgets/custom_card.dart';
import '../booking/video_booking_screen.dart';
import '../coach/public_coach_profile_screen.dart';
import 'coach_intro_screen.dart';

class CoachMessagingScreen extends StatefulWidget {
  final int initialTabIndex;
  final String? targetClientId;
  final String? targetClientName;

  const CoachMessagingScreen({
    super.key,
    this.initialTabIndex = 0,
    this.targetClientId,
    this.targetClientName,
  });

  @override
  State<CoachMessagingScreen> createState() => _CoachMessagingScreenState();
}

class _CoachMessagingScreenState extends State<CoachMessagingScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  MessagingProvider? _messagingProvider;
  bool _showIntro = false;
  bool _introLoaded = false;
  String? _lastObservedConversationId;
  String? _lastObservedLatestMessageId;
  int _lastObservedMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _loadIntroFlag();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attachMessagingListener();
      unawaited(_initializeMessaging());
    });
  }

  @override
  void dispose() {
    _messagingProvider?.removeListener(_handleMessagingChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _attachMessagingListener() {
    final provider = context.read<MessagingProvider>();
    if (identical(_messagingProvider, provider)) {
      return;
    }
    _messagingProvider?.removeListener(_handleMessagingChanged);
    _messagingProvider = provider;
    _messagingProvider?.addListener(_handleMessagingChanged);
  }

  Future<void> _loadIntroFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final seenIntro = prefs.getBool('coach_intro_seen') ?? false;
    if (!mounted) {
      return;
    }
    setState(() {
      _showIntro = !seenIntro;
      _introLoaded = true;
    });
  }

  Future<void> _completeIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('coach_intro_seen', true);
    if (!mounted) {
      return;
    }
    setState(() {
      _showIntro = false;
    });
  }

  Future<void> _loadCoachClientsIfNeeded() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user?.role != 'coach') {
      return;
    }

    final coachId = authProvider.user?.id;
    final coachProvider = context.read<CoachProvider>();
    if (coachId == null ||
        coachId.isEmpty ||
        coachProvider.clients.isNotEmpty) {
      return;
    }

    await coachProvider.loadClients(coachId: coachId);
  }

  Future<void> _initializeMessaging() async {
    final messagingProvider = context.read<MessagingProvider>();
    final languageProvider = context.read<LanguageProvider>();
    final authProvider = context.read<AuthProvider>();

    final currentUserId = authProvider.user?.id;
    final isCoach = (authProvider.user?.role ?? 'user') == 'coach';
    final assignedCoachId =
        DemoConfig.isDemo ? DemoConfig.demoCoachId : authProvider.user?.coachId;
    final targetClientId = widget.targetClientId?.trim();
    final isCoachInboxView =
        isCoach && (targetClientId == null || targetClientId.isEmpty);

    await _loadCoachClientsIfNeeded();

    if (isCoach &&
        targetClientId != null &&
        targetClientId.isNotEmpty &&
        currentUserId != null &&
        currentUserId.isNotEmpty) {
      await messagingProvider.connect(
        targetClientId,
        currentUserId,
        isArabic: languageProvider.isArabic,
        currentUserId: currentUserId,
      );
      return;
    }

    if (!isCoach &&
        currentUserId != null &&
        currentUserId.isNotEmpty &&
        assignedCoachId != null &&
        assignedCoachId.isNotEmpty) {
      await messagingProvider.connect(
        currentUserId,
        assignedCoachId,
        isArabic: languageProvider.isArabic,
        currentUserId: currentUserId,
      );
      return;
    }

    await messagingProvider.connectSocket();
    await messagingProvider.loadConversations(
      isArabic: languageProvider.isArabic,
      isCoach: isCoach,
      currentUserId: currentUserId,
      autoSelectConversation: !isCoachInboxView,
    );

    if (!isCoachInboxView &&
        messagingProvider.activeConversation == null &&
        messagingProvider.conversations.isNotEmpty) {
      await messagingProvider.selectConversation(
        messagingProvider.conversations.first.id,
        isArabic: languageProvider.isArabic,
      );
    }
  }

  Future<void> _refreshThread() async {
    await _initializeMessaging();
  }

  void _scrollToBottom() {
    _scrollToBottomAfterFrame();
  }

  void _scrollToBottomAfterFrame({bool animated = true}) {
    if (!_scrollController.hasClients) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      if (animated) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(0);
      }
    });
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) {
      return true;
    }
    return _scrollController.position.pixels <= 120;
  }

  void _handleMessagingChanged() {
    if (!mounted) {
      return;
    }

    final provider = _messagingProvider;
    if (provider == null) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final isCoach = (authProvider.user?.role ?? 'user') == 'coach';
    if (_isCoachInboxView(isCoach)) {
      _lastObservedConversationId = provider.activeConversationId;
      _lastObservedMessageCount = provider.messages.length;
      _lastObservedLatestMessageId =
          provider.messages.isNotEmpty ? provider.messages.last.id : null;
      return;
    }

    final conversationId = provider.activeConversationId;
    final messages = provider.messages;
    final latestMessage = messages.isNotEmpty ? messages.last : null;
    final latestMessageId = latestMessage?.id;
    final previousConversationId = _lastObservedConversationId;
    final previousMessageCount = _lastObservedMessageCount;
    final previousLatestMessageId = _lastObservedLatestMessageId;

    final conversationChanged = conversationId != previousConversationId;
    final latestMessageChanged = latestMessageId != previousLatestMessageId;
    final initialConversationLoad = conversationId != null &&
        conversationId.isNotEmpty &&
        messages.isNotEmpty &&
        (conversationChanged || previousMessageCount == 0);
    final currentUserId = authProvider.user?.id;
    final newestFromCurrentUser =
        latestMessage != null && latestMessage.senderId == currentUserId;
    final shouldScrollForIncoming = latestMessageChanged &&
        latestMessage != null &&
        !newestFromCurrentUser &&
        _isNearBottom();

    if (initialConversationLoad) {
      _scrollToBottomAfterFrame(animated: false);
    } else if (latestMessageChanged && newestFromCurrentUser) {
      _scrollToBottomAfterFrame();
    } else if (shouldScrollForIncoming) {
      _scrollToBottomAfterFrame();
    }

    _lastObservedConversationId = conversationId;
    _lastObservedMessageCount = messages.length;
    _lastObservedLatestMessageId = latestMessageId;
  }

  bool _isCoachInboxView(bool isCoach) {
    final targetClientId = widget.targetClientId?.trim();
    return isCoach && (targetClientId == null || targetClientId.isEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final messagingProvider = context.watch<MessagingProvider>();
    final authProvider = context.watch<AuthProvider>();
    final coachProvider = context.watch<CoachProvider>();
    final isCoach = (authProvider.user?.role ?? 'user') == 'coach';
    final canAttach =
        (authProvider.user?.subscriptionTier ?? 'Freemium') == 'Smart Premium';
    final isCoachInboxView = _isCoachInboxView(isCoach);

    if (!_introLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_showIntro) {
      return CoachIntroScreen(onGetStarted: _completeIntro);
    }

    final statusText = _statusText(lang, messagingProvider);

    return Scaffold(
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
                  offset: Offset(lang.isArabic ? 0.16 : -0.16, 0),
                  initialScale: 0.97,
                  child: _buildHeader(
                    lang,
                    messagingProvider,
                    statusText,
                    isCoachInboxView,
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshThread,
                    child: isCoachInboxView
                        ? _buildCoachInboxBody(
                            lang,
                            messagingProvider,
                            coachProvider,
                          )
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            children: [
                              if (_shouldShowSummaryCard(
                                  isCoach, coachProvider))
                                AnimatedReveal(
                                  delay: const Duration(milliseconds: 120),
                                  offset: const Offset(0, 0.08),
                                  initialScale: 0.98,
                                  child: _buildSummaryCard(
                                    lang,
                                    authProvider,
                                    coachProvider,
                                    isCoach,
                                  ),
                                ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.58,
                                child: _buildThreadBody(
                                  lang,
                                  messagingProvider,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                if (!isCoachInboxView)
                  _buildMessageInput(
                    lang,
                    messagingProvider,
                    canAttach,
                    isCoach,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    LanguageProvider lang,
    MessagingProvider messagingProvider,
    String? statusText,
    bool isCoachInboxView,
  ) {
    return Container(
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
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(
                  lang.isArabic ? Icons.arrow_forward : Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCoachInboxView
                          ? (lang.isArabic
                              ? 'رسائل العملاء'
                              : 'Client Messages')
                          : _threadTitle(lang),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      isCoachInboxView
                          ? (lang.isArabic
                              ? 'اختر عميلًا لفتح المحادثة'
                              : 'Choose a client to open the chat')
                          : (statusText ?? _threadSubtitle(lang)),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: lang.t('refresh'),
                onPressed: messagingProvider.isLoading ? null : _refreshThread,
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoachInboxBody(
    LanguageProvider lang,
    MessagingProvider messagingProvider,
    CoachProvider coachProvider,
  ) {
    final clients = coachProvider.clients;

    if (coachProvider.isLoading && clients.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (clients.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: [
          _buildEmptyState(
            lang,
            title: lang.isArabic ? 'لا يوجد عملاء بعد' : 'No clients yet',
            description: lang.isArabic
                ? 'سيظهر عملاؤك هنا لبدء المحادثة معهم.'
                : 'Your clients will appear here so you can start chatting.',
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: clients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final client = clients[index];
        final conversation = _conversationForClient(
          messagingProvider.conversations,
          client.id,
        );
        return AnimatedReveal(
          delay: Duration(milliseconds: 40 * index),
          offset: const Offset(0, 0.05),
          child: _buildClientInboxTile(lang, client, conversation),
        );
      },
    );
  }

  Conversation? _conversationForClient(
    List<Conversation> conversations,
    String clientId,
  ) {
    for (final conversation in conversations) {
      if (conversation.userId == clientId) {
        return conversation;
      }
    }
    return null;
  }

  Widget _buildClientInboxTile(
    LanguageProvider lang,
    CoachClient client,
    Conversation? conversation,
  ) {
    final timestamp = conversation?.lastMessageAt ?? client.lastActivity;
    final subtitle = conversation?.lastMessageContent?.trim().isNotEmpty == true
        ? conversation!.lastMessageContent!
        : (lang.isArabic ? 'لا توجد رسائل بعد' : 'No messages yet');

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CoachMessagingScreen(
              targetClientId: client.id,
              targetClientName: client.fullName,
            ),
          ),
        );
      },
      child: CustomCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                client.initials,
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
                    client.fullName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (timestamp != null)
                  Text(
                    _formatInboxTime(timestamp, lang),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textDisabled,
                    ),
                  ),
                if ((conversation?.unreadCount ?? 0) > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${conversation!.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatInboxTime(DateTime timestamp, LanguageProvider lang) {
    final now = DateTime.now();
    final sameDay = now.year == timestamp.year &&
        now.month == timestamp.month &&
        now.day == timestamp.day;
    final format = sameDay
        ? DateFormat('h:mm a', lang.isArabic ? 'ar' : 'en')
        : DateFormat('MMM d', lang.isArabic ? 'ar' : 'en');
    return format.format(timestamp);
  }

  Widget _buildThreadBody(
    LanguageProvider lang,
    MessagingProvider provider,
  ) {
    if (provider.isLoading && provider.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.messages.isEmpty) {
      return _buildEmptyState(
        lang,
        title: lang.isArabic ? 'لا توجد رسائل بعد' : 'No messages yet',
        description: lang.isArabic
            ? 'ابدأ المحادثة وستظهر الرسائل الحقيقية هنا فورًا.'
            : 'Start the conversation and real messages will appear here.',
      );
    }

    return _buildMessagesList(provider, lang);
  }

  Widget _buildSummaryCard(
    LanguageProvider lang,
    AuthProvider authProvider,
    CoachProvider coachProvider,
    bool isCoach,
  ) {
    if (isCoach) {
      final clientName = _coachThreadName(lang, coachProvider);
      return CustomCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                _initialsForName(clientName),
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
                    clientName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lang.isArabic
                        ? 'محادثة مباشرة مع العميل.'
                        : 'Direct 1-to-1 chat with your client.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final coachId =
        DemoConfig.isDemo ? DemoConfig.demoCoachId : authProvider.user?.coachId;
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF7E22CE),
                child: Text(
                  _initialsForName(lang.t('coach')),
                  style: const TextStyle(
                    color: Colors.white,
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
                      lang.t('coach'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lang.isArabic
                          ? 'محادثة مباشرة مع مدربك المعتمد.'
                          : 'Direct 1-to-1 chat with your assigned coach.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (coachId != null && coachId.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PublicCoachProfileScreen(
                            coachId: coachId,
                            onMessage: () => Navigator.of(context).maybePop(),
                            onBookCall: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const VideoBookingScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(lang.t('coach_view_profile')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const VideoBookingScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.videocam, size: 18),
                    label: Text(lang.t('book_video_call')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  bool _shouldShowSummaryCard(bool isCoach, CoachProvider coachProvider) {
    if (isCoach) {
      return widget.targetClientId != null ||
          widget.targetClientName != null ||
          context.read<MessagingProvider>().activeConversation != null;
    }
    return true;
  }

  Widget _buildEmptyState(
    LanguageProvider lang, {
    required String title,
    required String description,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              size: 72,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textDisabled,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(
    MessagingProvider provider,
    LanguageProvider lang,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 16),
      reverse: true,
      itemCount: provider.messages.length,
      itemBuilder: (context, index) {
        final message = provider.messages[provider.messages.length - 1 - index];
        return _buildMessageBubble(message, lang);
      },
    );
  }

  Widget _buildMessageBubble(
    Message message,
    LanguageProvider lang,
  ) {
    final currentUserId = context.read<AuthProvider>().user?.id;
    final isMe = message.senderId == currentUserId;

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
                        height: 1.4,
                        color: isMe ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  if (message.type == MessageType.image &&
                      message.attachmentUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _buildImageAttachment(message.attachmentUrl!),
                    ),
                  if (message.type == MessageType.video &&
                      message.attachmentUrl != null)
                    Container(
                      width: 200,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(10),
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
                            ? Colors.white.withValues(alpha: 0.18)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
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
    bool canAttach,
    bool isCoach,
  ) {
    final quotaProvider = context.read<QuotaProvider>();
    final canSend = isCoach ? true : quotaProvider.canSendMessage();
    final canCompose = canSend && messagingProvider.hasConversationTarget;
    final hintText = messagingProvider.hasConversationTarget
        ? lang.t('type_a_message')
        : (lang.isArabic
            ? 'لا يمكن بدء المحادثة من هنا بعد'
            : 'Open a direct chat target to start messaging');

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
              onPressed: canCompose ? () => _showAttachmentOptions(lang) : null,
              color: AppColors.textSecondary,
            ),
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: canCompose,
              decoration: InputDecoration(
                hintText: hintText,
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
              onChanged: messagingProvider.handleComposerChanged,
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
            onPressed: canCompose && !messagingProvider.isSending
                ? () => _sendMessage(messagingProvider, isCoach)
                : null,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(
    MessagingProvider messagingProvider,
    bool isCoach,
  ) async {
    final content = _messageController.text.trim();
    if (content.isEmpty) {
      return;
    }

    _messageController.clear();
    messagingProvider.handleComposerChanged('');

    final success = await messagingProvider.sendMessage(
      content,
      type: MessageType.text,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      if (!isCoach) {
        context.read<QuotaProvider>().incrementMessageCount();
      }
      _scrollToBottom();
      return;
    }

    if (messagingProvider.error != null) {
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
    final isCoach =
        (context.read<AuthProvider>().user?.role ?? 'user') == 'coach';

    String? filePath;
    String? displayName;
    var messageType = MessageType.file;

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
        final result = await FilePicker.platform.pickFiles();
        if (result != null && result.files.isNotEmpty) {
          final file = result.files.single;
          filePath = file.path;
          displayName = file.name;
          if (kIsWeb && filePath == null) {
            if (!mounted) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(lang.t('coach_file_unsupported_web'))),
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

      if (!mounted) {
        return;
      }

      if (success) {
        if (!isCoach) {
          context.read<QuotaProvider>().incrementMessageCount();
        }
        _scrollToBottom();
        return;
      }

      if (messagingProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(messagingProvider.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildImageAttachment(String attachmentUrl) {
    if (attachmentUrl.startsWith('http://') ||
        attachmentUrl.startsWith('https://')) {
      return Image.network(
        attachmentUrl,
        width: 220,
        height: 220,
        fit: BoxFit.cover,
      );
    }

    if (kIsWeb) {
      return Container(
        width: 220,
        height: 220,
        color: AppColors.surface,
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined),
      );
    }

    return Image.file(
      File(attachmentUrl),
      width: 220,
      height: 220,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 220,
        height: 220,
        color: AppColors.surface,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined),
      ),
    );
  }

  String _threadTitle(LanguageProvider lang) {
    final authProvider = context.read<AuthProvider>();
    final isCoach = (authProvider.user?.role ?? 'user') == 'coach';
    if (!isCoach) {
      return lang.t('coach_messaging');
    }
    return widget.targetClientName?.trim().isNotEmpty == true
        ? widget.targetClientName!
        : (lang.isArabic ? 'محادثة العميل' : 'Client chat');
  }

  String _threadSubtitle(LanguageProvider lang) {
    final authProvider = context.read<AuthProvider>();
    final isCoach = (authProvider.user?.role ?? 'user') == 'coach';
    if (isCoach) {
      return lang.isArabic
          ? 'محادثة مباشرة واحدة فقط'
          : 'One direct conversation only';
    }
    return lang.isArabic
        ? 'تواصل مباشر مع مدربك'
        : 'Direct chat with your coach';
  }

  String? _statusText(
    LanguageProvider lang,
    MessagingProvider messagingProvider,
  ) {
    if (messagingProvider.isOtherUserTyping) {
      return lang.isArabic ? 'يكتب الآن...' : 'typing...';
    }
    if (messagingProvider.isReconnecting) {
      return lang.isArabic ? 'جارٍ إعادة الاتصال...' : 'Reconnecting...';
    }
    if (!messagingProvider.isConnected && !DemoConfig.isDemo) {
      return lang.isArabic ? 'غير متصل' : 'Offline';
    }
    return null;
  }

  String _coachThreadName(
    LanguageProvider lang,
    CoachProvider coachProvider,
  ) {
    final explicitName = widget.targetClientName?.trim();
    if (explicitName != null && explicitName.isNotEmpty) {
      return explicitName;
    }

    final targetClientId = widget.targetClientId;
    if (targetClientId != null) {
      for (final client in coachProvider.clients) {
        if (client.id == targetClientId) {
          return client.fullName;
        }
      }
    }

    final activeConversation =
        context.read<MessagingProvider>().activeConversation;
    if (activeConversation != null) {
      for (final client in coachProvider.clients) {
        if (client.id == activeConversation.userId) {
          return client.fullName;
        }
      }
    }

    return lang.isArabic ? 'العميل' : 'Client';
  }

  String _initialsForName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, 1).toUpperCase();
  }

  String _formatTime(DateTime timestamp, LanguageProvider lang) {
    final formatter = DateFormat('MMM d • h:mm a', lang.isArabic ? 'ar' : 'en');
    return formatter.format(timestamp);
  }
}
