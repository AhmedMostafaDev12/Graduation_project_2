import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/remori_routes.dart';
import '../../../core/theme/remori_theme.dart';
import '../../../core/theme/remori_widgets.dart';
import '../../patient_today/presentation/patient_today_providers.dart';
import '../../reminders/domain/reminder_data.dart';
import '../domain/patient_memory_detail.dart';
import 'patient_memory_providers.dart';

class P5MemoryDetailScreen extends ConsumerStatefulWidget {
  const P5MemoryDetailScreen({super.key, this.target});
  final PatientMemoryTarget? target;
  @override
  ConsumerState<P5MemoryDetailScreen> createState() =>
      _P5MemoryDetailScreenState();
}

class _P5MemoryDetailScreenState extends ConsumerState<P5MemoryDetailScreen>
    with WidgetsBindingObserver {
  bool _foreground = true, _visible = true, _confirming = false;
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
    final target = widget.target;
    if (!mounted || target == null) return;
    final c = ref.read(patientMemoryControllerProvider(target).notifier);
    if (_foreground && _visible) {
      c.refresh();
    } else {
      c.hidePhotos();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() => _foreground = state == AppLifecycleState.resumed);
    _visibility();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(RemoriScreen.p4.name);
    }
  }

  Future<void> _delete(
    PatientMemoryTarget target, {
    bool cleanup = false,
  }) async {
    if (!cleanup) {
      final s = AppLocalizations.of(context);
      _confirming = true;
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: Text(
            s.patientMemoryDeleteTitle,
            style: const TextStyle(fontSize: 30),
          ),
          content: Text(
            s.patientMemoryDeleteConfirm,
            style: const TextStyle(fontSize: 22),
          ),
          actions: [
            RemoriButton(
              label: s.patientMemoryKeep,
              outlined: true,
              onPressed: () => Navigator.pop(context, false),
            ),
            const SizedBox(height: 12),
            RemoriButton(
              label: s.patientMemoryDelete,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );
      _confirming = false;
      if (accepted != true) return;
    }
    if (!mounted || ref.read(patientTodayKeyProvider) != target.journal.$1) {
      return;
    }
    final removed = await ref
        .read(patientMemoryControllerProvider(target).notifier)
        .remove();
    if (mounted && removed) _back();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _confirming || (ModalRoute.isCurrentOf(context) ?? true);
    if (visible != _visible) {
      _visible = visible;
      Future.microtask(_visibility);
    }
    final s = AppLocalizations.of(context), target = widget.target;
    final active =
        target != null &&
        ref.watch(patientTodayKeyProvider) == target.journal.$1;
    final state = active
        ? ref.watch(patientMemoryControllerProvider(target))
        : const PatientMemoryState(missing: true);
    final snapshot = active
        ? ref.watch(patientMemoryDataProvider(target))
        : null;
    final detail = state.missing
        ? null
        : snapshot?.isLoading == false && snapshot?.hasError == false
        ? snapshot?.value
        : null;
    final liveKey = target == null ? null : (target, state.revision);
    final live =
        active &&
        _foreground &&
        _visible &&
        state.fresh != null &&
        ref.watch(patientMemoryPhotoLiveProvider(liveKey!)).value == true;
    final photo = live && detail?.type == 'image'
        ? ref.watch(patientMemoryPhotoProvider(liveKey))
        : null;
    if (photo?.hasError == true) {
      Future.microtask(() {
        if (mounted && active) {
          ref
              .read(patientMemoryControllerProvider(target).notifier)
              .photoFailed(photo!.error!);
        }
      });
    }
    final placeholder = Container(
      color: RemoriColors.lavender,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Text(
        detail?.type == 'video'
            ? s.patientMemoryVideoPending
            : s.patientMemoryPhotoUnavailable,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22),
      ),
    );
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
                  Align(
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
                  const SizedBox(height: 16),
                  if (detail != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        height: 380,
                        child: photo?.value != null && photo?.hasError == false
                            ? Image.memory(
                                photo!.value!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => placeholder,
                              )
                            : placeholder,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      detail.eventType == 'encounter' && detail.person != null
                          ? s.patientMemoryMet(detail.person!.name)
                          : s.patientMemoryTitle,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      DateFormat.yMMMMEEEEd(
                        Localizations.localeOf(context).languageCode,
                      ).add_jm().format(
                        PatientTime.local(detail.at, target!.journal.$3),
                      ),
                      style: const TextStyle(
                        fontSize: 22,
                        color: RemoriColors.muted,
                      ),
                    ),
                  ] else
                    Text(
                      state.busy
                          ? s.todayGettingReady
                          : s.patientMemoryUnavailable,
                      style: const TextStyle(fontSize: 22),
                    ),
                  if (state.failed ||
                      snapshot?.hasError == true ||
                      state.uncertain) ...[
                    const SizedBox(height: 16),
                    Text(
                      state.acknowledged
                          ? s.patientMemoryRemovedPending
                          : state.uncertain
                          ? s.patientMemoryUncertain
                          : s.patientDayOffline,
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(height: 12),
                    RemoriButton(
                      label: s.homeRetry,
                      outlined: true,
                      onPressed: !active || state.busy
                          ? null
                          : () {
                              if (state.acknowledged) {
                                _delete(target, cleanup: true);
                              } else {
                                ref
                                    .read(
                                      patientMemoryControllerProvider(target)
                                          .notifier,
                                    )
                                    .refresh();
                              }
                            },
                    ),
                  ],
                  const Spacer(),
                  const SizedBox(height: 24),
                  if (detail != null && !state.acknowledged) ...[
                    RemoriButton(
                      label: s.patientMemoryDelete,
                      outlined: true,
                      onPressed:
                          !active ||
                              state.busy ||
                              state.uncertain ||
                              state.fresh == null ||
                              detail.expired(
                                ref.watch(patientTodayClockProvider)(),
                              )
                          ? null
                          : () => _delete(target),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.patientMemoryDeleteHelp,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        color: RemoriColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
