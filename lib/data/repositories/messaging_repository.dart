import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/message.dart';
import '../../core/config/api_config.dart';

class MessagingRepository {
      /// Deletes all messages in a conversation by its ID.
      Future<void> deleteConversationMessages(String conversationId) async {
        try {
          await _dio.delete(
            '/messages/conversations/$conversationId/messages',
            options: await _getAuthOptions(),
          );
        } on DioException catch (e) {
          throw Exception(e.response?.data['message'] ?? 'Failed to clear messages');
        }
      }
    /// Deletes a message by its ID.
    Future<void> deleteMessage(String messageId) async {
      try {
        await _dio.delete(
          '/messages/$messageId',
          options: await _getAuthOptions(),
        );
      } on DioException catch (e) {
        throw Exception(e.response?.data['message'] ?? 'Failed to delete message');
      }
    }
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  final Future<String?> Function()? _tokenReader;
  IO.Socket? _socket;
  
  static const String _tokenKey = 'fitcoach_auth_token';
  
  MessagingRepository({
    Dio? dio,
    FlutterSecureStorage? secureStorage,
    Future<String?> Function()? tokenReader,
  })
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: ApiConfig.connectTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
            )),
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _tokenReader = tokenReader;
  
  Future<String?> _getToken() async {
    if (_tokenReader != null) {
      return _tokenReader();
    }
    return await _secureStorage.read(key: _tokenKey);
  }
  
  Future<Options> _getAuthOptions() async {
    final token = await _getToken();
    return Options(
      headers: {'Authorization': 'Bearer $token'},
    );
  }
  
  // Connect to Socket.IO
  Future<void> connect() async {
    final token = await _getToken();
    
    _socket = IO.io(ApiConfig.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token},
    });
    
    _socket!.connect();
  }
  
  // Listen for new messages
  void onMessageReceived(Function(Message) callback) {
    _socket?.on('message:new', (data) {
      final message = Message.fromJson(data as Map<String, dynamic>);
      callback(message);
    });
  }
  
  // Disconnect socket
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
  
  // Get conversation
  Future<Conversation> getConversation(String conversationId) async {
    try {
      final response = await _dio.get(
        '/messages/conversations/$conversationId',
        options: await _getAuthOptions(),
      );

      final data = response.data as Map<String, dynamic>;
      if (data['conversation'] is Map<String, dynamic>) {
        return Conversation.fromJson(data['conversation'] as Map<String, dynamic>);
      }
      return Conversation.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load conversation');
    }
  }
  
  // Get all user conversations
  Future<List<Conversation>> getConversations() async {
    try {
      final response = await _dio.get(
        '/messages/conversations',
        options: await _getAuthOptions(),
      );

      final data = response.data as Map<String, dynamic>;
      final list = (data['conversations'] as List?) ?? [];
      return list
          .map((conv) => Conversation.fromJson(conv as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load conversations');
    }
  }
  
  // Get messages for a conversation
  Future<List<Message>> getMessages(String conversationId) async {
    try {
      final response = await _dio.get(
        '/messages/conversations/$conversationId/messages',
        options: await _getAuthOptions(),
      );

      final data = response.data as Map<String, dynamic>;
      final list = (data['messages'] as List?) ?? [];
      return list
          .map((msg) => Message.fromJson(msg as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load messages');
    }
  }
  
  // Send message
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
          if (recipientId != null) 'recipientId': recipientId,
          'content': content,
          'messageType': type.name,
        },
        options: await _getAuthOptions(),
      );

      final data = response.data as Map<String, dynamic>;
      if (data['message'] is Map<String, dynamic>) {
        return Message.fromJson(data['message'] as Map<String, dynamic>);
      }
      return Message.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to send message');
    }
  }
  
  // Send message with attachment (Premium+ only)
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

      final upload = uploadResponse.data as Map<String, dynamic>;
      final attachment = (upload['attachment'] as Map?)?.cast<String, dynamic>();

      if (attachment == null) {
        throw Exception('Attachment upload failed');
      }

      final response = await _dio.post(
        '/messages/send',
        data: {
          if (conversationId != null) 'conversationId': conversationId,
          if (recipientId != null) 'recipientId': recipientId,
          'content': content,
          'messageType': type.name,
          'attachmentUrl': attachment['url'],
          'attachmentType': attachment['type'],
          'attachmentName': attachment['name'],
        },
        options: await _getAuthOptions(),
      );

      final data = response.data as Map<String, dynamic>;
      if (data['message'] is Map<String, dynamic>) {
        return Message.fromJson(data['message'] as Map<String, dynamic>);
      }
      return Message.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to send message');
    }
  }
  
  // Mark conversation messages as read
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      await _dio.patch(
        '/messages/$conversationId/read',
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to mark as read');
    }
  }
}
