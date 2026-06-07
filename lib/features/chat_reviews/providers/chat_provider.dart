import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// Stream provider that listens to real-time chat updates
final chatMessagesStreamProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, roomId) {
  return supabase
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('room_id', roomId)
      .order('sent_at', ascending: true); // Orders chat logs chronologically
});

// Function to send a message to Supabase
Future<void> sendMessage({required String roomId, required String senderId, required String text}) async {
  if (text.trim().isEmpty) return;

  await supabase.from('messages').insert({
    'room_id': roomId,
    'sender_id': senderId,
    'message_text': text,
  });
}