import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/elysion_theme.dart';

class NativeMeshBackground extends StatefulWidget {
  final String mode; // 'mesh' | 'silk' | 'bloom' | 'static'
  final Color c1;
  final Color c2;
  final Color c3;
  final bool dimmed;

  const NativeMeshBackground({
    super.key,
    required this.mode,
    required this.c1,
    required this.c2,
    required this.c3,
    this.dimmed = false,
  });

  @override
  State<NativeMeshBackground> createState() => _NativeMeshBackgroundState();
}

class _NativeMeshBackgroundState extends State<NativeMeshBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 18));
    if (widget.mode != 'static') _ctrl.repeat();
  }

  @override
  void didUpdateWidget(covariant NativeMeshBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode == 'static' && _ctrl.isAnimating) {
      _ctrl.stop();
    } else if (widget.mode != 'static' && !_ctrl.isAnimating) {
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mode == 'static') {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cAlpha(widget.c1, 0.35), kBgDark, cAlpha(widget.c2, 0.25)],
          ),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _MeshPainter(
          t: _ctrl.value * 2 * pi,
          mode: widget.mode,
          c1: widget.c1,
          c2: widget.c2,
          c3: widget.c3,
          dim: widget.dimmed ? 0.58 : 1.0,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  final double t;
  final String mode;
  final Color c1;
  final Color c2;
  final Color c3;
  final double dim;

  _MeshPainter({
    required this.t,
    required this.mode,
    required this.c1,
    required this.c2,
    required this.c3,
    required this.dim,
  });

  void _drawOrb(Canvas canvas, Size size, Offset center, double radius, Color color, double opacity) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [cAlpha(color, opacity * dim), cAlpha(color, 0.0)],
      ).createShader(rect);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = mode == 'bloom' ? Colors.black : const Color(0xFF07040F));

    if (mode == 'bloom') {
      // Concept 3: Pure OLED black edges + tight glowing aura hugging the album cover
      final cx = w * 0.5;
      final cy = h * 0.36;
      _drawOrb(canvas, size, Offset(cx - w * 0.16 * cos(t), cy + h * 0.06 * sin(t)), w * 0.56, c1, 0.55);
      _drawOrb(canvas, size, Offset(cx + w * 0.18 * cos(t + 2.1), cy - h * 0.05 * sin(t + 2.1)), w * 0.52, c2, 0.50);
      _drawOrb(canvas, size, Offset(cx + w * 0.10 * sin(t * 0.8), cy + h * 0.08 * cos(t * 0.8)), w * 0.46, c3, 0.44);
    } else if (mode == 'silk') {
      // Concept 2: Flowing diagonal velvet silk ribbons
      _drawOrb(canvas, size, Offset(w * (0.25 + 0.25 * sin(t)), h * (0.20 + 0.14 * cos(t))), w * 0.90, c1, 0.48);
      _drawOrb(canvas, size, Offset(w * (0.78 + 0.20 * cos(t * 0.9)), h * (0.48 + 0.18 * sin(t))), w * 0.88, c2, 0.46);
      _drawOrb(canvas, size, Offset(w * (0.35 + 0.22 * cos(t + 1.5)), h * (0.76 + 0.14 * sin(t + 1.5))), w * 0.85, c3, 0.40);
    } else {
      // Concept 1 (default): Apple Music 4-color orbiting clouds
      _drawOrb(canvas, size, Offset(w * (0.22 + 0.20 * sin(t)), h * (0.22 + 0.14 * cos(t))), w * 0.84, c1, 0.56);
      _drawOrb(canvas, size, Offset(w * (0.80 + 0.18 * cos(t)), h * (0.30 + 0.16 * sin(t))), w * 0.78, c2, 0.52);
      _drawOrb(canvas, size, Offset(w * (0.26 + 0.22 * cos(t * 0.85)), h * (0.74 + 0.15 * sin(t))), w * 0.82, c3, 0.46);
      _drawOrb(canvas, size, Offset(w * (0.76 + 0.18 * sin(t * 0.9)), h * (0.78 + 0.14 * cos(t))), w * 0.76, c1, 0.44);
    }
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.mode != mode || oldDelegate.c1 != c1 || oldDelegate.dim != dim;
}
