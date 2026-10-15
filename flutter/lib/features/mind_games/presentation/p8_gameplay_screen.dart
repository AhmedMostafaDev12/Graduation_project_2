import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/remori_routes.dart';
import '../../../core/theme/remori_theme.dart';
import '../../../core/theme/remori_widgets.dart';
import '../../patient_today/domain/patient_today_data.dart';
import '../../patient_today/presentation/patient_today_providers.dart';
import 'card_game_providers.dart';

class P8GameplayScreen extends ConsumerStatefulWidget {
  const P8GameplayScreen({super.key, this.scope});
  final PatientTodayKey? scope;
  @override
  ConsumerState<P8GameplayScreen> createState() => _P8GameplayScreenState();
}

class _P8GameplayScreenState extends ConsumerState<P8GameplayScreen>
    with WidgetsBindingObserver {
  bool _foreground = true, _visible = true;
  @override
  void initState() {
    super.initState();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _visibility() {
    final key = widget.scope;
    if (!mounted || key == null || ref.read(patientTodayKeyProvider) != key) {
      return;
    }
    final c = ref.read(cardGameControllerProvider(key).notifier);
    if (_foreground && _visible) {
      c.resume();
    } else {
      c.pause();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _visibility();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final visible = ModalRoute.isCurrentOf(context) ?? true;
    if (_visible != visible) {
      _visible = visible;
      Future.microtask(_visibility);
    }
    final key = widget.scope, s = AppLocalizations.of(context);
    final active = key != null && key == ref.watch(patientTodayKeyProvider);
    final state = active
        ? ref.watch(cardGameControllerProvider(key))
        : const CardGameState(failed: true);
    if (!_foreground && active && (state.ready || state.busy)) {
      Future.microtask(_visibility);
    }
    final seconds = state.elapsed.inSeconds,
        timer =
            '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 40).clamp(0, double.infinity),
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            onPressed: () =>
                                context.goNamed(RemoriScreen.p7.name),
                            icon: const BackButtonIcon(),
                            label: Text(
                              s.patientMemoryBack,
                              style: const TextStyle(fontSize: 22),
                            ),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(64, 64),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          timer,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.patientGameCards,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.cardGameInstruction,
                    style: const TextStyle(
                      fontSize: 22,
                      color: RemoriColors.muted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (active &&
                      _foreground &&
                      _visible &&
                      state.photos.length == 2 &&
                      state.round != null) ...[
                    for (var row = 0; row < 2; row++) ...[
                      Row(
                        children: [
                          for (var col = 0; col < 2; col++) ...[
                            if (col > 0) const SizedBox(width: 14),
                            Expanded(
                              child: _Card(
                                index: row * 2 + col,
                                state: state,
                                onTap: () => ref
                                    .read(
                                      cardGameControllerProvider(key).notifier,
                                    )
                                    .pick(row * 2 + col),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                  ] else
                    Text(
                      state.busy
                          ? s.todayGettingReady
                          : state.needPeople
                          ? s.cardGameNeedPeople
                          : s.cardGameUnavailable,
                      style: const TextStyle(fontSize: 22),
                    ),
                  if (state.failed && active) ...[
                    const SizedBox(height: 14),
                    RemoriButton(
                      label: s.homeRetry,
                      outlined: true,
                      onPressed: state.busy
                          ? null
                          : () => ref
                                .read(cardGameControllerProvider(key).notifier)
                                .resume(),
                    ),
                  ],
                  if ((state.round?.score ?? 0) > 0 &&
                      !state.failed &&
                      !state.saveFailed)
                    Text(
                      s.cardGameEncouragement,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff2f5130),
                      ),
                    ),
                  if (state.saveFailed)
                    Text(
                      s.cardGameSaveFailed,
                      style: const TextStyle(fontSize: 22),
                    ),
                  const Spacer(),
                  const SizedBox(height: 24),
                  RemoriButton(
                    label: state.saveFailed ? s.homeRetry : s.cardGameDone,
                    outlined: true,
                    onPressed:
                        !active ||
                            state.busy ||
                            (!state.ready && !state.saveFailed) ||
                            !_foreground ||
                            !_visible
                        ? null
                        : () async {
                            final result = await ref
                                .read(cardGameControllerProvider(key).notifier)
                                .finish();
                            if (context.mounted &&
                                result != null &&
                                ref.read(patientTodayKeyProvider) == key) {
                              context.goNamed(
                                RemoriScreen.p9.name,
                                extra: result,
                              );
                            }
                          },
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

class _Card extends StatelessWidget {
  const _Card({required this.index, required this.state, required this.onTap});
  final int index;
  final CardGameState state;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final round = state.round!,
        up = round.up(index),
        person = round.cards[index],
        s = AppLocalizations.of(context);
    final enabled = state.ready && !up && !round.waiting;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: round.matched.contains(index),
      label: up
          ? s.cardGamePerson(state.people[person].name)
          : s.cardGameHidden(index + 1),
      child: ExcludeSemantics(
        child: SizedBox(
          height: 150,
          child: Material(
            color: RemoriColors.purple,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? onTap : null,
              child: Container(
                decoration: up
                    ? BoxDecoration(
                        border: Border.all(
                          color: const Color(0xfff4a261),
                          width: 4,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      )
                    : null,
                child: up
                    ? Image.memory(
                        state.photos[person],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.person_outline,
                          size: 48,
                          color: Colors.white,
                        ),
                      )
                    : const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
