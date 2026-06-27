import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/providers/home_provider.dart';

// Model for a chat message
class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String messageText;
  final DateTime sentAt;
  final Map<String, dynamic>? recommendedProduct;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.messageText,
    required this.sentAt,
    this.recommendedProduct,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'room_id': roomId,
      'sender_id': senderId,
      'message_text': messageText,
      'sent_at': sentAt.toIso8601String(),
      'recommendedProduct': recommendedProduct,
    };
  }
}

class ChatRoomInfo {
  final String id;
  final String name;
  final String avatar;
  final String badge;
  final bool isSupport;

  ChatRoomInfo({
    required this.id,
    required this.name,
    required this.avatar,
    this.badge = '',
    this.isSupport = false,
  });
}

class ChatState {
  final Map<String, ChatRoomInfo> rooms;
  final Map<String, List<ChatMessage>> messages;

  ChatState({required this.rooms, required this.messages});

  ChatState copyWith({
    Map<String, ChatRoomInfo>? rooms,
    Map<String, List<ChatMessage>>? messages,
  }) {
    return ChatState(
      rooms: rooms ?? this.rooms,
      messages: messages ?? this.messages,
    );
  }
}

// Notifier to manage chat messages and rooms
class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() {
    final supportRooms = {
      'room_Gift Specialist': ChatRoomInfo(
        id: 'room_Gift Specialist',
        name: 'Gift Specialist',
        avatar: 'https://i.pravatar.cc/150?u=support1',
        badge: 'CURATOR',
        isSupport: true,
      ),
      'room_Heritage Curator': ChatRoomInfo(
        id: 'room_Heritage Curator',
        name: 'Heritage Curator',
        avatar: 'https://i.pravatar.cc/150?u=support2',
        badge: 'STORYTELLER',
        isSupport: true,
      ),
      'room_Order Support': ChatRoomInfo(
        id: 'room_Order Support',
        name: 'Order Support',
        avatar: 'https://i.pravatar.cc/150?u=support3',
        badge: 'SERVICE',
        isSupport: true,
      ),
    };

    final initialMessages = {
      'room_Gift Specialist': [
        ChatMessage(
          id: '1',
          roomId: 'room_Gift Specialist',
          senderId: 'support_1',
          messageText: 'សួស្តី! (Hello!) I am your Gift Specialist. Need help finding the perfect traditional gift?',
          sentAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ],
      'room_Heritage Curator': [
        ChatMessage(
          id: '2',
          roomId: 'room_Heritage Curator',
          senderId: 'support_2',
          messageText: 'Welcome! I can tell you the stories behind each artisan piece. Which craft interests you?',
          sentAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ],
      'room_Order Support': [
        ChatMessage(
          id: '3',
          roomId: 'room_Order Support',
          senderId: 'support_3',
          messageText: 'Hi there, I can help you with your order status or shipping details.',
          sentAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
    };

    return ChatState(rooms: supportRooms, messages: initialMessages);
  }

  void initiateChat(String roomId, String name, String avatar) {
    if (!state.rooms.containsKey(roomId)) {
      final newRoom = ChatRoomInfo(
        id: roomId,
        name: name,
        avatar: avatar,
        isSupport: false,
      );
      state = state.copyWith(
        rooms: {...state.rooms, roomId: newRoom},
        messages: {...state.messages, roomId: <ChatMessage>[]},
      );
    }
  }

  void addMessage(String roomId, String senderId, String text) {
    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: roomId,
      senderId: senderId,
      messageText: text,
      sentAt: DateTime.now(),
    );

    final roomMessages = <ChatMessage>[...(state.messages[roomId] ?? []), newMessage];
    state = state.copyWith(
      messages: {...state.messages, roomId: roomMessages},
    );

    // Auto-reply logic
    if (senderId == 'user_123') {
      Future.delayed(const Duration(seconds: 1), () => _receiveReply(roomId, text));
    }
  }

  void _receiveReply(String roomId, String userText) {
    final room = state.rooms[roomId];
    if (room == null) return;

    String replyText = "I'm here to help! Tell me more about what you're looking for.";
    Map<String, dynamic>? recommendation;

    if (room.isSupport) {
      // Support recommendation logic
      final homeData = ref.read(homeFeedProvider).value;
      final List<dynamic> allProducts = homeData?.items ?? [];
      final query = userText.toLowerCase();
      
      if (query.contains('silk') || query.contains('gift')) {
        final match = allProducts.firstWhere(
          (p) => p['name'].toString().toLowerCase().contains('silk') || 
                 p['category'].toString().toLowerCase().contains('silk'),
          orElse: () => allProducts.isNotEmpty ? allProducts.first : null,
        );

        if (match != null) {
          replyText = "Based on your interest, I highly recommend our ${match['name']}. It's a masterpiece of Khmer heritage!";
          recommendation = {
            'id': match['id'],
            'name': match['name'],
            'price': match['price'],
            'image': match['cover'] ?? match['image'],
          };
        }
      } else if (query.contains('help')) {
        replyText = "Of course! Are you looking for a wedding gift or something for a corporate event?";
      }
    } else {
      // Artisan auto-reply logic
      replyText = "ជំរាបសួរ (Hello)! Thank you for your inquiry about my craft. I will get back to you with more details very soon!";
    }

    final replyMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: roomId,
      senderId: room.isSupport ? 'support_reply' : 'artisan_reply',
      messageText: replyText,
      sentAt: DateTime.now(),
      recommendedProduct: recommendation,
    );

    final roomMessages = <ChatMessage>[...(state.messages[roomId] ?? []), replyMsg];
    state = state.copyWith(
      messages: {...state.messages, roomId: roomMessages},
    );
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(() {
  return ChatNotifier();
});

// A provider that listens to messages for a specific room
final chatRoomMessagesProvider = Provider.family<List<ChatMessage>, String>((ref, roomId) {
  final chatState = ref.watch(chatProvider);
  return chatState.messages[roomId] ?? [];
});

// A provider for the last message in each room (to update the Chat List)
final lastMessageProvider = Provider.family<ChatMessage?, String>((ref, roomId) {
  final messages = ref.watch(chatRoomMessagesProvider(roomId));
  return messages.isNotEmpty ? messages.last : null;
});

final allChatRoomsProvider = Provider<List<ChatRoomInfo>>((ref) {
  final chatState = ref.watch(chatProvider);
  return chatState.rooms.values.toList();
});
