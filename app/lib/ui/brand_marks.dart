import 'package:flutter/material.dart';

// Simple hand-drawn marks that identify each streaming app on its key.
// They are drawn in code (no logo files are bundled).

/// Netflix-style "N": two dark-red uprights joined by a bright diagonal.
class NetflixMark extends StatelessWidget {
  const NetflixMark({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size * 0.62, size), painter: _NetflixPainter());
}

class _NetflixPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, bar = w * 0.3;
    final dark = Paint()..color = const Color(0xFFB1060F);
    canvas.drawRect(Rect.fromLTWH(0, 0, bar, h), dark);
    canvas.drawRect(Rect.fromLTWH(w - bar, 0, bar, h), dark);
    final diagonal = Path()
      ..moveTo(0, 0)
      ..lineTo(bar, 0)
      ..lineTo(w, h)
      ..lineTo(w - bar, h)
      ..close();
    canvas.drawShadow(diagonal, Colors.black, 2, false);
    canvas.drawPath(diagonal, Paint()..color = const Color(0xFFE50914));
  }

  @override
  bool shouldRepaint(_NetflixPainter oldDelegate) => false;
}

/// YouTube-style red rounded rectangle with a white play triangle.
class YouTubeMark extends StatelessWidget {
  const YouTubeMark({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size * 1.42, size), painter: _YouTubePainter());
}

class _YouTubePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(h * 0.3)),
      Paint()..color = const Color(0xFFFF0000),
    );
    final play = Path()
      ..moveTo(w * 0.40, h * 0.28)
      ..lineTo(w * 0.66, h * 0.5)
      ..lineTo(w * 0.40, h * 0.72)
      ..close();
    canvas.drawPath(play, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_YouTubePainter oldDelegate) => false;
}

/// Prime Video-style blue badge: "prime" with a smile arrow underneath.
class PrimeVideoMark extends StatelessWidget {
  const PrimeVideoMark({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 1.42,
      height: size,
      decoration: BoxDecoration(color: const Color(0xFF1A98FF), borderRadius: BorderRadius.circular(size * 0.24)),
      padding: EdgeInsets.symmetric(horizontal: size * 0.14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            child: Text(
              'prime',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.4, height: 1),
            ),
          ),
          CustomPaint(size: Size(size * 0.9, size * 0.2), painter: _SmilePainter()),
        ],
      ),
    );
  }
}

class _SmilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.32
      ..strokeCap = StrokeCap.round;
    final smile = Path()
      ..moveTo(w * 0.08, h * 0.2)
      ..quadraticBezierTo(w * 0.5, h * 1.0, w * 0.86, h * 0.25);
    canvas.drawPath(smile, stroke);
    final head = Path()
      ..moveTo(w * 0.74, h * 0.12)
      ..lineTo(w * 0.92, h * 0.16)
      ..lineTo(w * 0.88, h * 0.62);
    canvas.drawPath(head, stroke);
  }

  @override
  bool shouldRepaint(_SmilePainter oldDelegate) => false;
}
