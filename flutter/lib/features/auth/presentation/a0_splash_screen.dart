import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/remori_theme.dart';
import '../../../core/theme/remori_widgets.dart';

/// Body for A0; the entry router owns the background, Scaffold, and SafeArea.
class A0SplashScreen extends StatelessWidget {
  const A0SplashScreen({super.key, required this.onGetStarted});
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RemoriLogo(
                            semanticLabel: strings.appName,
                            width: 250,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            strings.splashTagline,
                            textAlign: TextAlign.center,
                            style: text.bodyLarge!.copyWith(
                              fontSize: 16,
                              letterSpacing: 0,
                              height: 1.45,
                              color: RemoriColors.lead,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 34),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RemoriButton(
                        label: strings.getStarted,
                        onPressed: onGetStarted,
                        trailingIcon: Transform.flip(
                          flipX:
                              Directionality.of(context) == TextDirection.rtl,
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CustomPaint(
                              painter: _ArrowPainter(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        strings.splashSupport,
                        textAlign: TextAlign.center,
                        style: text.bodySmall!.copyWith(
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Exact SVG stroke from A0's exported button; the label supplies semantics.
class _ArrowPainter extends CustomPainter {
  const _ArrowPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    canvas.drawPath(
      Path()
        ..moveTo(5, 12)
        ..lineTo(19, 12)
        ..moveTo(13, 6)
        ..lineTo(19, 12)
        ..lineTo(13, 18),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) =>
      color != oldDelegate.color;
}
