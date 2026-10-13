import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'remori_theme.dart';

class RemoriLogo extends StatelessWidget {
  const RemoriLogo({super.key, required this.semanticLabel, this.width = 130});
  final String semanticLabel;
  final double width;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/images/remori-logo.svg',
    width: width,
    semanticsLabel: semanticLabel,
  );
}

/// Callers provide localized labels, including accessibility descriptions.
class RemoriButton extends StatelessWidget {
  const RemoriButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.outlined = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      boxShadow: onPressed == null ? null : const [RemoriTheme.buttonShadow],
    ),
    child: outlined
        ? OutlinedButton(onPressed: onPressed, child: Text(label))
        : FilledButton(onPressed: onPressed, child: Text(label)),
  );
}

class RemoriCard extends StatelessWidget {
  const RemoriCard({
    super.key,
    required this.child,
    this.mode = RemoriMode.caregiver,
  });
  final Widget child;
  final RemoriMode mode;

  @override
  Widget build(BuildContext context) {
    final patient = mode == RemoriMode.patient;
    return Container(
      padding: patient
          ? const EdgeInsets.all(16)
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(patient ? 16 : 10),
        border: Border.all(
          color: RemoriColors.border,
          width: patient ? 1.5 : 1,
        ),
      ),
      child: child,
    );
  }
}

enum RemoriChipKind { neutral, selected, success, warning, danger, phaseTwo }

class RemoriChip extends StatelessWidget {
  const RemoriChip({
    super.key,
    required this.label,
    this.kind = RemoriChipKind.neutral,
    this.mode = RemoriMode.caregiver,
    this.onPressed,
  });
  final String label;
  final RemoriChipKind kind;
  final RemoriMode mode;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (kind) {
      RemoriChipKind.selected => (RemoriColors.purple, RemoriColors.surface),
      RemoriChipKind.success => (RemoriColors.success, RemoriColors.successInk),
      RemoriChipKind.warning => (RemoriColors.warning, RemoriColors.warningInk),
      RemoriChipKind.danger => (RemoriColors.danger, RemoriColors.dangerInk),
      _ => (RemoriColors.surface, RemoriColors.purple),
    };
    final status =
        kind == RemoriChipKind.success ||
        kind == RemoriChipKind.warning ||
        kind == RemoriChipKind.danger;
    final shape = StadiumBorder(
      side: BorderSide(
        color: status
            ? Colors.transparent
            : kind == RemoriChipKind.phaseTwo
            ? RemoriColors.lavender
            : RemoriColors.border,
      ),
    );
    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: mode == RemoriMode.patient ? 12 : 9,
        vertical: mode == RemoriMode.patient ? 5 : 3,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: mode == RemoriMode.patient ? 22 : 12,
          fontWeight: status ? FontWeight.w400 : FontWeight.w600,
        ),
      ),
    );
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        color: background,
        shadows: status ? RemoriTheme.statusShadows : null,
      ),
      child: onPressed == null
          ? content
          : Semantics(
              button: true,
              selected: kind == RemoriChipKind.selected,
              child: Material(
                color: Colors.transparent,
                shape: shape,
                child: InkWell(
                  onTap: onPressed,
                  customBorder: shape,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: mode == RemoriMode.patient ? 64 : 48,
                      minWidth: 48,
                    ),
                    child: Center(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: content,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class RemoriInput extends StatelessWidget {
  const RemoriInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
  });
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: 6),
      Semantics(
        label: label,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
        ),
      ),
    ],
  );
}
