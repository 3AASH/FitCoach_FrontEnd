import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/config/demo_config.dart';
import '../../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/messaging_provider.dart';
import 'coach_schedule_session_sheet.dart';

class CoachMessageThreadScreen extends StatefulWidget {
  final String clientId;
  final String clientName;

  const CoachMessageThreadScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<CoachMessageThreadScreen> createState() =>
      _CoachMessageThreadScreenState();
}

class _CoachMessageThreadScreenState extends State<CoachMessageThreadScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isConnecting = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _connect());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final messagingProvider = context.read<MessagingProvider>();
    final languageProvider = context.read<LanguageProvider>();
    final currentUserId = context.read<AuthProvider>().user?.id;
    final coachId = currentUserId ??
        (DemoConfig.isDemo ? DemoConfig.demoCoachId : null);

    if (coachId == null || coachId.isEmpty) {
      if (mounted) {
        setState(() => _isConnecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.t('auth_session_expired')),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    await messagingProvider.connect(
      widget.clientId,
      coachId,
      isArabic: languageProvider.isArabic,
      currentUserId: currentUserId,
    );
    setState(() => _isConnecting = false);
  }

  Future<void> _sendMessage() async {
    final messagingProvider = context.read<MessagingProvider>();
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final success = await messagingProvider.sendMessage(content);
    if (!mounted) return;
    if (success) {
      _messageController.clear();
      await Future.delayed(const Duration(milliseconds: 50));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } else if (messagingProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(messagingProvider.error!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final messagingProvider = context.watch<MessagingProvider>();
    final isArabic = lang.isArabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.clientName),
        actions: [
          IconButton(
            tooltip: lang.t('coach_schedule_call'),
            icon: const Icon(Icons.video_call),
            onPressed: () => showCoachScheduleSessionSheet(
              context,
              clientId: widget.clientId,
              clientName: widget.clientName,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isConnecting)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: messagingProvider.messages.isEmpty
                  ? _buildEmptyState(lang)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 24),
                      itemCount: messagingProvider.messages.length,
                      itemBuilder: (context, index) {
                        final message = messagingProvider.messages[index];
                        final isCoach = message.senderId != widget.clientId;
                        final timestamp =
                            DateFormat('MMM d • HH:mm', isArabic ? 'ar' : 'en')
                                .format(message.createdAt);
                        return Align(
                          alignment: isCoach
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            child: Card(
                              color: isCoach
                                  ? AppColors.primary.withValues(alpha: 0.9)
                                  : AppColors.background,
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.content,
                                      style: TextStyle(
                                        color: isCoach
                                            ? AppColors.textWhite
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        timestamp,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isCoach
                                              ? AppColors.textWhite
                                                  .withValues(alpha: 0.7)
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          _buildComposer(lang, messagingProvider),
        ],
      ),
    );
  }

  Widget _buildEmptyState(LanguageProvider lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            lang.t('coach_start_conversation_prompt'),
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildComposer(LanguageProvider lang, MessagingProvider provider) {
    final isArabic = lang.isArabic;
    final canSend =
        _messageController.text.trim().isNotEmpty && !provider.isSending;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: lang.t('type_message'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: canSend ? AppColors.primary : AppColors.border,
              child: IconButton(
                icon: provider.isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        isArabic ? Icons.send : Icons.send_rounded,
                        color: AppColors.textWhite,
                      ),
                onPressed: canSend ? _sendMessage : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
