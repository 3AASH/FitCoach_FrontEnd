import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/config/demo_config.dart';
import '../../core/config/demo_mode.dart';
import '../../data/demo/repositories/demo_messaging_repository.dart';
import '../../data/models/message.dart';
import '../../data/repositories/messaging_repository.dart';

class MessagingProvider extends ChangeNotifier {
  MessagingProvider(
    this._repository, {
    DemoMessagingRepository? demoRepository,
    DemoModeConfig? demoConfig,
  })  : _demoRepository = demoRepository ?? DemoMessagingRepository(),
        _demoConfig = demoConfig ?? const DemoModeConfig();

  final MessagingRepository _repository;
  final DemoMessagingRepository _demoRepository;
  final DemoModeConfig _demoConfig;

  List<Message> _messages = [];
  final Map<String, List<Message>> _messagesByConversation = {};
  List<Conversation> _conversations = [];
  Conversation? _activeConversation;
  String? _currentUserId;
  String? _participantUserId;
  String? _participantCoachId;
  String? _recipientId;
  String? _typingConversationId;
  bool _isLoading = false;
  bool _isSending = false;
  bool _isConnected = false;
  bool _isReconnecting = false;
  bool _socketCallbacksBound = false;
  String? _error;
  Timer? _typingStopTimer;
  String? _localTypingConversationId;

  String currentChatId = '';

  List<Message> get messages => List.unmodifiable(_messages);
  Map<String, List<Message>> get messagesByConversation =>
      Map.unmodifiable(_messagesByConversation.map(
        (key, value) => MapEntry(key, List<Message>.unmodifiable(value)),
      ));
  List<Conversation> get conversations => List.unmodifiable(_conversations);
  Conversation? get activeConversation => _activeConversation;
  String? get activeConversationId => _activeConversation?.id;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isConnected => _isConnected;
  bool get isReconnecting => _isReconnecting;
  bool get isOffline => !_isConnected;
  bool get hasConversationTarget =>
      (_activeConversation?.id.isNotEmpty ?? false) ||
      (_recipientId?.isNotEmpty ?? false);
  bool get isOtherUserTyping =>
      _activeConversation != null &&
      _typingConversationId == _activeConversation!.id;
  String? get error => _error;

  Future<void> connect(
    String userId,
    String coachId, {
    bool isArabic = false,
    String? currentUserId,
  }) async {
    _currentUserId = currentUserId;
    _participantUserId = userId;
    _participantCoachId = coachId;
    if (currentUserId != null) {
      if (currentUserId == userId) {
        _recipientId = coachId;
      } else if (currentUserId == coachId) {
        _recipientId = userId;
      }
    }

    if (_demoConfig.isDemo) {
      currentChatId = '${userId}_$coachId';
      _activeConversation = await _demoRepository.buildConversation(
        userId: userId,
        coachId: coachId,
        isArabic: isArabic,
      );
      _messages = await _demoRepository.getMessages(
        conversationId: currentChatId,
        isArabic: isArabic,
      );
      _messagesByConversation[currentChatId] = List<Message>.from(_messages);
      _isConnected = true;
      _isReconnecting = false;
      _error = null;
      notifyListeners();
      return;
    }

    if (userId == 'invalid' || coachId == 'invalid') {
      _isConnected = false;
      _isReconnecting = false;
      _error = 'Invalid user or coach';
      notifyListeners();
      return;
    }

    _error = null;
    notifyListeners();

    await _initializeSocket();

    try {
      final conversations = await getConversations();
      _conversations = List<Conversation>.from(conversations);
      _sortConversationsByActivity();
      final match = conversations.firstWhere(
        (conversation) =>
            conversation.userId == userId && conversation.coachId == coachId,
        orElse: () => Conversation(
          id: '',
          userId: userId,
          coachId: coachId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (match.id.isNotEmpty) {
        await loadConversation(match.id, isArabic: isArabic);
      } else {
        _activeConversation = null;
        currentChatId = '';
        _messages = [];
        _syncVisibleMessages();
        notifyListeners();
      }
    } catch (_) {
      // Ignore conversation preloading errors.
    }
  }

  Future<void> _initializeSocket() async {
    if (_demoConfig.isDemo) {
      return;
    }

    _bindSocketCallbacks();

    try {
      _isReconnecting = !_repository.isConnected;
      notifyListeners();
      await _repository.connect();
      _isConnected = _repository.isConnected;
      _isReconnecting = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isConnected = false;
      _isReconnecting = false;
      notifyListeners();
    }
  }

  void _bindSocketCallbacks() {
    if (_socketCallbacksBound || _demoConfig.isDemo) {
      return;
    }

    _repository.onConnect(() {
      _isConnected = true;
      _isReconnecting = false;
      _error = null;
      _joinActiveConversation();
      notifyListeners();
    });

    _repository.onDisconnect((reason) {
      _isConnected = false;
      _isReconnecting = true;
      notifyListeners();
    });

    _repository.onConnectError((error) {
      if (kDebugMode) {
        debugPrint('Messaging socket connect_error: $error');
      }
      _isConnected = false;
      _isReconnecting = true;
      notifyListeners();
    });

    _repository.onError((error) {
      if (kDebugMode) {
        debugPrint('Messaging socket error: $error');
      }
    });

    _repository.onMessageReceived(_handleIncomingMessage);
    _repository.onMessageRead(_handleMessageReadEvent);
    _repository.onUserTyping(_handleUserTypingEvent);
    _repository.onUserStoppedTyping(_handleUserStoppedTypingEvent);
    _repository.onQuotaExceeded((error) {
      _error = error?.toString();
      notifyListeners();
    });
    _repository.onNotification((payload) {
      if (kDebugMode) {
        debugPrint('Messaging notification: $payload');
      }
    });

    _socketCallbacksBound = true;
  }

  void _handleIncomingMessage(Message message) {
    final isActiveConversation =
        _activeConversation?.id == message.conversationId;
    final isFromCurrentUser =
        _currentUserId != null && message.senderId == _currentUserId;

    var changed = false;

    if (isActiveConversation) {
      changed = _appendMessageIfMissing(message) || changed;
      if (!isFromCurrentUser) {
        _typingConversationId = null;
        unawaited(_markConversationReadAndEmit(
          message.conversationId,
          specificMessageId: message.id,
        ));
      }
    }

    changed = _updateConversationFromMessage(
          message,
          incrementUnread: !isActiveConversation && !isFromCurrentUser,
        ) ||
        changed;

    if (!isActiveConversation &&
        _conversations.every(
            (conversation) => conversation.id != message.conversationId)) {
      unawaited(_loadConversationMetadata(message.conversationId, message));
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  void _handleMessageReadEvent(
    String messageId,
    String conversationId,
    DateTime? readAt,
  ) {
    if (messageId.isEmpty) {
      return;
    }

    final resolvedReadAt = readAt ?? DateTime.now();
    var changed = false;
    final targetConversationIds = conversationId.isNotEmpty
        ? <String>[conversationId]
        : _messagesByConversation.keys.toList();

    for (final targetConversationId in targetConversationIds) {
      final existingMessages = _messagesByConversation[targetConversationId];
      if (existingMessages == null) {
        continue;
      }
      _messagesByConversation[targetConversationId] =
          existingMessages.map((message) {
        if (message.id != messageId) {
          return message;
        }
        changed = true;
        return message.copyWith(isRead: true, readAt: resolvedReadAt);
      }).toList();
    }
    _syncVisibleMessages();

    if (changed) {
      notifyListeners();
    }
  }

  void _handleUserTypingEvent(String conversationId, String userId) {
    if (conversationId.isEmpty) {
      return;
    }
    if (_currentUserId != null && userId == _currentUserId) {
      return;
    }
    _typingConversationId = conversationId;
    notifyListeners();
  }

  void _handleUserStoppedTypingEvent(String conversationId, String userId) {
    if (_currentUserId != null && userId == _currentUserId) {
      return;
    }
    if (conversationId == _typingConversationId) {
      _typingConversationId = null;
      notifyListeners();
    }
  }

  Future<void> _loadConversationMetadata(
    String conversationId,
    Message message,
  ) async {
    try {
      final conversation = await _repository.getConversation(conversationId);
      _upsertConversation(conversation);
    } catch (_) {
      final fallback = Conversation(
        id: conversationId,
        userId: _participantUserId ?? 'user',
        coachId: _participantCoachId ?? 'coach',
        lastMessageContent: message.content,
        lastMessageAt: message.createdAt,
        unreadCount: 1,
        createdAt: message.createdAt,
        updatedAt: message.createdAt,
      );
      _upsertConversation(fallback);
    }
    notifyListeners();
  }

  Future<void> connectSocket() async {
    if (_demoConfig.isDemo) {
      return;
    }
    await _initializeSocket();
  }

  Future<void> disconnect() async {
    _typingStopTimer?.cancel();
    _typingStopTimer = null;
    _localTypingConversationId = null;
    _typingConversationId = null;

    if (_demoConfig.isDemo) {
      _isConnected = false;
      _isReconnecting = false;
      notifyListeners();
      return;
    }

    _repository.disconnect();
    _socketCallbacksBound = false;
    _isConnected = false;
    _isReconnecting = false;
    _activeConversation = null;
    currentChatId = '';
    _messages = [];
    _messagesByConversation.clear();
    _typingConversationId = null;
    notifyListeners();
  }

  Future<void> reconnect() async {
    if (_demoConfig.isDemo) {
      return;
    }
    _isReconnecting = true;
    notifyListeners();
    await _repository.connect();
  }

  Future<void> loadConversations({
    bool isArabic = false,
    bool isCoach = false,
    String? currentUserId,
    bool autoSelectConversation = true,
  }) async {
    if (currentUserId != null) {
      _currentUserId = currentUserId;
    }

    if (_demoConfig.isDemo) {
      _conversations = await _demoRepository.getConversations(
        demoUserId: DemoConfig.demoUserId,
        demoCoachId: DemoConfig.demoCoachId,
        isArabic: isArabic,
      );
      if (autoSelectConversation && _conversations.isNotEmpty) {
        _activeConversation = _conversations.first;
        currentChatId = _activeConversation?.id ?? '';
        _messages = _activeConversation != null
            ? await _demoRepository.getMessages(
                conversationId: _activeConversation!.id,
                isArabic: isArabic,
              )
            : [];
        if (_activeConversation != null) {
          _messagesByConversation[_activeConversation!.id] =
              List<Message>.from(_messages);
        }
      } else {
        _activeConversation = null;
        currentChatId = '';
        _messages = [];
      }
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final previousActiveConversationId = _activeConversation?.id;
      _conversations = await _repository.getConversations();
      _sortConversationsByActivity();
      if (autoSelectConversation && _conversations.isNotEmpty) {
        final hasPreviousActiveConversation =
            previousActiveConversationId != null &&
                _conversations.any(
                  (conversation) =>
                      conversation.id == previousActiveConversationId,
                );
        final nextConversationId = hasPreviousActiveConversation
            ? previousActiveConversationId
            : _conversations.first.id;
        await loadConversation(nextConversationId, isArabic: isArabic);
      } else {
        _activeConversation = null;
        _messages = [];
        currentChatId = '';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadConversation(
    String conversationId, {
    bool isArabic = false,
  }) async {
    if (_demoConfig.isDemo) {
      final existing = _conversations.firstWhere(
        (conversation) => conversation.id == conversationId,
        orElse: () => Conversation(
          id: conversationId,
          userId: DemoConfig.demoUserId,
          coachId: DemoConfig.demoCoachId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      _activeConversation = existing;
      currentChatId = conversationId;
      _messages = await _demoRepository.getMessages(
        conversationId: conversationId,
        isArabic: isArabic,
      );
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final conversation = await _repository.getConversation(conversationId);
      final messages = _messagesByConversation[conversationId] ??
          _sortMessages(_dedupeMessages(
            await _repository.getMessages(conversationId),
          ));
      _setActiveConversation(conversation);
      _messagesByConversation[conversationId] = List<Message>.from(messages);
      _syncVisibleMessages();
      await markConversationAsRead(conversationId);
      _joinActiveConversation();
    } catch (e) {
      _error = e.toString();
      _activeConversation = null;
      _messages = [];
      _messagesByConversation.clear();
      currentChatId = '';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectConversation(
    String conversationId, {
    bool isArabic = false,
  }) async {
    if (_activeConversation?.id == conversationId && _messages.isNotEmpty) {
      await markConversationAsRead(conversationId);
      _joinActiveConversation();
      return;
    }
    await loadConversation(conversationId, isArabic: isArabic);
  }

  Future<bool> sendMessage(
    String content, {
    MessageType type = MessageType.text,
  }) async {
    if (_demoConfig.isDemo) {
      final message = await _demoRepository.buildOutgoingMessage(
        conversationId: currentChatId.isEmpty ? 'local' : currentChatId,
        senderId: DemoConfig.demoUserId,
        receiverId: DemoConfig.demoCoachId,
        content: content,
        type: type,
      );
      _appendMessageIfMissing(message);
      notifyListeners();
      return true;
    }

    if (_activeConversation == null && _recipientId == null) {
      _error = 'No active conversation';
      notifyListeners();
      return false;
    }

    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      final message = await _repository.sendMessage(
        _activeConversation?.id,
        content,
        recipientId: _recipientId,
        type: type,
      );
      _ensureConversationForMessage(message);
      _appendMessageIfMissing(message);
      _updateConversationFromMessage(message, incrementUnread: false);
      _stopTyping();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessageWithAttachment(
    String content,
    String filePath,
    MessageType type,
  ) async {
    if (_demoConfig.isDemo) {
      final message = await _demoRepository.buildOutgoingMessage(
        conversationId: currentChatId.isEmpty ? 'local' : currentChatId,
        senderId: DemoConfig.demoUserId,
        receiverId: DemoConfig.demoCoachId,
        content: content,
        type: type,
        attachmentUrl: filePath,
        attachmentType: type.name,
      );
      _appendMessageIfMissing(message);
      notifyListeners();
      return true;
    }

    if (_activeConversation == null && _recipientId == null) {
      _error = 'No active conversation';
      notifyListeners();
      return false;
    }

    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      final message = await _repository.sendMessageWithAttachment(
        _activeConversation?.id,
        content,
        filePath,
        recipientId: _recipientId,
        type: type,
      );
      _ensureConversationForMessage(message);
      _appendMessageIfMissing(message);
      _updateConversationFromMessage(message, incrementUnread: false);
      _stopTyping();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  void receiveMessage(Message message) {
    _handleIncomingMessage(message);
  }

  Future<void> markConversationAsRead(String conversationId) async {
    await _markConversationReadAndEmit(conversationId);
    notifyListeners();
  }

  Future<void> _markConversationReadAndEmit(
    String conversationId, {
    String? specificMessageId,
  }) async {
    try {
      await _repository.markConversationAsRead(conversationId);
    } catch (_) {
      // Ignore in offline mode.
    }

    final now = DateTime.now();
    final currentUserId = _currentUserId;
    final unreadIds = <String>{};

    final existingMessages = _messagesByConversation[conversationId] ??
        (_activeConversation?.id == conversationId
            ? _messages
            : const <Message>[]);
    _messagesByConversation[conversationId] = existingMessages.map((message) {
      if (currentUserId != null && message.senderId == currentUserId) {
        return message;
      }
      if (!message.isRead) {
        unreadIds.add(message.id);
      }
      return message.copyWith(isRead: true, readAt: message.readAt ?? now);
    }).toList();
    _syncVisibleMessages();

    if (specificMessageId != null && specificMessageId.isNotEmpty) {
      unreadIds.add(specificMessageId);
    }

    final index = _conversations.indexWhere(
      (conversation) => conversation.id == conversationId,
    );
    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(
        unreadCount: 0,
      );
    }

    for (final messageId in unreadIds) {
      _repository.emitMarkRead(messageId);
    }
  }

  Future<List<Conversation>> getConversations() async {
    if (_demoConfig.isDemo) {
      return [
        await _demoRepository.buildConversation(
          userId: DemoConfig.demoUserId,
          coachId: DemoConfig.demoCoachId,
        ),
      ];
    }

    try {
      return await _repository.getConversations();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  void handleComposerChanged(String value) {
    if (_demoConfig.isDemo) {
      return;
    }

    final conversationId = _activeConversation?.id;
    if (conversationId == null || conversationId.isEmpty) {
      return;
    }

    final text = value.trim();
    if (text.isEmpty) {
      _stopTyping();
      return;
    }

    if (_localTypingConversationId != conversationId) {
      _repository.emitTypingStart(conversationId);
      _localTypingConversationId = conversationId;
    }

    _typingStopTimer?.cancel();
    _typingStopTimer = Timer(const Duration(milliseconds: 900), _stopTyping);
  }

  void _stopTyping() {
    final conversationId = _localTypingConversationId;
    _typingStopTimer?.cancel();
    _typingStopTimer = null;

    if (conversationId == null || conversationId.isEmpty) {
      _localTypingConversationId = null;
      return;
    }

    _repository.emitTypingStop(conversationId);
    _localTypingConversationId = null;
  }

  int getUnreadCount() {
    return _messages.where((message) => !message.isRead).length;
  }

  List<Message> searchMessages(String query) {
    final lowerQuery = query.toLowerCase();
    return _messages
        .where((message) => message.content.toLowerCase().contains(lowerQuery))
        .toList();
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _repository.deleteMessage(messageId);
    } catch (_) {
      // Ignore in offline mode.
    }
    final conversationId = _activeConversation?.id;
    if (conversationId != null) {
      _messagesByConversation[conversationId] =
          (_messagesByConversation[conversationId] ?? _messages)
              .where((message) => message.id != messageId)
              .toList();
    }
    _syncVisibleMessages();
    notifyListeners();
  }

  Future<void> clearChat() async {
    try {
      if (_activeConversation != null) {
        await _repository.deleteConversationMessages(_activeConversation!.id);
      } else if (currentChatId.isNotEmpty) {
        await _repository.deleteConversationMessages(currentChatId);
      }
    } catch (_) {
      // Ignore in offline mode.
    }
    final conversationId = _activeConversation?.id ?? currentChatId;
    if (conversationId.isNotEmpty) {
      _messagesByConversation[conversationId] = [];
    }
    _syncVisibleMessages();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _ensureConversationForMessage(Message message) {
    if (_activeConversation == null && message.conversationId.isNotEmpty) {
      final createdAt = message.createdAt;
      _setActiveConversation(
        Conversation(
          id: message.conversationId,
          userId: _participantUserId ?? 'user',
          coachId: _participantCoachId ?? 'coach',
          lastMessageContent: message.content,
          lastMessageAt: createdAt,
          unreadCount: 0,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );
    }

    if (_activeConversation?.id == message.conversationId) {
      _joinActiveConversation();
    }
  }

  void _setActiveConversation(Conversation conversation) {
    _activeConversation = conversation;
    currentChatId = conversation.id;
    _typingConversationId = null;
    _upsertConversation(conversation);
    _syncVisibleMessages();
  }

  void _joinActiveConversation() {
    final conversationId = _activeConversation?.id ?? currentChatId;
    if (conversationId.isEmpty) {
      return;
    }
    _repository.joinConversation(conversationId);
  }

  bool _appendMessageIfMissing(Message message) {
    final conversationId = message.conversationId;
    final existing =
        _messagesByConversation[conversationId] ?? const <Message>[];
    if (_containsMessage(existing, message)) {
      return false;
    }
    _messagesByConversation[conversationId] =
        _sortMessages([...existing, message]);
    _syncVisibleMessages();
    return true;
  }

  bool _containsMessage(List<Message> existing, Message incoming) {
    return existing.any((message) {
      if (incoming.id.isNotEmpty && message.id == incoming.id) {
        return true;
      }
      return message.conversationId == incoming.conversationId &&
          message.senderId == incoming.senderId &&
          message.content == incoming.content &&
          message.createdAt == incoming.createdAt;
    });
  }

  bool _updateConversationFromMessage(
    Message message, {
    required bool incrementUnread,
  }) {
    final index = _conversations.indexWhere(
      (conversation) => conversation.id == message.conversationId,
    );

    if (index == -1) {
      final fallback = Conversation(
        id: message.conversationId,
        userId: _participantUserId ?? 'user',
        coachId: _participantCoachId ?? 'coach',
        lastMessageContent: message.content,
        lastMessageAt: message.createdAt,
        unreadCount: incrementUnread ? 1 : 0,
        createdAt: message.createdAt,
        updatedAt: message.createdAt,
      );
      _upsertConversation(fallback);
      return true;
    }

    final existing = _conversations.removeAt(index);
    final updated = existing.copyWith(
      lastMessageContent: message.content,
      lastMessageAt: message.createdAt,
      unreadCount:
          incrementUnread ? existing.unreadCount + 1 : existing.unreadCount,
      updatedAt: message.createdAt,
    );
    _conversations.insert(0, updated);

    if (_activeConversation?.id == updated.id) {
      _activeConversation = updated;
    }

    return true;
  }

  void _upsertConversation(Conversation conversation) {
    final index = _conversations.indexWhere(
      (existing) => existing.id == conversation.id,
    );
    if (index != -1) {
      _conversations.removeAt(index);
    }
    _conversations.insert(0, conversation);
    _sortConversationsByActivity();
    if (_activeConversation?.id == conversation.id) {
      _activeConversation = conversation;
    }
  }

  void _sortConversationsByActivity() {
    _conversations.sort((a, b) {
      final aDate = a.lastMessageAt ?? a.updatedAt;
      final bDate = b.lastMessageAt ?? b.updatedAt;
      return bDate.compareTo(aDate);
    });
  }

  List<Message> _dedupeMessages(List<Message> messages) {
    final seen = <String>{};
    final deduped = <Message>[];
    for (final message in messages) {
      final key = message.id.isNotEmpty
          ? message.id
          : '${message.conversationId}|${message.senderId}|${message.createdAt.toIso8601String()}|${message.content}';
      if (seen.add(key)) {
        deduped.add(message);
      }
    }
    return deduped;
  }

  void _syncVisibleMessages() {
    final conversationId = _activeConversation?.id ?? currentChatId;
    if (conversationId.isEmpty) {
      _messages = [];
      return;
    }
    _messages = List<Message>.from(
      _messagesByConversation[conversationId] ?? const <Message>[],
    );
  }

  List<Message> _sortMessages(List<Message> messages) {
    final sorted = [...messages];
    sorted.sort((a, b) {
      final byTime = a.createdAt.compareTo(b.createdAt);
      if (byTime != 0) {
        return byTime;
      }
      return a.id.compareTo(b.id);
    });
    return sorted;
  }

  @override
  void dispose() {
    _typingStopTimer?.cancel();
    disconnect();
    super.dispose();
  }
}
