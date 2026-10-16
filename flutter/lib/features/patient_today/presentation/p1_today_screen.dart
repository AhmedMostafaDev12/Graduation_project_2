import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/remori_routes.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/remori_theme.dart';
import '../../../core/theme/remori_widgets.dart';
import '../../reminders/domain/reminder_data.dart';
import '../domain/patient_today_data.dart';
import 'patient_today_providers.dart';

class P1TodayScreen extends ConsumerStatefulWidget {
  const P1TodayScreen({super.key});
  @override
  ConsumerState<P1TodayScreen> createState() => _P1TodayScreenState();
}

class _P1TodayScreenState extends ConsumerState<P1TodayScreen>
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

  Future<void> _refresh() async {
    final key = ref.read(patientTodayKeyProvider);
    if (key != null) {
      await ref.read(patientTodayControllerProvider(key).notifier).refresh();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context),
        key = ref.watch(patientTodayKeyProvider);
    final snapshot = key == null
        ? null
        : ref.watch(patientTodayDataProvider(key));
    final data = snapshot == null || snapshot.isLoading || snapshot.hasError
        ? const PatientTodayData()
        : snapshot.value ?? const PatientTodayData();
    final state = key == null
        ? const PatientTodayState()
        : ref.watch(patientTodayControllerProvider(key));
    final now =
        ref.watch(patientTodayNowProvider).value ??
        ref.watch(patientTodayClockProvider)();
    final locale = Localizations.localeOf(context).languageCode,
        settings = data.settings;
    final link =
        ref.watch(patientLinkProvider).value ?? const PatientLinkStatus();
    final reconnect = ref.watch(patientReconnectProvider);
    ref.listen(patientTodayNowProvider, (old, next) {
      if (key == null ||
          settings == null ||
          old?.value == null ||
          next.value == null) {
        return;
      }
      if (PatientTime.day(old!.value!, settings.timezone) !=
          PatientTime.day(next.value!, settings.timezone)) {
        _refresh();
      }
    });
    String memory() {
      if (settings?.memoryEnabled == false) return s.todayMemoryOff;
      if (settings == null || !link.connected || link.paused == null) {
        return s.todayMemoryUnknown;
      }
      return link.paused! ? s.todayMemoryPaused : s.todayMemoryOn;
    }

    Widget status(String label, bool positive) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: positive ? RemoriColors.success : RemoriColors.surface,
        border: Border.all(color: RemoriColors.purple),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 22, color: RemoriColors.ink),
      ),
    );
    final next = data.next;
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) => RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 46).clamp(
                  0,
                  double.infinity,
                ),
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (settings != null) ...[
                      Text(
                        DateFormat.jm(locale)
                            .format(PatientTime.local(now, settings.timezone)),
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'EEEE d MMMM',
                          locale,
                        ).format(PatientTime.local(now, settings.timezone)),
                        style: const TextStyle(
                          fontSize: 22,
                          color: RemoriColors.muted,
                        ),
                      ),
                    ] else
                      Text(
                        s.todayGettingReady,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 14),
                    if (!link.connected)
                      Container(
                        key: const Key('d5-disconnected'),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: RemoriColors.warning,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              s.todayGlassesDisconnected,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w600,
                                color: RemoriColors.warningInk,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              s.todayGlassesCheck,
                              style: const TextStyle(
                                fontSize: 22,
                                color: RemoriColors.warningInk,
                              ),
                            ),
                            if (reconnect.offline) ...[
                              const SizedBox(height: 12),
                              Text(
                                s.todayReconnectUnavailable,
                                style: const TextStyle(
                                  fontSize: 22,
                                  color: RemoriColors.warningInk,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            RemoriButton(
                              label: s.todayTryAgain,
                              outlined: true,
                              onPressed: reconnect.busy
                                  ? null
                                  : () => ref
                                        .read(patientReconnectProvider.notifier)
                                        .retry(),
                            ),
                          ],
                        ),
                      )
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          status(
                            link.connected
                                ? s.todayGlassesConnected
                                : s.todayGlassesAway,
                            link.connected,
                          ),
                          status(
                            memory(),
                            settings?.memoryEnabled == true &&
                                link.connected &&
                                link.paused == false,
                          ),
                        ],
                      ),
                    const SizedBox(height: 14),
                    if (state.offline || snapshot?.hasError == true) ...[
                      Text(
                        s.todayOffline,
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1E0),
                        border: Border.all(
                          color: const Color(0xFFF4A261),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            s.todayNextReminder,
                            style: const TextStyle(
                              fontSize: 22,
                              color: RemoriColors.muted,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            next == null || settings == null
                                ? state.busy || settings == null
                                      ? s.todayGettingReady
                                      : s.todayNoReminder
                                : '${next.title} · ${DateFormat.jm(locale).format(PatientTime.local(next.dueAt, settings.timezone))}',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (next != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: RemoriButton(
                                    label: s.todayDone,
                                    onPressed: state.busy || key == null
                                        ? null
                                        : () => ref
                                              .read(
                                                patientTodayControllerProvider(
                                                  key,
                                                ).notifier,
                                              )
                                              .act(next.id, snooze: false),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: RemoriButton(
                                    label: s.todayLater,
                                    outlined: true,
                                    onPressed: state.busy || key == null
                                        ? null
                                        : () => ref
                                              .read(
                                                patientTodayControllerProvider(
                                                  key,
                                                ).notifier,
                                              )
                                              .act(next.id, snooze: true),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      s.todayPeopleMet,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (data.people.isEmpty)
                      Text(
                        s.todayNoPeople,
                        style: const TextStyle(fontSize: 22),
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final person in data.people)
                            Expanded(
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 36,
                                    backgroundColor: RemoriColors.lavender,
                                    child: Text(
                                      person.name
                                          .trim()
                                          .split(RegExp(r'\s+'))
                                          .take(2)
                                          .map((word) => word.characters.first)
                                          .join(),
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    person.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    const Spacer(),
                    const SizedBox(height: 24),
                    RemoriButton(
                      label: s.todayAskLater,
                      outlined: true,
                      onPressed: () => context.pushNamed(RemoriScreen.p6.name),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
