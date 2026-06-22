import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StoryViewer extends StatefulWidget {
  final List<Map<String, dynamic>> stories;
  final int initialIndex;

  const StoryViewer({
    super.key,
    required this.stories,
    required this.initialIndex,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    // The 4500ms auto-progression timer
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _animController.forward();
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() => _currentIndex++);
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
      _animController.reset();
      _animController.forward();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. The Swipable Images & Text
          PageView.builder(
            controller: _pageController,
            physics:
                const NeverScrollableScrollPhysics(), // Disable drag to rely on tap zones
            itemCount: widget.stories.length,
            itemBuilder: (context, index) {
              final story = widget.stories[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(story['image'], fit: BoxFit.cover),

                  // Dark Gradient Overlay at bottom for text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        colors: [
                          Colors.black.withOpacity(0.9),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // Text Content
                  Positioned(
                    bottom: 40,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story['title'],
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          story['subtitle'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          story['caption'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            final String? destination = story['linkTo'] ??
                                (story['linkCollectionId'] != null
                                    ? '/collections/${story['linkCollectionId']}'
                                    : null);

                            Navigator.of(context).pop();

                            if (destination != null) {
                              GoRouter.of(context).push(destination);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Explore',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          // 2. The Invisible Tap Zones (Left 30% = Back, Right 70% = Next)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width * 0.33,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _previousStory,
            ),
          ),
          // Right Edge Tap Zone (React: w-1/3 absolute right-0)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width * 0.33,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _nextStory,
            ),
          ),

          // 3. The Animated Progress Bars
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            right: 10,
            child: Row(
              children: List.generate(widget.stories.length, (index) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          double progress = 0.0;
                          if (index < _currentIndex) progress = 1.0;
                          if (index == _currentIndex)
                            progress = _animController.value;

                          return LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            minHeight: 2,
                          );
                        },
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // 4. Close Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 24,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => context.pop(),
            ),
          ),
        ],
      ),
    );
  }
}
