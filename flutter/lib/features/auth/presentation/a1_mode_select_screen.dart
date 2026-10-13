import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/remori_theme.dart';
import '../../../core/theme/remori_widgets.dart';

/// A1 body; the entry router supplies the background and SafeArea.
class A1ModeSelectScreen extends StatelessWidget {
  const A1ModeSelectScreen({
    super.key,
    required this.onCaregiver,
    required this.onPatientPhone,
  });
  final VoidCallback onCaregiver;
  final VoidCallback onPatientPhone;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RemoriLogo(
                            semanticLabel: strings.appName,
                            width: 210,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            strings.modeSelectIntro,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(
                                  fontSize: 15,
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
                  padding: const EdgeInsets.fromLTRB(40, 0, 40, 150),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RemoriButton(
                        label: strings.modeCaregiver,
                        onPressed: onCaregiver,
                      ),
                      const SizedBox(height: 14),
                      RemoriButton(
                        label: strings.modePatientPhone,
                        onPressed: onPatientPhone,
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
