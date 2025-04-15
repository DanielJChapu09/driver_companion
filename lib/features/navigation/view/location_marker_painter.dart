import 'dart:math';
import 'package:flutter/material.dart';

class LocationMarkerPainter extends CustomPainter {
  final double bearing;

  LocationMarkerPainter({this.bearing = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    // Draw outer circle (accuracy indicator)
    final outerPaint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, outerPaint);

    // Draw inner circle (location point)
    final innerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.5, innerPaint);

    // Draw direction indicator
    if (bearing != 0) {
      // Save the current canvas state
      canvas.save();

      // Rotate the canvas based on bearing
      canvas.translate(center.dx, center.dy);
      canvas.rotate((bearing * pi) / 180);

      // Draw the direction triangle
      final directionPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(0, -radius * 0.8); // Top point
      path.lineTo(radius * 0.4, radius * 0.4); // Bottom right
      path.lineTo(-radius * 0.4, radius * 0.4); // Bottom left
      path.close();

      canvas.drawPath(path, directionPaint);

      // Restore the canvas to its original state
      canvas.restore();
    }

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius * 0.5, borderPaint);
  }

  @override
  bool shouldRepaint(LocationMarkerPainter oldDelegate) {
    return oldDelegate.bearing != bearing;
  }
}
