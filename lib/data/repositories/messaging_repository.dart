import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/config/api_config.dart';
import '../models/message.dart';

class MessagingRepository {
  MessagingRepository({
    Dio? dio,
    FlutterSecureStorage? secureStorage,
    Future<String?> Function()? tokenReader,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConfig.baseUrl,
                connectTimeout: ApiConfig.connectTimeout,
                receiveTimeout: ApiConfig.receiveTimeout,
                sendTimeout: ApiConfig.sendTimeout,
              ),
            ),
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _tokenReader = tokenReader;

  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  final Future<String?> Function()? _tokenReader;

  io.Socket? _socket;
  bool _listenersRegistered = false;

  final List<void Function(Message)> _messageListeners = [];
  final List<void Function(String, String, DateTime?)> _messageReadListeners =
      [];
  final List<void Function(String, String)> _userTypingListeners = [];
  final List<void Function(String, String)> _userStoppedTypingListeners = [];
  final List<void Function(Map<String, dynamic>)> _notificationListeners = [];
  final List<void Function()> _connectListeners = [];
  final List<void Function(dynamic)> _disconnectListeners = [];
  final List<void Function(dynamic)> _connectErrorListeners = [];
  final List<void Function(dynamic)> _errorListeners = [];
  final List<void Function(dynamic)> _quotaExceededListeners = [];

  static const String _tokenKey = 'fitcoach_auth_token';

  bool get isConnected => _socket?.connected ?? false;

  Future<String?> _getToken() async {
    if (_tokenReader != null) {
      return _tokenReader();
    }
    return _secureStorage.read(key: _tokenKey);
  }

  Future<Options> _getAuthOptions() async {
    final token = await _getToken();
    return Options(
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<void> connect() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Missing auth token');
    }

    if (_socket != null && _socket!.connected) {
      return;
    }

    if (_socket == null) {
      _socket = io.io(
        ApiConfig.socketUrl,
        <String, dynamic>{
          'transports': ['websocket'],
          'autoConnect': false,
          'forceNew': false,
          'reconnection': true,
          'reconnectionAttempts': 999999,
          'reconnectionDelay': 1000,
          'reconnectionDelayMax': 5000,
          'auth': {'token': token},
        },
      );
      _registerSocketListeners();
    } else {
      _socket!.auth = {'token': token};
    }

    if (!_socket!.connected) {
      _socket!.connect();
    }
  }

  void _registerSocketListeners() {
    if (_socket == null || _listenersRegistered) {
      return;
    }

    _listenersRegistered = true;

    _socket!.on('connect', (_) {
      for (final callback in List<void Function()>.from(_connectListeners)) {
        callback();
      }
    });

    _socket!.on('disconnect', (data) {
      final reason = data ?? 'disconnect';
      for (final callback
          in List<void Function(dynamic)>.from(_disconnectListeners)) {
        callback(reason);
      }
    });

    _socket!.on('connect_error', (data) {
      for (final callback
          in List<void Function(dynamic)>.from(_connectErrorListeners)) {
        callback(data ?? 'connect_error');
      }
    });

    _socket!.on('error', (data) {
      for (final callback
          in List<void Function(dynamic)>.from(_errorListeners)) {
        callback(data ?? 'socket_error');
      }
    });

    _socket!.on('message:new', (data) {
      final payload = _unwrapPayload(data);
      if (payload == null) {
        return;
      }
      try {
        final message = Message.fromJson(payload);
        for (final callback
            in List<void Function(Message)>.from(_messageListeners)) {
          callback(message);
        }
      } catch (_) {
        // Ignore malformed socket payloads.
      }
    });

    _socket!.on('message_read', (data) {
      final payload = _unwrapPayload(data);
      if (payload == null) {
        return;
      }
      final messageId = _stringValue(
        payload['messageId'] ?? payload['message_id'] ?? payload['id'],
      );
      final conversationId = _stringValue(
        payload['conversationId'] ?? payload['conversation_id'],
      );
      final readAt = _dateValue(payload['readAt'] ?? payload['read_at']);
      if (messageId.isEmpty) {
        return;
      }
      for (final callback
          in List<void Function(String, String, DateTime?)>.from(
              _messageReadListeners)) {
        callback(messageId, conversationId, readAt);
      }
    });

    _socket!.on('user_typing', (data) {
      final payload = _unwrapPayload(data);
      if (payload == null) {
        return;
      }
      final conversationId = _stringValue(
        payload['conversationId'] ?? payload['conversation_id'],
      );
      final userId = _stringValue(
        payload['userId'] ?? payload['user_id'] ?? payload['senderId'],
      );
      if (conversationId.isEmpty || userId.isEmpty) {
        return;
      }
      for (final callback
          in List<void Function(String, String)>.from(_userTypingListeners)) {
        callback(conversationId, userId);
      }
    });

    _socket!.on('user_stopped_typing', (data) {
      final payload = _unwrapPayload(data);
      if (payload == null) {
        return;
      }
      final conversationId = _stringValue(
        payload['conversationId'] ?? payload['conversation_id'],
      );
      final userId = _stringValue(
        payload['userId'] ?? payload['user_id'] ?? payload['senderId'],
      );
      if (conversationId.isEmpty || userId.isEmpty) {
        return;
      }
      for (final callback in List<void Function(String, String)>.from(
          _userStoppedTypingListeners)) {
        callback(conversationId, userId);
      }
    });

    _socket!.on('notification', (data) {
      final payload = _unwrapPayload(data);
      if (payload == null) {
        return;
      }
      for (final callback in List<void Function(Map<String, dynamic>)>.from(
          _notificationListeners)) {
        callback(payload);
      }
    });

    _socket!.on('quota_exceeded', (data) {
      for (final callback
          in List<void Function(dynamic)>.from(_quotaExceededListeners)) {
        callback(data ?? 'quota_exceeded');
      }
    });
  }

  Map<String, dynamic>? _unwrapPayload(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = _asMap(data['message']) ??
          _asMap(data['payload']) ??
          _asMap(data['data']) ??
          _asMap(data['result']);
      return nested ?? data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  void _addListener<T>(List<T> listeners, T callback) {
    if (!listeners.contains(callback)) {
      listeners.add(callback);
    }
  }

  void onMessageReceived(void Function(Message) callback) {
    _addListener(_messageListeners, callback);
  }

  void onMessageRead(
    void Function(String messageId, String conversationId, DateTime? readAt)
        callback,
  ) {
    _addListener(_messageReadListeners, callback);
  }

  void onUserTyping(
    void Function(String conversationId, String userId) callback,
  ) {
    _addListener(_userTypingListeners, callback);
  }

  void onUserStoppedTyping(
    void Function(String conversationId, String userId) callback,
  ) {
    _addListener(_userStoppedTypingListeners, callback);
  }

  void onNotification(void Function(Map<String, dynamic>) callback) {
    _addListener(_notificationListeners, callback);
  }

  void onConnect(void Function() callback) {
    _addListener(_connectListeners, callback);
  }

  void onDisconnect(void Function(dynamic reason) callback) {
    _addListener(_disconnectListeners, callback);
  }

  void onConnectError(void Function(dynamic error) callback) {
    _addListener(_connectErrorListeners, callback);
  }

  void onError(void Function(dynamic error) callback) {
    _addListener(_errorListeners, callback);
  }

  void onQuotaExceeded(void Function(dynamic error) callback) {
    _addListener(_quotaExceededListeners, callback);
  }

  void joinConversation(String conversationId) {
    if (conversationId.isEmpty) {
      return;
    }
    _socket?.emit('join_conversation', {'conversationId': conversationId});
  }

  void emitTypingStart(String conversationId) {
    if (conversationId.isEmpty) {
      return;
    }
    _socket?.emit('typing_start', {'conversationId': conversationId});
  }

  void emitTypingStop(String conversationId) {
    if (conversationId.isEmpty) {
      return;
    }
    _socket?.emit('typing_stop', {'conversationId': conversationId});
  }

  void emitMarkRead(String messageId) {
    if (messageId.isEmpty) {
      return;
    }
    _socket?.emit('mark_read', {'messageId': messageId});
  }

  void disconnect() {
    _socket?.clearListeners();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _listenersRegistered = false;
    _messageListeners.clear();
    _messageReadListeners.clear();
    _userTypingListeners.clear();
    _userStoppedTypingListeners.clear();
    _notificationListeners.clear();
    _connectListeners.clear();
    _disconnectListeners.clear();
    _connectErrorListeners.clear();
    _errorListeners.clear();
    _quotaExceededListeners.clear();
  }

  Future<Conversation> getConversation(String conversationId) async {
    try {
      final response = await _dio.get(
        '/messages/conversations/$conversationId',
        options: await _getAuthOptions(),
      );

      final data = _asMap(response.data) ?? const <String, dynamic>{};
      final conversation = _asMap(data['conversation']) ??
          _asMap(data['data']) ??
          _asMap(data['result']) ??
          data;
      return Conversation.fromJson(conversation);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Failed to load conversation'));
    }
  }

  Future<List<Conversation>> getConversations() async {
    try {
      final response = await _dio.get(
        '/messages/conversations',
        options: await _getAuthOptions(),
      );

      final data = _asMap(response.data) ?? const <String, dynamic>{};
      final list = (data['conversations'] as List?) ??
          (data['data'] as List?) ??
          (data['results'] as List?) ??
          const [];
      return list
          .whereType<Map>()
          .map((conv) => Conversation.fromJson(Map<String, dynamic>.from(conv)))
          .toList();
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Failed to load conversations'));
    }
  }

  Future<List<Message>> getMessages(String conversationId) async {
    try {
      final response = await _dio.get(
        '/messages/conversations/$conversationId/messages',
        options: await _getAuthOptions(),
      );

      final data = _asMap(response.data) ?? const <String, dynamic>{};
      final list = (data['messages'] as List?) ??
          (data['data'] as List?) ??
          (data['results'] as List?) ??
          const [];
      return list
          .whereType<Map>()
          .map((msg) => Message.fromJson(Map<String, dynamic>.from(msg)))
          .toList();
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Failed to load messages'));
    }
  }

  Future<Message> sendMessage(
    String? conversationId,
    String content, {
    String? recipientId,
    MessageType type = MessageType.text,
  }) async {
    try {
      if (conversationId == null && recipientId == null) {
        throw Exception('Conversation ID or recipient ID is required');
      }

      final response = await _dio.post(
        '/messages/send',
        data: {
          if (conversationId != null) 'conversationId': conversationId,
          if (conversationId == null && recipientId != null)
            'recipientId': recipientId,
          'content': content,
          'messageType': type.name,
        },
        options: await _getAuthOptions(),
      );

      final data = _asMap(response.data) ?? const <String, dynamic>{};
      final message = _asMap(data['message']) ??
          _asMap(data['data']) ??
          _asMap(data['result']) ??
          data;
      return Message.fromJson(message);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Failed to send message'));
    }
  }

  Future<Message> sendMessageWithAttachment(
    String? conversationId,
    String content,
    String filePath, {
    String? recipientId,
    MessageType type = MessageType.image,
  }) async {
    try {
      if (conversationId == null && recipientId == null) {
        throw Exception('Conversation ID or recipient ID is required');
      }

      final uploadData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final uploadResponse = await _dio.post(
        '/messages/upload',
        data: uploadData,
        options: await _getAuthOptions(),
      );

      final upload = _asMap(uploadResponse.data) ?? const <String, dynamic>{};
      final attachment = _asMap(upload['attachment']) ?? upload;
      final attachmentUrl = (attachment['url'] ??
              attachment['attachmentUrl'] ??
              attachment['fileUrl'])
          ?.toString();
      final attachmentType =
          (attachment['type'] ?? attachment['attachmentType'] ?? type.name)
              .toString();
      final attachmentName = (attachment['name'] ??
              attachment['attachmentName'] ??
              attachment['fileName'])
          ?.toString();

      if (attachmentUrl == null || attachmentUrl.isEmpty) {
        throw Exception('Attachment upload failed');
      }

      final response = await _dio.post(
        '/messages/send',
        data: {
          if (conversationId != null) 'conversationId': conversationId,
          if (conversationId == null && recipientId != null)
            'recipientId': recipientId,
          'content': content,
          'messageType': type.name,
          'attachmentUrl': attachmentUrl,
          'attachmentType': attachmentType,
          if (attachmentName != null && attachmentName.isNotEmpty)
            'attachmentName': attachmentName,
        },
        options: await _getAuthOptions(),
      );

      final data = _asMap(response.data) ?? const <String, dynamic>{};
      final message = _asMap(data['message']) ??
          _asMap(data['data']) ??
          _asMap(data['result']) ??
          data;
      return Message.fromJson(message);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Failed to send message with attachment'),
      );
    }
  }

  Future<void> markConversationAsRead(String conversationId) async {
    try {
      await _dio.patch(
        '/messages/$conversationId/read',
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Failed to mark as read'));
    }
  }

  Future<void> deleteConversationMessages(String conversationId) async {
    try {
      await _dio.delete(
        '/messages/conversations/$conversationId/messages',
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Failed to clear messages'));
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _dio.delete(
        '/messages/$messageId',
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Failed to delete message'));
    }
  }

  String _extractErrorMessage(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    } else if (data is String && data.isNotEmpty) {
      return data;
    }
    return fallback;
  }
}

String _stringValue(dynamic value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

DateTime? _dateValue(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  return DateTime.tryParse(value.toString());
}
