import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/chat_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/constants/translations.dart';
import '../../../core/theme/app_theme.dart';

class ChatSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setSearch(String query) => state = query;
  void clear() => state = '';
}

final chatSearchProvider = NotifierProvider<ChatSearchNotifier, String>(() => ChatSearchNotifier());

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final locale = ref.watch(localeProvider).languageCode;
    final searchQuery = ref.watch(chatSearchProvider);
    final allRooms = ref.watch(allChatRoomsProvider);
    
    String t(String key) => Translations.translate(key, locale);

    final textColor = isDark ? Colors.white : AppTheme.deepEarth;
    final cardBg = Theme.of(context).cardColor;

    final filteredChats = allRooms.where((room) {
      final name = room.name.toLowerCase();
      final query = searchQuery.toLowerCase();
      return name.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          t('messages'),
          style: TextStyle(color: textColor, fontFamily: 'serif', fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (value) => ref.read(chatSearchProvider.notifier).setSearch(value),
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: t('search_messages'),
                hintStyle: TextStyle(color: textColor.withAlpha(80), fontSize: 14),
                prefixIcon: Icon(Icons.search, color: textColor.withAlpha(80), size: 20),
                filled: true,
                fillColor: cardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: filteredChats.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(searchQuery.isEmpty ? Icons.chat_bubble_outline : Icons.search_off, size: 64, color: textColor.withAlpha(30)),
                        const SizedBox(height: 16),
                        Text(searchQuery.isEmpty ? t('no_messages') : 'No results found', style: TextStyle(color: textColor.withAlpha(100))),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredChats.length,
                    itemBuilder: (context, index) {
                      final room = filteredChats[index];
                      final lastMsg = ref.watch(lastMessageProvider(room.id));
                      
                      return _buildChatItem(context, room, lastMsg, textColor, cardBg);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, ChatRoomInfo room, ChatMessage? lastMsg, Color textColor, Color cardBg) {
    return InkWell(
      onTap: () => context.push('/chat-room/${room.id}', extra: {'currentUserId': 'user_123', 'artisanName': room.name}),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(radius: 28, backgroundColor: AppTheme.gold.withAlpha(20), backgroundImage: NetworkImage(room.avatar)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(room.name, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                          if (room.badge.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppTheme.gold.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                              child: Text(room.badge, style: const TextStyle(color: AppTheme.gold, fontSize: 8, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      if (lastMsg != null)
                        Text('${lastMsg.sentAt.hour}:${lastMsg.sentAt.minute.toString().padLeft(2, '0')}', style: TextStyle(color: textColor.withAlpha(80), fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMsg?.messageText ?? 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textColor.withAlpha(120), fontSize: 14),
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
