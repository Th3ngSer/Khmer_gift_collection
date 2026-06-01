// lib/features/nearby/screens/nearby_screen.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;
// Note: avoid importing `app_shell.dart` here to prevent a circular import

// ─── Data Model ────────────────────────────────────────────────────────────────

class Atelier {
  final String name;
  final String city;
  final String? address;
  final String? hours;
  final String? phone;
  final List<String> tags;
  final double distanceKm;
  final double mapX; // 0.0 – 1.0 relative position on map
  final double mapY;
  final bool featured;

  const Atelier({
    required this.name,
    required this.city,
    this.address,
    this.hours,
    this.phone,
    this.tags = const [],
    required this.distanceKm,
    required this.mapX,
    required this.mapY,
    this.featured = false,
  });
}

const List<Atelier> kAteliers = [
  Atelier(
    name: 'Riverside Atelier',
    city: 'Phnom Penh',
    address: 'Street 178, near the National Museum',
    hours: 'Tue–Sun, 10:00–19:00',
    phone: '+855 23 555 0101',
    tags: ['Heritage Silk', 'Modern Heritage'],
    distanceKm: 0.8,
    mapX: 0.62,
    mapY: 0.52,
    featured: true,
  ),
  Atelier(
    name: "Tonle Sap Weavers' Hub",
    city: 'Kampong Chhnang',
    distanceKm: 91.2,
    mapX: 0.30,
    mapY: 0.28,
  ),
  Atelier(
    name: 'Kampot Pepper Cellar',
    city: 'Kampot',
    distanceKm: 148.9,
    mapX: 0.48,
    mapY: 0.18,
  ),
  Atelier(
    name: 'Battambang Silver House',
    city: 'Battambang',
    distanceKm: 291.3,
    mapX: 0.15,
    mapY: 0.14,
  ),
  Atelier(
    name: 'Old Market Boutique',
    city: 'Siem Reap',
    distanceKm: 312.4,
    mapX: 0.50,
    mapY: 0.82,
  ),
];

// ─── Colours ───────────────────────────────────────────────────────────────────

const _kCream    = Color(0xFFF5F0E8);
const _kMapBg    = Color(0xFFEDE3D0);
const _kMapShape = Color(0xFFD9C9A8);
const _kLake     = Color(0xFFADD4CC);
const _kPin      = Color(0xFF8B3A2A);
const _kPinStar  = Color(0xFFC8A84B);
const _kText     = Color(0xFF2C1A0E);
const _kSubText  = Color(0xFF7A6651);
const _kTag      = Color(0xFFEDE3D0);
const _kSelected = Color(0xFF8B3A2A);
const _kCompass  = Color(0xFFC8A84B);

// ─── Screen ────────────────────────────────────────────────────────────────────

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  int _selectedAtelier = 0;

  @override
  Widget build(BuildContext context) {
    final selected = kAteliers[_selectedAtelier];

    return Scaffold(
      backgroundColor: _kCream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DISCOVER',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2.5,
                        color: _kSubText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nearby ateliers',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: _kText,
                        fontFamily: 'Georgia',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Tap a pin to see what's at each location.",
                      style: TextStyle(fontSize: 13, color: _kSubText),
                    ),
                  ],
                ),
              ),

              // ── Map ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 240,
                    child: _MapWidget(
                      ateliers: kAteliers,
                      selectedIndex: _selectedAtelier,
                      onTap: (i) => setState(() => _selectedAtelier = i),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Detail Card ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _DetailCard(atelier: selected),
              ),

              const SizedBox(height: 20),

              // ── List header ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'SORTED BY PROXIMITY',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2.2,
                    color: _kSubText,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── Atelier list ──
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: kAteliers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _AtelierListTile(
                  atelier: kAteliers[i],
                  isSelected: i == _selectedAtelier,
                  onTap: () => setState(() => _selectedAtelier = i),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Map ───────────────────────────────────────────────────────────────────────

class _MapWidget extends StatelessWidget {
  final List<Atelier> ateliers;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _MapWidget({
    required this.ateliers,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      return Stack(
        children: [
          Container(color: _kMapBg),
          CustomPaint(size: Size(w, h), painter: _MapPainter()),
          Positioned(
            top: 16,
            right: 20,
            child: _CompassWidget(),
          ),
          ...List.generate(ateliers.length, (i) {
            final a = ateliers[i];
            return Positioned(
              left: a.mapX * w - 14,
              top: a.mapY * h - 28,
              child: GestureDetector(
                onTap: () => onTap(i),
                child: _PinWidget(
                  featured: a.featured,
                  selected: i == selectedIndex,
                ),
              ),
            );
          }),
        ],
      );
    });
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Cambodia-like land blob
    final path = Path()
      ..moveTo(w * 0.25, h * 0.10)
      ..cubicTo(w * 0.40, h * 0.00, w * 0.70, h * 0.02, w * 0.85, h * 0.15)
      ..cubicTo(w * 1.00, h * 0.28, w * 0.98, h * 0.55, w * 0.90, h * 0.70)
      ..cubicTo(w * 0.82, h * 0.88, w * 0.60, h * 1.00, w * 0.40, h * 0.95)
      ..cubicTo(w * 0.20, h * 0.90, w * 0.02, h * 0.75, w * 0.05, h * 0.55)
      ..cubicTo(w * 0.00, h * 0.35, w * 0.10, h * 0.20, w * 0.25, h * 0.10)
      ..close();
    canvas.drawPath(path, Paint()..color = _kMapShape);

    // Tonle Sap lake
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.38, h * 0.52),
        width: w * 0.22,
        height: h * 0.14,
      ),
      Paint()..color = _kLake,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _PinWidget extends StatelessWidget {
  final bool featured;
  final bool selected;
  const _PinWidget({this.featured = false, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 28,
      height: 34,
      child: CustomPaint(
        painter: _PinPainter(featured: featured, selected: selected),
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  final bool featured;
  final bool selected;
  _PinPainter({required this.featured, required this.selected});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final r  = size.width / 2;
    final paint = Paint()
      ..color = _kPin.withOpacity(selected ? 1.0 : 0.85);

    // Body: circle + teardrop point
    final path = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, r), radius: r))
      ..moveTo(cx - r * 0.4, size.height * 0.72 * 0.75)
      ..lineTo(cx, size.height)
      ..lineTo(cx + r * 0.4, size.height * 0.72 * 0.75)
      ..close();
    canvas.drawPath(path, paint);

    if (featured) {
      _drawStar(canvas, Offset(cx, r), r * 0.55,
          Paint()..color = _kPinStar);
    } else {
      canvas.drawCircle(
          Offset(cx, r), r * 0.35, Paint()..color = Colors.white);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final oA = (2 * math.pi * i / 5) - math.pi / 2;
      final iA = oA + math.pi / 5;
      final outer = Offset(center.dx + radius * math.cos(oA),
          center.dy + radius * math.sin(oA));
      final inner = Offset(center.dx + radius * 0.45 * math.cos(iA),
          center.dy + radius * 0.45 * math.sin(iA));
      if (i == 0) {
        path.moveTo(outer.dx, outer.dy);
      } else {
        path.lineTo(outer.dx, outer.dy);
      }
      path.lineTo(inner.dx, inner.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinPainter old) =>
      old.featured != featured || old.selected != selected;
}

class _CompassWidget extends StatelessWidget {
  const _CompassWidget();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _kCompass.withOpacity(0.25),
        shape: BoxShape.circle,
        border: Border.all(color: _kCompass, width: 1.5),
      ),
      child: Center(
        child: Text('N',
            style: TextStyle(
                color: _kCompass,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ─── Detail Card ───────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final Atelier atelier;
  const _DetailCard({required this.atelier});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            atelier.city.toUpperCase(),
            style: TextStyle(
                fontSize: 10,
                letterSpacing: 2.0,
                color: _kPin,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            atelier.name,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _kText,
                fontFamily: 'Georgia'),
          ),
          if (atelier.address != null) ...[
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.location_on_outlined, text: atelier.address!),
          ],
          if (atelier.hours != null) ...[
            const SizedBox(height: 6),
            _InfoRow(icon: Icons.access_time_outlined, text: atelier.hours!),
          ],
          if (atelier.phone != null) ...[
            const SizedBox(height: 6),
            _InfoRow(icon: Icons.phone_outlined, text: atelier.phone!),
          ],
          if (atelier.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children:
                  atelier.tags.map((t) => _TagChip(label: t)).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: _kSubText),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 13, color: _kSubText))),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
          color: _kTag, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              color: _kText,
              fontWeight: FontWeight.w500)),
    );
  }
}

// ─── List Tile ─────────────────────────────────────────────────────────────────

class _AtelierListTile extends StatelessWidget {
  final Atelier atelier;
  final bool isSelected;
  final VoidCallback onTap;

  const _AtelierListTile({
    required this.atelier,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _kSelected : Colors.transparent,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(atelier.name,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _kText)),
                  const SizedBox(height: 2),
                  Text(atelier.city,
                      style:
                          TextStyle(fontSize: 12, color: _kSubText)),
                ],
              ),
            ),
            Text('${atelier.distanceKm} km',
                style: TextStyle(
                    fontSize: 13,
                    color: _kSubText,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}