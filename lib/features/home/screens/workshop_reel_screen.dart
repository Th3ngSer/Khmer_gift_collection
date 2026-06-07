import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../data/models/reel.dart';
import '../../../core/theme/app_theme.dart';

class WorkshopReelScreen extends ConsumerStatefulWidget {
  const WorkshopReelScreen({super.key});

  @override
  ConsumerState<WorkshopReelScreen> createState() => _WorkshopReelScreenState();
}

class _WorkshopReelScreenState extends ConsumerState<WorkshopReelScreen> {
  final PageController _pageController = PageController();

  // Mock data for reels
  final List<Reel> mockReels = [
    Reel(
      id: 'r1',
      artisanId: 'a1',
      artisanName: 'Sophea Silk',
      artisanAvatar: 'https://i.pravatar.cc/150?u=a1',
      videoUrl: 'https://assets.mixkit.com/videos/preview/mixkit-weaving-silk-on-a-loom-41584-large.mp4',
      caption: 'The art of traditional Khmer silk weaving. Every thread tells a story of our ancestors.',
      location: 'Siem Reap',
      likes: 1240,
    ),
    Reel(
      id: 'r2',
      artisanId: 'a2',
      artisanName: 'Kiri Woodwork',
      artisanAvatar: 'https://i.pravatar.cc/150?u=a2',
      videoUrl: 'https://assets.mixkit.com/videos/preview/mixkit-carpenter-shaving-a-piece-of-wood-with-a-chisel-42774-large.mp4',
      caption: 'Transforming sustainable rosewood into elegant kitchenware. Traditional carving at its best.',
      location: 'Kampong Thom',
      likes: 856,
    ),
    Reel(
      id: 'r3',
      artisanId: 'a3',
      artisanName: 'Sopheap Clay',
      artisanAvatar: 'https://i.pravatar.cc/150?u=a3',
      videoUrl: 'https://assets.mixkit.com/videos/preview/mixkit-potter-shaping-a-clay-bowl-on-wheel-42770-large.mp4',
      caption: 'The legendary red clay of Kampong Chhnang. Shaping tradition into modern vessels.',
      location: 'Kampong Chhnang',
      likes: 2100,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Workshop Reels',
          style: TextStyle(color: Colors.white, fontFamily: 'serif', fontWeight: FontWeight.bold),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: mockReels.length,
        itemBuilder: (context, index) {
          return ReelItem(reel: mockReels[index]);
        },
      ),
    );
  }
}

class ReelItem extends StatefulWidget {
  final Reel reel;
  const ReelItem({super.key, required this.reel});

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.reel.videoUrl))
      ..initialize().then((_) {
        setState(() {
          _initialized = true;
          _controller.setLooping(true);
          _controller.play();
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video Player
        if (_initialized)
          GestureDetector(
            onTap: () {
              _controller.value.isPlaying ? _controller.pause() : _controller.play();
            },
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          )
        else
          Shimmer.fromColors(
            baseColor: Colors.grey[900]!,
            highlightColor: Colors.grey[800]!,
            child: Container(color: Colors.black),
          ),

        // Bottom Gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.center,
              colors: [Colors.black.withAlpha(200), Colors.transparent],
            ),
          ),
        ),

        // Right Side Actions
        Positioned(
          right: 16,
          bottom: 100,
          child: Column(
            children: [
              _buildActionButton(Icons.favorite, widget.reel.likes.toString(), color: Colors.redAccent),
              const SizedBox(height: 20),
              _buildActionButton(Icons.chat_bubble_outline, '24'),
              const SizedBox(height: 20),
              _buildActionButton(Icons.share, 'Share'),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.gold,
                child: CircleAvatar(
                  radius: 22,
                  backgroundImage: NetworkImage(widget.reel.artisanAvatar),
                ),
              ),
            ],
          ),
        ),

        // Bottom Info
        Positioned(
          left: 16,
          bottom: 40,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.reel.artisanName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withAlpha(200),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'FOLLOW',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.reel.caption ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppTheme.gold, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    widget.reel.location ?? '',
                    style: const TextStyle(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, {Color color = Colors.white}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
