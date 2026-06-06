import 'package:flutter/material.dart';

class LoadingShimmer extends StatefulWidget {
  final int itemCount;
  
  const LoadingShimmer({super.key, this.itemCount = 6});

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(); 
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Automatically adjust colors based on light/dark mode
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.1, 0.5, 0.9],
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              // Slides the gradient across the screen based on the animation value
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: _buildSkeletonGrid(),
    );
  }

  Widget _buildSkeletonGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(), // Prevent scrolling while loading
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.60, // Matches your ProductCard aspect ratio
      ),
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Placeholder
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white, // Color doesn't matter, ShaderMask overrides it
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Title Placeholder
            Container(
              height: 16,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(4)
              ),
            ),
            const SizedBox(height: 8),
            // Price/Subtitle Placeholder
            Container(
              height: 14,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(4)
              ),
            ),
          ],
        );
      },
    );
  }
}

// Custom Transform to slide the gradient from left to right
class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0.0, 0.0);
  }
}