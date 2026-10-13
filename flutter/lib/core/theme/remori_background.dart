import 'package:flutter/material.dart';

import 'remori_theme.dart';

enum RemoriBackgroundKind { onboarding, wave }

/// Paint is decorative; the OS owns the status bar and SafeArea insets.
class RemoriBackground extends StatelessWidget {
  const RemoriBackground({
    super.key,
    required this.child,
    this.kind = RemoriBackgroundKind.wave,
  });
  final Widget child;
  final RemoriBackgroundKind kind;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: RemoriColors.cream,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _BackgroundPainter(kind)),
          ),
        ),
        SafeArea(child: child),
      ],
    ),
  );
}

class _BackgroundPainter extends CustomPainter {
  const _BackgroundPainter(this.kind);
  final RemoriBackgroundKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 390);
    if (kind == RemoriBackgroundKind.onboarding) {
      canvas.scale(1, size.height / 844);
      _fill(
        canvas,
        Path()
          ..moveTo(168, 0)
          ..lineTo(390, 0)
          ..lineTo(390, 306)
          ..cubicTo(366, 276, 342, 204, 312, 148)
          ..cubicTo(280, 90, 222, 40, 168, 0)
          ..close(),
        RemoriColors.curveLilac,
      );
      _fill(
        canvas,
        Path()
          ..moveTo(0, 288)
          ..cubicTo(30, 298, 38, 370, 0, 412)
          ..close(),
        RemoriColors.curveGreen,
      );
      _fill(
        canvas,
        Path()
          ..moveTo(0, 100)
          ..cubicTo(42, 102, 78, 160, 76, 222)
          ..cubicTo(74, 284, 38, 330, 0, 346)
          ..close(),
        RemoriColors.curveBlue,
      );
      _fill(
        canvas,
        Path()
          ..moveTo(390, 478)
          ..cubicTo(342, 490, 302, 520, 272, 560)
          ..cubicTo(252, 588, 232, 612, 218, 640)
          ..cubicTo(282, 646, 344, 632, 390, 612)
          ..close(),
        RemoriColors.curvePink,
      );
      _stroke(
        canvas,
        Path()
          ..moveTo(-4, 506)
          ..cubicTo(36, 528, 100, 604, 196, 614)
          ..cubicTo(262, 621, 300, 600, 322, 584)
          ..cubicTo(348, 566, 372, 548, 396, 536),
        RemoriColors.curveLine,
      );
      _circle(canvas, const Offset(18.5, 521.3), 7, RemoriColors.curveLine);
      _circle(canvas, const Offset(322, 584), 6, RemoriColors.curveLine);
    } else {
      // The export's 390 x 300 SVG is anchored to the bottom, not stretched tall.
      canvas.translate(0, size.height - 300);
      _fill(
        canvas,
        Path()
          ..moveTo(0, 190)
          ..cubicTo(50, 160, 120, 172, 160, 214)
          ..cubicTo(190, 246, 184, 300, 184, 300)
          ..lineTo(0, 300)
          ..close(),
        RemoriColors.blue.withValues(alpha: .3),
      );
      _fill(
        canvas,
        Path()
          ..moveTo(140, 300)
          ..cubicTo(166, 238, 232, 196, 302, 202)
          ..cubicTo(348, 206, 390, 176, 390, 176)
          ..lineTo(390, 300)
          ..close(),
        RemoriColors.waveLilac.withValues(alpha: .62),
      );
      _fill(
        canvas,
        Path()
          ..moveTo(250, 300)
          ..cubicTo(276, 252, 342, 238, 390, 252)
          ..lineTo(390, 300)
          ..close(),
        RemoriColors.wavePink.withValues(alpha: .75),
      );
      _stroke(
        canvas,
        Path()
          ..moveTo(-10, 120)
          ..cubicTo(70, 76, 140, 150, 210, 112)
          ..cubicTo(280, 74, 330, 50, 400, 74),
        RemoriColors.waveLine.withValues(alpha: .55),
      );
      for (final position in [const Offset(66, 98), const Offset(322, 64)]) {
        _circle(
          canvas,
          position,
          5,
          RemoriColors.waveLine.withValues(alpha: .75),
        );
      }
    }
    canvas.restore();
  }

  void _fill(Canvas canvas, Path path, Color color) =>
      canvas.drawPath(path, Paint()..color = color);
  void _stroke(Canvas canvas, Path path, Color color) => canvas.drawPath(
    path,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6,
  );
  void _circle(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(center, radius, Paint()..color = RemoriColors.cream);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) =>
      kind != oldDelegate.kind;
}
