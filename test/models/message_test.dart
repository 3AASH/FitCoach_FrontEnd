import 'package:flutter_test/flutter_test.dart';
import 'package:fitapp/data/models/message.dart';
// Ensure the Message class is defined in the imported file and the import path is correct.

void main() {
  group('Message Model Tests', () {
    test('should create Message from JSON', () {
      final json = {
        'id': 'msg_123',
        'conversationId': 'conv_456',
        'senderId': 'user_789',
        'receiverId': 'coach_012',
        'content': 'Hello coach!',
        'type': 'text',
        'attachmentUrl': null,
        'attachmentType': null,
        'isRead': false,
        'createdAt': '2024-01-15T10:30:00.000Z',
        'readAt': null,
      };

      final message = Message.fromJson(json);

      expect(message.id, 'msg_123');
      expect(message.conversationId, 'conv_456');
      expect(message.senderId, 'user_789');
      expect(message.receiverId, 'coach_012');
      expect(message.content, 'Hello coach!');
      expect(message.type, MessageType.text);
      expect(message.attachmentUrl, isNull);
      expect(message.isRead, false);
      expect(message.createdAt.year, 2024);
      expect(message.readAt, isNull);
    });

    test('should create Message with image attachment from JSON', () {
      final json = {
        'id': 'msg_123',
        'conversationId': 'conv_456',
        'senderId': 'user_789',
        'receiverId': 'coach_012',
        'content': 'Check my progress photo',
        'type': 'image',
        'attachmentUrl': 'https://example.com/photo.jpg',
        'attachmentType': 'image/jpeg',
        'isRead': true,
        'createdAt': '2024-01-15T10:30:00.000Z',
        'readAt': '2024-01-15T10:32:00.000Z',
      };

      final message = Message.fromJson(json);

      expect(message.type, MessageType.image);
      expect(message.attachmentUrl, 'https://example.com/photo.jpg');
      expect(message.attachmentType, 'image/jpeg');
      expect(message.isRead, true);
      expect(message.readAt, isNotNull);
    });

    test('should convert Message to JSON', () {
      final message = Message(
        id: 'msg_1',
        conversationId: 'conv_1',
        senderId: 'user_1',
        receiverId: 'coach_1',
        content: 'Test message',
        type: MessageType.text,
        isRead: false,
        createdAt: DateTime(2024, 1, 15, 10, 30),
      );

      final json = message.toJson();

      expect(json['id'], 'msg_1');
      expect(json['content'], 'Test message');
      expect(json['type'], 'text');
      expect(json['isRead'], false);
      expect(json['createdAt'], contains('2024-01-15'));
      expect(json['readAt'], isNull);
    });

    test('should handle all MessageType enums', () {
      final types = [
        {'type': 'text', 'expected': MessageType.text},
        {'type': 'image', 'expected': MessageType.image},
        {'type': 'video', 'expected': MessageType.video},
        {'type': 'audio', 'expected': MessageType.audio},
        {'type': 'file', 'expected': MessageType.file},
      ];

      for (var typeData in types) {
        final json = {
          'id': 'msg_1',
          'conversationId': 'conv_1',
          'senderId': 'user_1',
          'receiverId': 'coach_1',
          'content': 'Test',
          'type': typeData['type'],
          'createdAt': '2024-01-15T10:30:00.000Z',
        };

        final message = Message.fromJson(json);
        expect(message.type, typeData['expected']);
      }
    });

    test('should default to text type for unknown type', () {
      final json = {
        'id': 'msg_1',
        'conversationId': 'conv_1',
        'senderId': 'user_1',
        'receiverId': 'coach_1',
        'content': 'Test',
        'type': 'unknown_type',
        'createdAt': '2024-01-15T10:30:00.000Z',
      };

      final message = Message.fromJson(json);
      expect(message.type, MessageType.text);
    });

    test('should handle default values', () {
      final json = {
        'id': 'msg_1',
        'conversationId': 'conv_1',
        'senderId': 'user_1',
        'receiverId': 'coach_1',
        'content': 'Test',
        'createdAt': '2024-01-15T10:30:00.000Z',
      };

      final message = Message.fromJson(json);

      expect(message.type, MessageType.text); // default
      expect(message.isRead, false); // default
      expect(message.attachmentUrl, isNull);
      expect(message.attachmentType, isNull);
      expect(message.readAt, isNull);
    });

    test('should serialize and deserialize correctly', () {
      final original = Message(
        id: 'msg_1',
        conversationId: 'conv_1',
        senderId: 'user_1',
        receiverId: 'coach_1',
        content: 'Round trip test',
        type: MessageType.video,
        attachmentUrl: 'https://example.com/video.mp4',
        attachmentType: 'video/mp4',
        isRead: true,
        createdAt: DateTime(2024, 1, 15, 10, 30),
        readAt: DateTime(2024, 1, 15, 10, 35),
      );

      final json = original.toJson();
      final restored = Message.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.content, original.content);
      expect(restored.type, original.type);
      expect(restored.attachmentUrl, original.attachmentUrl);
      expect(restored.isRead, original.isRead);
      expect(restored.createdAt.toIso8601String(), 
             original.createdAt.toIso8601String());
    });
  });

  group('Conversation Model Tests', () {
    test('should create Conversation from JSON', () {
      final json = {
        'id': 'conv_123',
        'userId': 'user_456',
        'coachId': 'coach_789',
        'lastMessageContent': 'Thanks for the tips!',
        'lastMessageAt': '2024-01-15T14:30:00.000Z',
        'unreadCount': 3,
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-15T14:30:00.000Z',
      };

      final conversation = Conversation.fromJson(json);

      expect(conversation.id, 'conv_123');
      expect(conversation.userId, 'user_456');
      expect(conversation.coachId, 'coach_789');
      expect(conversation.lastMessageContent, 'Thanks for the tips!');
      expect(conversation.lastMessageAt, isNotNull);
      expect(conversation.unreadCount, 3);
      expect(conversation.createdAt.year, 2024);
    });

    test('should convert Conversation to JSON', () {
      final conversation = Conversation(
        id: 'conv_1',
        userId: 'user_1',
        coachId: 'coach_1',
        lastMessageContent: 'See you tomorrow',
        lastMessageAt: DateTime(2024, 1, 15, 16, 0),
        unreadCount: 1,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 15),
      );

      final json = conversation.toJson();

      expect(json['id'], 'conv_1');
      expect(json['userId'], 'user_1');
      expect(json['lastMessageContent'], 'See you tomorrow');
      expect(json['unreadCount'], 1);
      expect(json['createdAt'], contains('2024-01-01'));
    });

    test('should handle null optional fields', () {
      final json = {
        'id': 'conv_1',
        'userId': 'user_1',
        'coachId': 'coach_1',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
      };

      final conversation = Conversation.fromJson(json);

      expect(conversation.lastMessageContent, isNull);
      expect(conversation.lastMessageAt, isNull);
      expect(conversation.unreadCount, 0); // default
    });

    test('should handle default unreadCount', () {
      final json1 = {
        'id': 'conv_1',
        'userId': 'user_1',
        'coachId': 'coach_1',
        'unreadCount': 0,
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
      };

      final json2 = {
        'id': 'conv_2',
        'userId': 'user_2',
        'coachId': 'coach_2',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
      };

      final conv1 = Conversation.fromJson(json1);
      final conv2 = Conversation.fromJson(json2);

      expect(conv1.unreadCount, 0);
      expect(conv2.unreadCount, 0); // default
    });

    test('should serialize and deserialize correctly', () {
      final original = Conversation(
        id: 'conv_1',
        userId: 'user_1',
        coachId: 'coach_1',
        lastMessageContent: 'Last message',
        lastMessageAt: DateTime(2024, 1, 15, 10, 0),
        unreadCount: 5,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 15),
      );

      final json = original.toJson();
      final restored = Conversation.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.coachId, original.coachId);
      expect(restored.lastMessageContent, original.lastMessageContent);
      expect(restored.unreadCount, original.unreadCount);
      expect(restored.createdAt.toIso8601String(), 
             original.createdAt.toIso8601String());
    });
  });

  group('MessageType Enum Tests', () {
    test('should have all expected message types', () {
      expect(MessageType.values.length, 5);
      expect(MessageType.values.contains(MessageType.text), true);
      expect(MessageType.values.contains(MessageType.image), true);
      expect(MessageType.values.contains(MessageType.video), true);
      expect(MessageType.values.contains(MessageType.audio), true);
      expect(MessageType.values.contains(MessageType.file), true);
    });

    test('should convert enum to string name correctly', () {
      expect(MessageType.text.name, 'text');
      expect(MessageType.image.name, 'image');
      expect(MessageType.video.name, 'video');
      expect(MessageType.audio.name, 'audio');
      expect(MessageType.file.name, 'file');
    });
  });
}
