import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/remori_routes.dart';
import '../domain/patient_today_data.dart';
import 'patient_today_providers.dart';

/// An in-memory app-session receipt, scoped by patient, device and due time.
final patientAlertSessionProvider =
    NotifierProvider<PatientAlertSession, Set<PatientReminderAlertTarget>>(
      PatientAlertSession.new,
    );

class PatientAlertSession extends Notifier<Set<PatientReminderAlertTarget>> {
  @override
  Set<PatientReminderAlertTarget> build() => {};
  bool claim(PatientReminderAlertTarget target) {
    if (state.contains(target)) return false;
    state = {...state, target};
    return true;
  }
}

/// Injectable candidate selection also keeps older screen fixtures isolated.
final patientAlertCandidateProvider =
    Provider.autoDispose<PatientReminderAlertTarget?>((ref) {
      final key = ref.watch(patientTodayKeyProvider);
      if (key == null) return null;
      final snapshot = ref.watch(patientTodayDataProvider(key));
      if (snapshot.isLoading || snapshot.hasError) return null;
      final data = snapshot.value;
      final next = data?.next;
      final now =
          ref.watch(patientTodayNowProvider).value ??
          ref.watch(patientTodayClockProvider)();
      if (data?.settings == null ||
          next == null ||
          !{'pending', 'snoozed'}.contains(next.status) ||
          next.dueAt.isAfter(now)) {
        return null;
      }
      if (ref.watch(patientTodayControllerProvider(key)).busy) return null;
      return (scope: key, id: next.id, dueAt: next.dueAt);
    });

class PatientReminderAlertHost extends ConsumerStatefulWidget {
  const PatientReminderAlertHost({
    super.key,
    required this.screen,
    required this.child,
  });
  final RemoriScreen screen;
  final Widget child;
  @override
  ConsumerState<PatientReminderAlertHost> createState() =>
      _PatientReminderAlertHostState();
}

class _PatientReminderAlertHostState
    extends ConsumerState<PatientReminderAlertHost>
    with WidgetsBindingObserver {
  bool _foreground = false;
  bool _scheduled = false;
  @override
  void initState() {
    super.initState();
    _foreground =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() => _foreground = state == AppLifecycleState.resumed);
  }

  @override
  Widget build(BuildContext context) {
    final eligible =
        widget.screen == RemoriScreen.p1 || widget.screen == RemoriScreen.p2;
    final candidate = eligible && _foreground
        ? ref.watch(patientAlertCandidateProvider)
        : null;
    final seen = ref.watch(patientAlertSessionProvider);
    if (candidate != null && !seen.contains(candidate) && !_scheduled) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scheduled = false;
        if (!mounted ||
            !_foreground ||
            (widget.screen != RemoriScreen.p1 &&
                widget.screen != RemoriScreen.p2)) {
          return;
        }
        final router = GoRouter.of(context);
        final path = router.routeInformationProvider.value.uri.path;
        if (path != RemoriScreen.p1.path && path != RemoriScreen.p2.path) {
          return;
        }
        if (ref.read(patientTodayKeyProvider) != candidate.scope ||
            ref.read(patientAlertCandidateProvider) != candidate) {
          return;
        }
        if (ref.read(patientAlertSessionProvider.notifier).claim(candidate)) {
          context.goNamed(RemoriScreen.p3.name, extra: candidate);
        }
      });
    }
    return widget.child;
  }
}
