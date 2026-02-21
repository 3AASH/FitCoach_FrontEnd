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

  /// Returns the status for UI: 'read', 'delivered', or 'sent'.
  String get status {
    if (isRead || readAt != null) {
      return 'read';
    }
    // You can add more logic here for 'delivered' if you track delivery.
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
  
  factory Message.fromJson(Map<String, dynamic> json) {
    final conversationId = json['conversationId'] ?? json['conversation_id'];
    final senderId = json['senderId'] ?? json['sender_id'];
    final receiverId = json['receiverId'] ?? json['receiver_id'];
    final content = json['content'];
    final typeValue = json['type'] ?? json['messageType'] ?? json['message_type'];
    final attachmentUrl = json['attachmentUrl'] ?? json['attachment_url'];
    final attachmentType = json['attachmentType'] ?? json['attachment_type'];
    final isReadValue = json['isRead'] ?? json['is_read'];
    final createdAtValue = json['createdAt'] ?? json['created_at'];
    final readAtValue = json['readAt'] ?? json['read_at'];

    return Message(
      id: json['id'] as String,
      conversationId: conversationId as String,
      senderId: senderId as String,
      receiverId: receiverId as String? ?? '',
      content: content as String? ?? '',
      type: MessageType.values.firstWhere(
        (type) => type.name == typeValue,
        orElse: () => MessageType.text,
      ),
      attachmentUrl: attachmentUrl as String?,
      attachmentType: attachmentType as String?,
      isRead: isReadValue as bool? ?? false,
      createdAt: DateTime.parse(createdAtValue as String),
      readAt: readAtValue != null
          ? DateTime.parse(readAtValue as String)
          : null,
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
  
  factory Conversation.fromJson(Map<String, dynamic> json) {
    final userId = json['userId'] ?? json['user_id'];
    final coachId = json['coachId'] ?? json['coach_id'];
    final lastMessageContent = json['lastMessageContent'] ?? json['last_message_preview'];
    final lastMessageAt = json['lastMessageAt'] ?? json['last_message_at'];
    final unreadCount = json['unreadCount'] ?? json['unread_count'];
    final createdAt = json['createdAt'] ?? json['created_at'];
    final updatedAt = json['updatedAt'] ?? json['updated_at'] ?? json['created_at'];

    return Conversation(
      id: json['id'] as String,
      userId: userId as String,
      coachId: coachId as String,
      lastMessageContent: lastMessageContent as String?,
      lastMessageAt: lastMessageAt != null
          ? DateTime.parse(lastMessageAt as String)
          : null,
      unreadCount: unreadCount as int? ?? 0,
      createdAt: DateTime.parse(createdAt as String),
      updatedAt: DateTime.parse(updatedAt as String),
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
