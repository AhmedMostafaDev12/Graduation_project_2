import 'package:flutter/material.dart';

import 'remori_theme.dart';

class RemoriNavigationItem {
  const RemoriNavigationItem({required this.label, required this.icon});
  final String label;
  final Widget icon;
}

/// Four localized destinations and a center action; routing is supplied later.
class RemoriNavigationBar extends StatelessWidget {
  const RemoriNavigationBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
    this.showAction = true,
    this.actionSelected = false,
    this.showActionLabel = false,
    this.mode = RemoriMode.caregiver,
  }) : assert(items.length == 4),
       assert(selectedIndex >= -1 && selectedIndex < 4);

  final List<RemoriNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String actionLabel;
  final Widget actionIcon;
  final VoidCallback? onAction;
  final bool showAction;
  final bool actionSelected;
  final bool showActionLabel;
  final RemoriMode mode;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final actionSize = mode == RemoriMode.patient ? 64.0 : 58.0;
      final destinationWidth = constraints.maxWidth * (1 - 78 / 390) / 4;
      var barHeight = 68.0;
      for (final item in items) {
        final text = TextPainter(
          text: TextSpan(
            text: item.label,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: mode == RemoriMode.patient ? 14 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: destinationWidth);
        final requiredHeight = 22 + 3 + text.height + 16;
        if (requiredHeight > barHeight) barHeight = requiredHeight;
        text.dispose();
      }
      return SizedBox(
        height: barHeight + 24,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: barHeight,
              child: IgnorePointer(
                child: CustomPaint(painter: _NavigationPainter()),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: barHeight,
              child: Row(
                children: [
                  _destination(context, 0, barHeight),
                  _destination(context, 1, barHeight),
                  SizedBox(width: constraints.maxWidth * 78 / 390),
                  _destination(context, 2, barHeight),
                  _destination(context, 3, barHeight),
                ],
              ),
            ),
            if (showAction)
              Positioned(
                top: 0,
                left: (constraints.maxWidth - actionSize) / 2,
                child: Semantics(
                  button: true,
                  enabled: onAction != null,
                  selected: actionSelected,
                  label: actionLabel,
                  child: Tooltip(
                    message: actionLabel,
                    child: Column(
                      children: [
                        DecoratedBox(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [RemoriTheme.actionShadow],
                          ),
                          child: Material(
                            color: actionSelected
                                ? RemoriColors.purple
                                : RemoriColors.surface,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: onAction,
                              customBorder: const CircleBorder(),
                              child: SizedBox(
                                width: actionSize,
                                height: actionSize,
                                child: IconTheme(
                                  data: IconThemeData(
                                    color: actionSelected
                                        ? Colors.white
                                        : RemoriColors.purple,
                                    size: 28,
                                  ),
                                  child: Center(
                                    child: ExcludeSemantics(child: actionIcon),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (showActionLabel)
                          ExcludeSemantics(
                            child: InkWell(
                              onTap: onAction,
                              child: Text(
                                actionLabel,
                                style: TextStyle(
                                  color: actionSelected
                                      ? RemoriColors.purple
                                      : RemoriColors.muted,
                                  fontSize: 12,
                                  fontWeight: actionSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );

  Widget _destination(BuildContext context, int index, double barHeight) {
    final selected = selectedIndex == index;
    final color = selected ? RemoriColors.purple : RemoriColors.muted;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onSelected(index),
            child: SizedBox(
              height: barHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconTheme(
                    data: IconThemeData(color: color, size: 22),
                    child: ExcludeSemantics(child: items[index].icon),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    items[index].label,
                    style: TextStyle(
                      color: color,
                      fontSize: mode == RemoriMode.patient ? 14 : 12,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 390);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(146, 0)
      ..cubicTo(162, 0, 165, 6, 169, 14)
      ..cubicTo(176, 30, 185, 37, 195, 37)
      ..cubicTo(205, 37, 214, 30, 221, 14)
      ..cubicTo(225, 6, 228, 0, 244, 0)
      ..lineTo(390, 0)
      ..lineTo(390, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawShadow(path, RemoriColors.ink.withValues(alpha: .08), 8, false);
    canvas.drawPath(path, Paint()..color = RemoriColors.surface);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NavigationPainter oldDelegate) => false;
}
