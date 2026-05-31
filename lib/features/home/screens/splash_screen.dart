import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 1.5 second timer before navigating to the Home tab
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        context.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Deep Earth Tone Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4A2511), // Deep Terracotta/Forest
                  Color(0xFF2A1508), // Rich Dark Earth
                ],
              ),
            ),
          ),
          
          // 2. Faint Khmer Motif Pattern Overlay (Opactiy at 20%)
          Opacity(
            opacity: 0.2,
            child: CustomPaint(
              size: Size.infinite,
              painter: _KhmerMotifPainter(color: goldColor),
            ),
          ),

          // 3. Centered Content (Logo, Text, Divider)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Gold Logo Circle
                Container(
                  height: 96,
                  width: 96,
                  decoration: BoxDecoration(
                    color: goldColor.withOpacity(0.95),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: goldColor.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome, // Closest native icon to the React SVG star
                    color: Color(0xFF4A2511),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Typography
                const Text(
                  'Gift & Souvenir',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'អំណោយខ្មែរ · Khmer Collection',
                  style: TextStyle(
                    fontSize: 16,
                    color: goldColor,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Custom Native Khmer Divider
                SizedBox(
                  width: 180,
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: goldColor.withOpacity(0.5))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Transform.rotate(
                          angle: 0.785398, // 45 degrees in radians
                          child: Container(
                            width: 6,
                            height: 6,
                            color: goldColor,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: goldColor.withOpacity(0.5))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Bottom Subtitle
                Text(
                  'HANDMADE IN CAMBODIA',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 4.0, // Matches tracking-[0.3em]
                    color: goldColor.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter to draw the diamond lattice pattern natively
class _KhmerMotifPainter extends CustomPainter {
  final Color color;
  _KhmerMotifPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    const double step = 80.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        final path = Path()
          ..moveTo(x + 40, y + 10)
          ..lineTo(x + 50, y + 30)
          ..lineTo(x + 40, y + 50)
          ..lineTo(x + 30, y + 30)
          ..close();
        
        // Side lines
        path.moveTo(x + 10, y + 40);
        path.lineTo(x + 30, y + 40);
        path.moveTo(x + 50, y + 40);
        path.lineTo(x + 70, y + 40);

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}