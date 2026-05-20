class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final String? attachmentUrl;
  final String? attachmentType;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  String get status {
    if (isRead || readAt != null) {
      return 'read';
    }
    return 'sent';
  }

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.type = MessageType.text,
    this.attachmentUrl,
    this.attachmentType,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    String? attachmentUrl,
    String? attachmentType,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentType: attachmentType ?? this.attachmentType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    final conversationId =
        json['conversationId'] ?? json['conversation_id'] ?? json['chatId'];
    final senderId = json['senderId'] ??
        json['sender_id'] ??
        json['fromUserId'] ??
        json['from_user_id'];
    final receiverId = json['receiverId'] ??
        json['receiver_id'] ??
        json['toUserId'] ??
        json['to_user_id'];
    final content = json['content'] ?? json['text'] ?? '';
    final typeValue =
        json['type'] ?? json['messageType'] ?? json['message_type'];
    final attachmentUrl = json['attachmentUrl'] ??
        json['attachment_url'] ??
        json['fileUrl'] ??
        json['file_url'];
    final attachmentType =
        json['attachmentType'] ?? json['attachment_type'] ?? json['fileType'];
    final isReadValue = json['isRead'] ?? json['is_read'] ?? json['read'];
    final createdAtValue = json['createdAt'] ??
        json['created_at'] ??
        json['sentAt'] ??
        json['sent_at'];
    final readAtValue = json['readAt'] ?? json['read_at'];

    return Message(
      id: _stringValue(json['id'] ?? json['_id'] ?? json['messageId']),
      conversationId: _stringValue(conversationId),
      senderId: _stringValue(senderId),
      receiverId: _stringValue(receiverId),
      content: _stringValue(content),
      type: MessageTypeX.fromValue(typeValue),
      attachmentUrl: _nullableStringValue(attachmentUrl),
      attachmentType: _nullableStringValue(attachmentType),
      isRead: _boolValue(isReadValue),
      createdAt: _dateValue(createdAtValue),
      readAt: _nullableDateValue(readAtValue),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.name,
      'attachmentUrl': attachmentUrl,
      'attachmentType': attachmentType,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }
}

enum MessageType {
  text,
  image,
  video,
  audio,
  file,
}

extension MessageTypeX on MessageType {
  static MessageType fromValue(dynamic value) {
    final normalized = value?.toString().trim().toLowerCase();
    for (final type in MessageType.values) {
      if (type.name == normalized) {
        return type;
      }
    }
    return MessageType.text;
  }
}

class Conversation {
  final String id;
  final String userId;
  final String coachId;
  final String? lastMessageContent;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.userId,
    required this.coachId,
    this.lastMessageContent,
    this.lastMessageAt,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Conversation copyWith({
    String? id,
    String? userId,
    String? coachId,
    String? lastMessageContent,
    DateTime? lastMessageAt,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      coachId: coachId ?? this.coachId,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final userId = json['userId'] ?? json['user_id'] ?? json['clientId'];
    final coachId = json['coachId'] ?? json['coach_id'];
    final lastMessageContent = json['lastMessageContent'] ??
        json['last_message_preview'] ??
        json['lastMessage'] ??
        json['last_message'];
    final lastMessageAt = json['lastMessageAt'] ??
        json['last_message_at'] ??
        json['lastActivityAt'] ??
        json['updatedAt'] ??
        json['updated_at'];
    final unreadCount = json['unreadCount'] ?? json['unread_count'];
    final createdAt =
        json['createdAt'] ?? json['created_at'] ?? json['updatedAt'];
    final updatedAt =
        json['updatedAt'] ?? json['updated_at'] ?? json['created_at'];

    return Conversation(
      id: _stringValue(json['id'] ?? json['_id'] ?? json['conversationId']),
      userId: _stringValue(userId),
      coachId: _stringValue(coachId),
      lastMessageContent: _nullableStringValue(lastMessageContent),
      lastMessageAt: _nullableDateValue(lastMessageAt),
      unreadCount: _intValue(unreadCount),
      createdAt: _dateValue(createdAt),
      updatedAt: _dateValue(updatedAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'coachId': coachId,
      'lastMessageContent': lastMessageContent,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

String _stringValue(dynamic value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

String? _nullableStringValue(dynamic value) {
  final text = _stringValue(value);
  return text.isEmpty ? null : text;
}

bool _boolValue(dynamic value) {
  if (value is bool) {
    return value;
  }
  final normalized = value?.toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1';
}

int _intValue(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime _dateValue(dynamic value) {
  return _nullableDateValue(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _nullableDateValue(dynamic value) {
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
