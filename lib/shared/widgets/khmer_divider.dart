import 'package:flutter/material.dart';

class KhmerDivider extends StatelessWidget {
  final double width;
  
  const KhmerDivider({
    super.key, 
    this.width = 180,
  });

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);
    
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Expanded(child: Divider(color: goldColor.withOpacity(0.5))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Transform.rotate(
              angle: 0.785398, // 45 degrees to make a diamond
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
    );
  }
}