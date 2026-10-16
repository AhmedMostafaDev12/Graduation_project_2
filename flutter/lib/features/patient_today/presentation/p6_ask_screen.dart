import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/remori_routes.dart';
import '../../../core/theme/remori_theme.dart';

/// P6 presentation only; recording and assistance remain Phase 2.
class P6AskScreen extends StatelessWidget {
  const P6AskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.goNamed(RemoriScreen.p1.name);
      },
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.goNamed(RemoriScreen.p1.name);
                        }
                      },
                      style: TextButton.styleFrom(
                        minimumSize: const Size(64, 64),
                        textStyle: const TextStyle(fontSize: 22),
                      ),
                      icon: const BackButtonIcon(),
                      label: Text(s.patientMemoryBack),
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    s.askPhaseTwo,
                    style: const TextStyle(
                      fontSize: 22,
                      color: RemoriColors.purple,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              s.ask,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            Center(
              child: Semantics(
                button: true,
                enabled: false,
                label: s.askTapSpeak,
                child: ExcludeSemantics(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: const BoxDecoration(
                      color: RemoriColors.purple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic_none,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              s.askTapSpeak,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            TextField(
              enabled: false,
              style: const TextStyle(fontSize: 22),
              decoration: InputDecoration(
                hintText: s.askQuestionHint,
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: RemoriColors.purple),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xfffff4e6),
                border: Border.all(color: RemoriColors.purple, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                s.askPending,
                style: const TextStyle(fontSize: 22, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
