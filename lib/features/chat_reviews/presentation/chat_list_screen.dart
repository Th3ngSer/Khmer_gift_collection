import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);
    const clayColor = Color(0xFF8B4513);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 3, // Mock data for now
        separatorBuilder: (context, index) => const Divider(height: 32),
        itemBuilder: (context, index) {
          final names = ['Sophea Silk', 'Kiri Woodwork', 'Arun Sculpture'];
          final messages = [
            'How is the progress on my silk scarf?',
            'Yes, I can customize the wood grain for you.',
            'The stone carving will be ready next week!'
          ];
          
          return ListTile(
            onTap: () {
              context.push(
                '/chat-room/room_$index',
                extra: {
                  'currentUserId': 'user_123', // Replace with real user ID
                  'artisanName': names[index],
                },
              );
            },
            contentPadding: EdgeInsets.zero,
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: goldColor.withOpacity(0.1),
                  child: Text(names[index][0], style: const TextStyle(color: clayColor, fontWeight: FontWeight.bold)),
                ),
                if (index == 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: goldColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              names[index],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              messages[index],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.black.withOpacity(0.6)),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${10 + index} min ago',
                  style: TextStyle(fontSize: 10, color: Colors.black.withOpacity(0.3)),
                ),
                if (index == 0)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: clayColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
