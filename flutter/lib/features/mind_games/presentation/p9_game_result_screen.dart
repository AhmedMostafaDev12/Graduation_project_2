import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/remori_routes.dart';
import '../../../core/theme/remori_widgets.dart';
import '../../patient_today/presentation/patient_today_providers.dart';
import '../domain/card_game.dart';
import 'card_game_providers.dart';

class P9GameResultScreen extends ConsumerStatefulWidget {
  const P9GameResultScreen({super.key, this.target});
  final GameResultTarget? target;
  @override
  ConsumerState<P9GameResultScreen> createState() => _P9GameResultScreenState();
}

class _P9GameResultScreenState extends ConsumerState<P9GameResultScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.target != null) {
      ref.invalidate(gameResultUploadProvider(widget.target!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context), target = widget.target;
    final active =
        target != null && ref.watch(patientTodayKeyProvider) == target.scope;
    final snapshot = active ? ref.watch(gameResultProvider(target)) : null;
    final result = snapshot?.isLoading == false && snapshot?.hasError == false
        ? snapshot?.value
        : null;
    if (active && result != null) ref.watch(gameResultUploadProvider(target));
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 72).clamp(0, double.infinity),
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (result != null) ...[
                          Container(
                            width: 140,
                            height: 140,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xfff4a261),
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 72,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            s.cardGameWellDone,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w600,
                              color: Color(0xffb5651d),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            s.cardGameScore(result.score),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 26),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            s.cardGameDuration(
                              '${(result.seconds ~/ 60).toString().padLeft(2, '0')}:${(result.seconds % 60).toString().padLeft(2, '0')}',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              color: Color(0xff4d4d4d),
                            ),
                          ),
                        ] else
                          Text(
                            snapshot?.isLoading == true
                                ? s.todayGettingReady
                                : s.cardGameResultUnavailable,
                            style: const TextStyle(fontSize: 22),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (result != null) ...[
                    RemoriButton(
                      label: s.cardGameAgain,
                      onPressed: () => context.goNamed(
                        RemoriScreen.p8.name,
                        extra: target!.scope,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (snapshot?.hasError == true && active) ...[
                    RemoriButton(
                      label: s.homeRetry,
                      outlined: true,
                      onPressed: () =>
                          ref.invalidate(gameResultProvider(target)),
                    ),
                    const SizedBox(height: 14),
                  ],
                  RemoriButton(
                    label: s.cardGameBackGames,
                    outlined: true,
                    onPressed: () => context.goNamed(RemoriScreen.p7.name),
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
