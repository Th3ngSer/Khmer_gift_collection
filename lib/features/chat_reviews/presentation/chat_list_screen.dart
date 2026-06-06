import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/constants/translations.dart';
import '../../../core/theme/app_theme.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final locale = ref.watch(localeProvider).languageCode;
    
    String t(String key) => Translations.translate(key, locale);

    final textColor = isDark ? Colors.white : AppTheme.deepEarth;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = Theme.of(context).cardColor;

    // Mock data for UI demonstration
    final chatList = [
      {
        'name': 'Sophea Silk',
        'lastMessage': 'How is the progress on my silk scarf?',
        'time': '10 min ago',
        'isNew': true,
        'image': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQX1CuF5ByhjpYZMllwvBG75hNLw58TW7Dp6Q&s',
      },
      {
        'name': 'Kiri Woodwork',
        'lastMessage': 'Yes, I can customize the wood grain for you.',
        'time': '25 min ago',
        'isNew': false,
        'image': 'https://pethero.co.za/wp-content/uploads/2026/02/Indoor-Cats-Blog-Banner.png',
      },
      {
        'name': 'Arun Sculpture',
        'lastMessage': 'The stone carving will be ready next week!',
        'time': '1 hour ago',
        'isNew': false,
        'image': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQiugxgmLGqUu6bXJiwgMidRtxyKN9zG_ujGg&s',
      },
    ];

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          t('messages'),
          style: TextStyle(
            color: textColor,
            fontFamily: 'serif',
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: textColor.withAlpha(180)),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Optional: Filter/Categories for chats (Active, Completed, All)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: t('search_messages'),
                hintStyle: TextStyle(color: textColor.withAlpha(80), fontSize: 14),
                prefixIcon: Icon(Icons.search, color: textColor.withAlpha(80), size: 20),
                filled: true,
                fillColor: cardBg,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          Expanded(
            child: chatList.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: textColor.withAlpha(30)),
                      const SizedBox(height: 16),
                      Text(t('no_messages'), style: TextStyle(color: textColor.withAlpha(100))),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: chatList.length,
                  itemBuilder: (context, index) {
                    final chat = chatList[index];
                    return _buildChatItem(context, chat, isDark, textColor, cardBg);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(
    BuildContext context, 
    Map<String, dynamic> chat, 
    bool isDark, 
    Color textColor,
    Color cardBg,
  ) {
    return InkWell(
      onTap: () {
        context.push(
          '/chat-room/room_${chat['name']}',
          extra: {
            'currentUserId': 'user_123', // Matches the mock user ID in provider
            'artisanName': chat['name'],
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: chat['isNew'] == true ? AppTheme.gold : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.gold.withAlpha(20),
                    backgroundImage: NetworkImage(chat['image']!),
                  ),
                ),
                if (chat['isNew'] == true)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.gold,
                        shape: BoxShape.circle,
                        border: Border.all(color: cardBg, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Message Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        chat['name']!,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: chat['isNew'] == true ? FontWeight.bold : FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        chat['time']!,
                        style: TextStyle(
                          color: textColor.withAlpha(80),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat['lastMessage']!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: chat['isNew'] == true ? textColor : textColor.withAlpha(120),
                      fontSize: 14,
                      fontWeight: chat['isNew'] == true ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
