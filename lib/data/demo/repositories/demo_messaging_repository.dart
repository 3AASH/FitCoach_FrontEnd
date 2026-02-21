import '../../models/message.dart';
import '../../models/coach_client.dart';
import '../demo_data.dart';

class DemoMessagingRepository {
  Future<Conversation> buildConversation({
    required String userId,
    required String coachId,
    bool isArabic = false,
  }) async {
    return DemoData.demoConversation(
      userId: userId,
      coachId: coachId,
      isArabic: isArabic,
    );
  }

  Future<List<Message>> getMessages({
    required String conversationId,
    bool isArabic = false,
  }) async {
    return DemoData.chatMessages(
      conversationId: conversationId,
      isArabic: isArabic,
    );
  }

  Future<List<Conversation>> getConversations({
    required String demoUserId,
    required String demoCoachId,
    bool isArabic = false,
    bool isCoach = false,
  }) async {
    if (!isCoach) {
      return [
        DemoData.demoConversation(
          userId: demoUserId,
          coachId: demoCoachId,
          isArabic: isArabic,
        ),
      ];
    }
    final List<CoachClient> clients = DemoData.coachClients();
    if (clients.isEmpty) {
      final conversation = DemoData.demoConversation(
        userId: demoUserId,
        coachId: demoCoachId,
        isArabic: isArabic,
      );
      return [conversation];
    }

    return clients.asMap().entries.map((entry) {
      final client = entry.value;
      final base = DemoData.demoConversation(
        userId: client.id,
        coachId: demoCoachId,
        isArabic: isArabic,
      );
      final offsetMinutes = entry.key * 9;
      return Conversation(
        id: base.id,
        userId: client.id,
        coachId: base.coachId,
        lastMessageContent: base.lastMessageContent ??
            (isArabic
                ? 'Ready for the next check-in?'
                : 'Ready for the next check-in?'),
        lastMessageAt: base.lastMessageAt?.subtract(
              Duration(minutes: offsetMinutes),
            ) ??
            DateTime.now().subtract(Duration(minutes: offsetMinutes + 4)),
        unreadCount: entry.key == 0 ? 2 : 0,
        createdAt: base.createdAt,
        updatedAt: base.updatedAt.subtract(Duration(minutes: offsetMinutes)),
      );
    }).toList();
  }

  Future<Message> buildOutgoingMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
    String? attachmentUrl,
    String? attachmentType,
  }) async {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      type: type,
      attachmentUrl: attachmentUrl,
      attachmentType: attachmentType,
      isRead: false,
      createdAt: DateTime.now(),
    );
  }
}
