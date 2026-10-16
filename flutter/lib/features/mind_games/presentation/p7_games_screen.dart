import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/remori_routes.dart';
import '../../../core/router/patient_preview_provider.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/remori_theme.dart';
import '../../../core/theme/remori_widgets.dart';
import '../../patient_today/presentation/patient_today_providers.dart';
import '../domain/patient_games_data.dart';
import 'patient_games_providers.dart';

class P7GamesScreen extends ConsumerStatefulWidget {
  const P7GamesScreen({super.key});
  @override
  ConsumerState<P7GamesScreen> createState() => _P7GamesScreenState();
}

class _P7GamesScreenState extends ConsumerState<P7GamesScreen>
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
    final key = ref.read(patientTodayKeyProvider);
    if (state == AppLifecycleState.resumed &&
        key != null &&
        (ModalRoute.isCurrentOf(context) ?? true)) {
      ref.read(patientGamesControllerProvider(key).notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context),
        key = ref.watch(patientTodayKeyProvider);
    final snapshot = key == null
        ? null
        : ref.watch(patientGamesDataProvider(key));
    final state = key == null
        ? const PatientGamesState()
        : ref.watch(patientGamesControllerProvider(key));
    final data = snapshot?.isLoading == false && snapshot?.hasError == false
        ? snapshot?.value ?? const PatientGamesData()
        : const PatientGamesData();
    final titles = [
      s.patientGameCards,
      s.patientGamePicture,
      s.patientGameWords,
    ];
    final preview = ref.watch(patientPreviewProvider);
    const icons = [Icons.copy_outlined, Icons.image_outlined, Icons.notes];
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
        children: [
          Text(
            s.patientGames,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          if (state.failed || snapshot?.hasError == true) ...[
            Text(s.patientGamesOffline, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 12),
            RemoriButton(
              label: s.homeRetry,
              outlined: true,
              onPressed: key == null || state.busy
                  ? null
                  : () => ref
                        .read(patientGamesControllerProvider(key).notifier)
                        .refresh(),
            ),
            const SizedBox(height: 14),
          ],
          for (var i = 0; i < patientGameTypes.length; i++) ...[
            Semantics(
              button: true,
              enabled: key != null || preview,
              child: InkWell(
                onTap: key != null || preview
                    ? () => context.pushNamed(
                        RemoriScreen.p8.name,
                        extra: i == 0 && !preview
                            ? key
                            : (scope: key, type: patientGameTypes[i]),
                      )
                    : null,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  key: ValueKey('patient-game-${patientGameTypes[i]}'),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xffa48fcb),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: const Color(0xffeee8f7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            icons[i],
                            size: 40,
                            color: RemoriColors.purple,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titles[i],
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              data.scores[patientGameTypes[i]] != null
                                  ? s.patientGameLastScore(
                                      NumberFormat.decimalPattern(
                                        Localizations.localeOf(context)
                                            .languageCode,
                                      ).format(
                                        data.scores[patientGameTypes[i]]!.score,
                                      ),
                                    )
                                  : data.refreshed.contains(patientGameTypes[i])
                                  ? s.patientGameNone
                                  : s.patientGameUnavailable,
                              style: const TextStyle(
                                fontSize: 22,
                                color: RemoriColors.muted,
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
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}
