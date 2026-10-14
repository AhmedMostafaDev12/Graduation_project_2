import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../../core/l10n/app_localizations.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/router/remori_routes.dart';
import '../../../core/theme/remori_theme.dart';
import '../../../core/theme/remori_widgets.dart';
import '../../reminders/domain/reminder_data.dart';
import '../domain/home_data.dart';
import 'alerts_providers.dart';
import 'home_providers.dart';

class C2AlertsScreen extends ConsumerStatefulWidget {
  const C2AlertsScreen({super.key});
  @override
  ConsumerState<C2AlertsScreen> createState() => _C2AlertsScreenState();
}

class _C2AlertsScreenState extends ConsumerState<C2AlertsScreen>
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
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(alertsNowProvider);
      ref.read(alertsControllerProvider.notifier).refresh();
    }
  }

  Future<void> _tap(HomeAlert alert) async {
    final owner = ref.read(alertsOwnerProvider);
    final success = await ref
        .read(alertsControllerProvider.notifier)
        .open(alert);
    if (!mounted || !success || owner != ref.read(alertsOwnerProvider)) return;
    final snapshot = ref.read(homeDataProvider);
    if (snapshot.isLoading ||
        snapshot.hasError ||
        !(snapshot.value?.patients.any((p) => p.id == alert.patientId) ??
            false)) {
      return;
    }
    if (alert.type == 'missed_medication' &&
        alert.entityType == 'reminder_log' &&
        alert.entityId != null) {
      ref.read(selectedHomePatientIdProvider.notifier).select(alert.patientId);
      context.goNamed(RemoriScreen.c8.name);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).alertsDestinationPending),
        ),
      );
    }
  }

  Future<void> _refresh() async {
    if (ref.read(caregiverIdentityProvider).hasError) {
      ref.invalidate(caregiverIdentityProvider);
    }
    await ref.read(alertsControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context),
        owner = ref.watch(alertsOwnerProvider);
    final identity = ref.watch(caregiverIdentityProvider);
    final state = ref.watch(alertsControllerProvider),
        snapshot = ref.watch(homeDataProvider);
    final data = owner == null || snapshot.isLoading || snapshot.hasError
        ? const HomeData()
        : snapshot.value ?? const HomeData();
    final patients = {for (final p in data.patients) p.id: p};
    final alerts =
        data.alerts.where((a) => patients.containsKey(a.patientId)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final locale = Localizations.localeOf(context).languageCode;
    final tick = ref.watch(alertsNowProvider);
    final now = tick.isLoading
        ? ref.watch(alertsClockProvider)()
        : tick.value ?? ref.watch(alertsClockProvider)();
    final groups = <String, List<HomeAlert>>{};
    final dates = <String, DateTime>{};
    for (final alert in alerts) {
      final zone = patients[alert.patientId]!.timezone;
      final local = PatientTime.local(alert.createdAt, zone),
          today = PatientTime.local(now, zone);
      final date = DateTime(local.year, local.month, local.day),
          todayDate = DateTime(today.year, today.month, today.day);
      final label = date == todayDate
          ? s.alertsToday
          : date == DateTime(today.year, today.month, today.day - 1)
          ? s.alertsYesterday
          : DateFormat.yMMMd(locale).format(date);
      groups.putIfAbsent(label, () => []).add(alert);
      dates[label] = date;
    }
    int rank(String label) => label == s.alertsToday
        ? 0
        : label == s.alertsYesterday
        ? 1
        : 2;
    final sections = groups.entries.toList()
      ..sort((a, b) {
        final order = rank(a.key).compareTo(rank(b.key));
        return order != 0 ? order : dates[b.key]!.compareTo(dates[a.key]!);
      });
    final enabled = owner != null && !state.busy && !state.pending;
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: RemoriColors.border)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  height: 38,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: MaterialLocalizations.of(context)
                        .backButtonTooltip,
                    onPressed: () => context.goNamed(RemoriScreen.c1.name),
                    icon: const Icon(Icons.chevron_left, size: 26),
                  ),
                ),
                Expanded(
                  child: Text(
                    s.alertsTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  fit: FlexFit.tight,
                  child: Text(
                    s.alertsUnread(
                      NumberFormat.decimalPattern(locale)
                          .format(alerts.where((a) => a.readAt == null).length),
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      color: RemoriColors.muted,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (state.failure != null ||
                      snapshot.hasError ||
                      identity.hasError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            state.pending
                                ? s.alertsCacheRetry
                                : state.readFailure
                                ? s.alertsReadFailed
                                : alerts.isNotEmpty
                                ? s.alertsCached
                                : s.alertsLoadFailed,
                            style: const TextStyle(
                              fontSize: 13,
                              color: RemoriColors.dangerInk,
                            ),
                          ),
                          TextButton(
                            onPressed: state.busy ? null : _refresh,
                            child: Text(s.homeRetry),
                          ),
                        ],
                      ),
                    ),
                  if (alerts.isEmpty &&
                      (state.busy || snapshot.isLoading || identity.isLoading))
                    const Center(child: CircularProgressIndicator())
                  else if (alerts.isEmpty)
                    Text(s.alertsNone),
                  for (final group in sections) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Text(
                        group.key,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: RemoriColors.muted,
                        ),
                      ),
                    ),
                    for (final alert in group.value)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _card(
                          context,
                          alert,
                          patients[alert.patientId]!,
                          enabled,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context,
    HomeAlert alert,
    HomePatient patient,
    bool enabled,
  ) {
    final s = AppLocalizations.of(context),
        locale = Localizations.localeOf(context).languageCode;
    final label = switch (alert.type) {
      'unknown_person_flagged' => s.alertsSomeoneNew,
      'low_battery' => s.alertsLowBattery,
      'missed_medication' => s.alertsMissedMedication,
      'device_offline' => s.alertsDeviceOffline,
      'daily_summary_ready' => s.alertsSummaryReady,
      _ => s.homeAlert,
    };
    final name = '\u2068${patient.name}\u2069';
    final description = switch (alert.type) {
      'unknown_person_flagged' => s.alertsUnknownDescription(name),
      'low_battery' => s.alertsBatteryDescription(name),
      'missed_medication' => s.alertsMissedDescription(name),
      'device_offline' => s.alertsOfflineDescription(name),
      'daily_summary_ready' => s.alertsSummaryDescription(name),
      _ => s.alertsOtherDescription(name),
    };
    return Material(
      color: RemoriColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: RemoriColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('alert-${alert.id}'),
        onTap: enabled ? () => _tap(alert) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: SizedBox(
                  width: 8,
                  height: 8,
                  child: alert.readAt == null
                      ? const DecoratedBox(
                          decoration: BoxDecoration(
                            color: RemoriColors.purple,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        DefaultTextStyle.merge(
                          style: const TextStyle(
                            fontFamilyFallback: ['DM Sans', 'Readex Pro'],
                          ),
                          child: RemoriChip(
                            label: label,
                            kind: switch (alert.type) {
                              'missed_medication' ||
                              'device_offline' => RemoriChipKind.danger,
                              'unknown_person_flagged' ||
                              'low_battery' => RemoriChipKind.warning,
                              _ => RemoriChipKind.neutral,
                            },
                          ),
                        ),
                        Text(
                          DateFormat.Hm(locale).format(
                            PatientTime.local(
                              alert.createdAt,
                              patient.timezone,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: RemoriColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        fontFamilyFallback: ['DM Sans', 'Readex Pro'],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
