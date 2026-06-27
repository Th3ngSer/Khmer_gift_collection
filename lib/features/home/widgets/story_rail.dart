import 'package:flutter/material.dart';
import 'story_viewer.dart';
import 'add_story_sheet.dart';

class StoryRail extends StatelessWidget {
  final List<Map<String, dynamic>> stories;
  final String role;

  const StoryRail({
    super.key,
    required this.stories,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);
    final isArtisan = role == 'artisan';

    if (stories.isEmpty && !isArtisan) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: stories.length + (isArtisan ? 1 : 0),
        itemBuilder: (context, index) {
          if (isArtisan && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                    builder: (context) => const AddStorySheet(),
                  );
                },
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade200),
                          child: const CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.palette_outlined,
                                color: Color(0xFF8C2D19)),
                          ),
                        ),
                        const Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: goldColor,
                            child: Icon(Icons.add, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Add Story',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }

          final storyIndex = isArtisan ? index - 1 : index;
          final story = stories[storyIndex];

          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        StoryViewer(stories: stories, initialIndex: storyIndex),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) =>
                            FadeTransition(opacity: animation, child: child),
                  ),
                );
              },
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [
                        Color(0xFF8C2D19),
                        goldColor,
                        Color(0xFF8C2D19)
                      ]),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).scaffoldBackgroundColor),
                      child: CircleAvatar(
                          radius: 26,
                          backgroundImage: NetworkImage(story['avatar'])),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(story['label'],
                      style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(200))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}