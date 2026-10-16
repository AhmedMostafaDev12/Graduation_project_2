import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/remori_routes.dart';
import '../../../core/router/patient_preview_provider.dart';
import '../../../core/theme/remori_theme.dart';
import '../../../core/theme/remori_widgets.dart';
import '../../patient_today/presentation/patient_today_providers.dart';
import '../domain/card_game.dart';
import 'card_game_providers.dart';

/// Approved UI-only P8 variants. All choices and timing are ephemeral; this
/// widget never creates a session, calls a repository, or opens a scored result.
class P8PracticeScreen extends ConsumerStatefulWidget {
  const P8PracticeScreen({super.key, required this.target});
  final GameUiTarget target;
  @override
  ConsumerState<P8PracticeScreen> createState() => _P8PracticeScreenState();
}

class _P8PracticeScreenState extends ConsumerState<P8PracticeScreen>
    with WidgetsBindingObserver {
  late final Stopwatch _watch;
  Timer? _ticker;
  bool _foreground = true;
  bool _study = true;
  int _picture = 0;
  int? _choice;
  CardRound _round = CardRound([0, 1, 1, 0]);
  Timer? _mismatch;
  static const _icons = [
    Icons.local_cafe_outlined,
    Icons.key_outlined,
    Icons.menu_book_outlined,
    Icons.local_florist_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _watch = ref.read(cardGameStopwatchProvider)();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _watch.isRunning) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _mismatch?.cancel();
    _watch.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) _watch.stop();
    setState(() {});
  }

  void _back() => context.goNamed(RemoriScreen.p7.name);

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final target = widget.target;
    final picture = target.type == 'picture_naming';
    final preview = ref.watch(patientPreviewProvider) && target.scope == null;
    final matching = preview && target.type == 'face_match';
    final active =
        (preview ||
            (target.scope != null &&
                ref.watch(patientTodayKeyProvider) == target.scope)) &&
        (picture || target.type == 'word_recall' || matching);
    final visible = ModalRoute.isCurrentOf(context) ?? true;
    if (active && visible && _foreground) {
      _watch.start();
    } else {
      _watch.stop();
    }
    final labels = [
      s.gameObjectCup,
      s.gameObjectKey,
      s.gameObjectBook,
      s.gameObjectFlower,
    ];
    final elapsed = _watch.elapsed.inSeconds;
    final timer =
        '${(elapsed ~/ 60).toString().padLeft(2, '0')}:${(elapsed % 60).toString().padLeft(2, '0')}';
    final correct =
        _choice != null && (picture ? _choice == _picture : _choice! < 3);
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
                            onPressed: _back,
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
                  if (active) ...[
                    Text(
                      matching
                          ? s.patientGameCards
                          : picture
                          ? s.patientGamePicture
                          : s.patientGameWords,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      matching
                          ? s.cardGameInstruction
                          : picture
                          ? s.gamePicturePrompt
                          : _study
                          ? s.gameWordsStudy
                          : s.gameWordsRecall,
                      style: const TextStyle(
                        fontSize: 22,
                        color: RemoriColors.muted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (matching)
                      for (var row = 0; row < 2; row++) ...[
                        Row(
                          children: [
                            for (var col = 0; col < 2; col++) ...[
                              if (col > 0) const SizedBox(width: 14),
                              Expanded(
                                child: _previewCard(row * 2 + col, labels, s),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 14),
                      ]
                    else if (picture)
                      Semantics(
                        image: true,
                        label: labels[_picture],
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: const Color(0xffeee8f7),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _icons[_picture],
                            size: 112,
                            color: RemoriColors.purple,
                          ),
                        ),
                      )
                    else if (_study)
                      for (var i = 0; i < 3; i++) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            border: Border.all(color: RemoriColors.border),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              ExcludeSemantics(
                                child: Icon(
                                  _icons[i],
                                  size: 40,
                                  color: RemoriColors.purple,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  labels[i],
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    const SizedBox(height: 16),
                    if (!matching && (picture || !_study))
                      for (var i = 0; i < 4; i++) ...[
                        Semantics(
                          selected: _choice == i,
                          child: RemoriButton(
                            label: labels[i],
                            outlined: _choice != i,
                            onPressed: () => setState(() => _choice = i),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    if (_choice != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          correct ? s.cardGameEncouragement : s.gameTryAnother,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: correct
                                ? const Color(0xff2f5130)
                                : RemoriColors.muted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (!matching && !picture && _study)
                      RemoriButton(
                        label: s.gameWordsReady,
                        onPressed: () => setState(() {
                          _study = false;
                          _choice = null;
                        }),
                      ),
                    if (correct)
                      RemoriButton(
                        label: picture ? s.gameNextPicture : s.gameWordsAgain,
                        outlined: true,
                        onPressed: () => setState(() {
                          _choice = null;
                          if (picture) {
                            _picture = (_picture + 1) % 4;
                          } else {
                            _study = true;
                          }
                        }),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      s.gameUiOnlyNotice,
                      style: const TextStyle(
                        fontSize: 22,
                        color: RemoriColors.muted,
                      ),
                    ),
                  ] else
                    Text(
                      s.cardGameResultUnavailable,
                      style: const TextStyle(fontSize: 22),
                    ),
                  const Spacer(),
                  const SizedBox(height: 24),
                  RemoriButton(
                    label: s.cardGameDone,
                    outlined: true,
                    onPressed: _back,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _previewCard(int index, List<String> labels, AppLocalizations s) {
    final up = _round.up(index), value = _round.cards[index];
    return Semantics(
      button: true,
      label: up ? labels[value] : s.cardGameHidden(index + 1),
      selected: _round.matched.contains(index),
      child: SizedBox(
        height: 150,
        child: Material(
          color: up ? const Color(0xffeee8f7) : RemoriColors.purple,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('preview-card-$index'),
            onTap: up || _round.waiting
                ? null
                : () {
                    setState(() => _round = _round.pick(index));
                    if (_round.waiting) {
                      _mismatch = Timer(const Duration(seconds: 1), () {
                        if (mounted) {
                          setState(() => _round = _round.hideMismatch());
                        }
                      });
                    }
                  },
            child: up
                ? ExcludeSemantics(
                    child: Icon(
                      _icons[value],
                      size: 64,
                      color: RemoriColors.purple,
                    ),
                  )
                : const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}
