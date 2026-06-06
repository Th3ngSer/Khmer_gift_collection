import 'package:flutter_riverpod/flutter_riverpod.dart';

// Model for a chat message
class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String messageText;
  final DateTime sentAt;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.messageText,
    required this.sentAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'room_id': roomId,
      'sender_id': senderId,
      'message_text': messageText,
      'sent_at': sentAt.toIso8601String(),
    };
  }
}

// Modern Notifier to manage chat messages
class ChatNotifier extends Notifier<Map<String, List<ChatMessage>>> {
  @override
  Map<String, List<ChatMessage>> build() {
    return {
      'room_Sophea Silk': [
        ChatMessage(
          id: '1',
          roomId: 'room_Sophea Silk',
          senderId: 'artisan_1',
          messageText: 'សួស្តី! (Hello!) How can I help you today?',
          sentAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      ],
      'room_Kiri Woodwork': [
        ChatMessage(
          id: '2',
          roomId: 'room_Kiri Woodwork',
          senderId: 'artisan_2',
          messageText: 'Yes, I can customize the wood grain for you.',
          sentAt: DateTime.now().subtract(const Duration(minutes: 25)),
        ),
      ],
    };
  }

  void addMessage(String roomId, String senderId, String text) {
    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: roomId,
      senderId: senderId,
      messageText: text,
      sentAt: DateTime.now(),
    );

    final currentMessages = state[roomId] ?? [];
    state = {
      ...state,
      roomId: [...currentMessages, newMessage],
    };

    // Auto-reply logic for mock demonstration
    if (senderId == 'user_123') {
      Future.delayed(const Duration(seconds: 1), () {
        _receiveAutoReply(roomId);
      });
    }
  }

  void _receiveAutoReply(String roomId) {
    final replies = [
      'That sounds great!',
      'Let me check that for you.',
      'I will be ready with the update soon.',
      'Would you like to see more designs?',
      'ជំរាបសួរ (Hello), thank you for reaching out!',
    ];
    
    final randomReply = replies[DateTime.now().second % replies.length];
    
    final replyMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: roomId,
      senderId: 'artisan_reply',
      messageText: randomReply,
      sentAt: DateTime.now(),
    );

    final currentMessages = state[roomId] ?? [];
    state = {
      ...state,
      roomId: [...currentMessages, replyMsg],
    };
  }
}

// The provider that stores all chat history in-memory
final chatProvider = NotifierProvider<ChatNotifier, Map<String, List<ChatMessage>>>(() {
  return ChatNotifier();
});

// Selector provider for chat messages by roomId
final chatMessagesStreamProvider = Provider.family<List<Map<String, dynamic>>, String>((ref, roomId) {
  final allChats = ref.watch(chatProvider);
  final messages = allChats[roomId] ?? [];
  return messages.map((m) => m.toMap()).toList();
});

// Mock sendMessage function that updates the provider
Future<void> sendMessage({required String roomId, required String senderId, required String text, required WidgetRef ref}) async {
  if (text.trim().isEmpty) return;
  ref.read(chatProvider.notifier).addMessage(roomId, senderId, text);
}
