import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/remori_routes.dart';
import '../../../core/theme/remori_theme.dart';
import '../../../core/theme/remori_widgets.dart';
import '../../reminders/domain/reminder_data.dart';
import '../domain/patient_today_data.dart';
import 'patient_today_providers.dart';

class P3ReminderAlertScreen extends ConsumerStatefulWidget {
  const P3ReminderAlertScreen({super.key, this.target});
  final PatientReminderAlertTarget? target;
  @override
  ConsumerState<P3ReminderAlertScreen> createState() =>
      _P3ReminderAlertScreenState();
}

class _P3ReminderAlertScreenState extends ConsumerState<P3ReminderAlertScreen> {
  bool _saving = false, _saveFailed = false;
  void _back() => context.goNamed(RemoriScreen.p2.name);
  Future<void> _confirm(bool snooze) async {
    final target = widget.target;
    if (target == null ||
        _saving ||
        ref.read(patientTodayKeyProvider) != target.scope) {
      return;
    }
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    final saved = await ref
        .read(patientTodayControllerProvider(target.scope).notifier)
        .confirmAlert(target, snooze: snooze);
    if (!mounted) return;
    if (ref.read(patientTodayKeyProvider) != target.scope) {
      setState(() => _saving = false);
      return;
    }
    if (saved) {
      _back();
    } else {
      setState(() {
        _saving = false;
        _saveFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context), target = widget.target;
    final key = ref.watch(patientTodayKeyProvider);
    final scoped = key != null && key == target?.scope;
    final snapshot = scoped ? ref.watch(patientTodayDataProvider(key)) : null;
    final data = snapshot == null || snapshot.isLoading || snapshot.hasError
        ? null
        : snapshot.value;
    final next = data?.next;
    final state = scoped
        ? ref.watch(patientTodayControllerProvider(key))
        : const PatientTodayState();
    final now =
        ref.watch(patientTodayNowProvider).value ??
        ref.watch(patientTodayClockProvider)();
    final valid =
        scoped &&
        target != null &&
        data?.settings != null &&
        next != null &&
        next.id == target.id &&
        next.dueAt == target.dueAt &&
        !next.dueAt.isAfter(now) &&
        {'pending', 'snoozed'}.contains(next.status);
    if (!_saving && scoped && data?.settings != null && !valid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            !_saving &&
            ref.read(patientTodayKeyProvider) == target?.scope) {
          _back();
        }
      });
    }
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (valid) ...[
                            ExcludeSemantics(
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF4A261),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: next.type == 'medication'
                                    ? SvgPicture.string(
                                        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="9" width="18" height="6" rx="3" transform="rotate(-45 12 12)"/><path d="M9.5 9.5l5 5"/></svg>',
                                        key: const Key('patient-alert-pill'),
                                        width: 72,
                                        height: 72,
                                      )
                                    : const Icon(
                                        Icons.notifications_none,
                                        key: Key('patient-alert-bell'),
                                        size: 72,
                                        color: Colors.white,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                s.patientAlertTitle(next.title),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              DateFormat.jm(
                                Localizations.localeOf(context).languageCode,
                              ).format(
                                PatientTime.local(
                                  next.dueAt,
                                  data!.settings!.timezone,
                                ),
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                color: RemoriColors.muted,
                              ),
                            ),
                          ] else
                            Text(
                              snapshot?.isLoading == true
                                  ? s.todayGettingReady
                                  : s.patientAlertUnavailable,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 30),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_saveFailed) ...[
                    Text(
                      s.patientAlertSaveFailed,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (valid) ...[
                    RemoriButton(
                      label: s.todayDone,
                      onPressed: _saving || state.busy
                          ? null
                          : () => _confirm(false),
                    ),
                    const SizedBox(height: 14),
                    RemoriButton(
                      label: s.todayLater,
                      outlined: true,
                      onPressed: _saving || state.busy
                          ? null
                          : () => _confirm(true),
                    ),
                  ] else
                    RemoriButton(
                      label: s.patientAlertBack,
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
}
