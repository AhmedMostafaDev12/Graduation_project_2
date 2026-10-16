import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/remori_routes.dart';
import '../../../core/theme/remori_theme.dart';
import '../../../core/theme/remori_widgets.dart';

/// Staged D7 UI. Social collision handling awaits the approved auth integration.
class D7AccountExistsScreen extends StatelessWidget {
  const D7AccountExistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    void login() => context.goNamed(RemoriScreen.a2.name);
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 20, 20, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: RemoriColors.border)),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: login,
                  icon: const BackButtonIcon(),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    s.loginTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 14,
                          children: [
                            Semantics(
                              liveRegion: true,
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: RemoriColors.warning,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  spacing: 8,
                                  children: [
                                    Text(
                                      s.accountExistsTitle,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: RemoriColors.warningInk,
                                      ),
                                    ),
                                    Text(
                                      s.accountExistsGuidance,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: RemoriColors.warningInk,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: null,
                              style: OutlinedButton.styleFrom(
                                disabledForegroundColor: RemoriColors.muted,
                                side: const BorderSide(
                                  color: Color(0xFF747775),
                                ),
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              icon: ExcludeSemantics(
                                child: Opacity(
                                  opacity: 0.5,
                                  child: SvgPicture.asset(
                                    'assets/images/google.svg',
                                    width: 22,
                                    height: 22,
                                  ),
                                ),
                              ),
                              label: Text(s.continueGoogle),
                            ),
                            RemoriButton(
                              label: s.accountExistsEmail,
                              onPressed: login,
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Text(
                            s.accountExistsExplanation,
                            style: const TextStyle(
                              fontSize: 13,
                              color: RemoriColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
