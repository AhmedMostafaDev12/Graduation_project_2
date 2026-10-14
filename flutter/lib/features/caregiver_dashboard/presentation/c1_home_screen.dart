import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../core/api/api_providers.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/relay/glasses_connection.dart';
import '../../../core/router/remori_routes.dart';
import '../../../core/theme/remori_theme.dart';
import '../../../core/theme/remori_widgets.dart';
import '../domain/home_data.dart';
import 'home_providers.dart';

final homeClockProvider = StreamProvider.autoDispose<DateTime>(
  (ref) => Stream.periodic(
    const Duration(minutes: 1),
    (_) => DateTime.now().toUtc(),
  ),
);

class C1HomeScreen extends ConsumerStatefulWidget {
  const C1HomeScreen({super.key});
  @override
  ConsumerState<C1HomeScreen> createState() => _C1HomeScreenState();
}

class _C1HomeScreenState extends ConsumerState<C1HomeScreen>
    with WidgetsBindingObserver {
  String? _linkTarget;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      if (mounted) ref.read(homeRefreshProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(homeRefreshProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final identity = ref.watch(caregiverIdentityProvider);
    final data = ref.watch(homeDataProvider);
    final refresh = ref.watch(homeRefreshProvider);
    final patient = ref.watch(selectedHomePatientProvider);
    final loading = identity.isLoading || data.isLoading;
    final failed = identity.hasError || data.hasError || refresh.failed;
    final snapshot = loading || identity.hasError
        ? const HomeData()
        : data.value ?? const HomeData();
    return RefreshIndicator(
      onRefresh: () => _refresh(identity.hasError),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (patient != null && !loading && !identity.hasError)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: RemoriColors.border),
                  ),
                ),
                child: PopupMenuButton<String>(
                  enabled: !refresh.busy,
                  tooltip: s.homeSwitchPatient,
                  onSelected: (id) {
                    ref.read(selectedHomePatientIdProvider.notifier).select(id);
                    ref.read(homeRefreshProvider.notifier).refresh();
                  },
                  itemBuilder: (context) => [
                    for (final p in snapshot.patients)
                      PopupMenuItem(
                        value: p.id,
                        child: Text(p.name, style: _title(context)),
                      ),
                  ],
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: RemoriColors.lavender,
                        child: Text(
                          patient.name
                              .trim()
                              .split(RegExp(r'\s+'))
                              .take(2)
                              .map(
                                (word) => String.fromCharCode(word.runes.first),
                              )
                              .join(),
                          style: _title(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    patient.name,
                                    style: _title(context),
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, size: 18),
                              ],
                            ),
                            Text(s.homeSwitchPatient, style: _small(context)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 10,
                children: [
                  if (loading || (refresh.busy && snapshot.patients.isEmpty))
                    Semantics(
                      label: s.homeLoading,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  if (failed)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            snapshot.patients.isEmpty
                                ? s.homeLoadFailed
                                : s.homeOffline,
                            style: _small(context),
                          ),
                        ),
                        TextButton(
                          onPressed: refresh.busy
                              ? null
                              : () => _refresh(identity.hasError),
                          child: Text(s.homeRetry),
                        ),
                      ],
                    ),
                  if (patient == null && !loading && !refresh.busy && !failed)
                    Text(s.homeNoPatients, style: _small(context)),
                  if (patient != null && !loading && !identity.hasError)
                    ..._cards(
                      context,
                      s,
                      snapshot,
                      patient,
                      failed || refresh.busy,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh(bool reloadIdentity) async {
    if (reloadIdentity) ref.invalidate(caregiverIdentityProvider);
    await ref.read(homeRefreshProvider.notifier).refresh();
  }

  TextStyle? _small(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall
          ?.copyWith(fontFamilyFallback: const ['Readex Pro']);
  TextStyle? _title(BuildContext context) => Theme.of(context)
      .textTheme
      .bodyMedium
      ?.copyWith(
        fontWeight: FontWeight.w600,
        fontFamilyFallback: const ['Readex Pro'],
      );

  List<Widget> _cards(
    BuildContext context,
    AppLocalizations s,
    HomeData data,
    HomePatient patient,
    bool cached,
  ) {
    final devices = data.devices
        .where((d) => d.patientId == patient.id)
        .toList();
    // Prefer an online device, then the most recently seen paired device.
    devices.sort((a, b) {
      if (a.online != b.online) return a.online ? -1 : 1;
      return (b.lastSeen ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
        a.lastSeen ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
    });
    final device = devices.firstOrNull;
    final target = '${patient.id}:${device?.serial}';
    if (_linkTarget != target) {
      _linkTarget = target;
      Future.microtask(() {
        if (mounted) {
          ref.read(homeLinkProvider.notifier).prepare(patient, device);
        }
      });
    }
    final now = ref.watch(homeClockProvider).value ?? DateTime.now().toUtc();
    final link = ref.watch(homeLinkProvider);
    final local =
        device != null &&
        link.serial == device.serial &&
        link.connection == GlassesConnectionState.connected;
    final remote =
        device != null &&
        device.online &&
        device.lastSeen != null &&
        now.difference(device.lastSeen!).inSeconds <= 300;
    final connected =
        device != null && link.serial == device.serial && link.live
        ? local
        : remote;
    final battery = local ? link.battery ?? device.battery : device?.battery;
    final memory = !patient.memoryEnabled
        ? s.homeMemoryOff
        : local && link.paused != null
        ? link.paused!
              ? s.homeMemoryPaused
              : s.homeMemoryCapturing
        : s.homeMemoryEnabled;
    final day = data.days.where((d) => d.patientId == patient.id).firstOrNull;
    final alerts = data.alerts
        .where((a) => a.patientId == patient.id)
        .take(3)
        .toList();
    final numbers = NumberFormat.decimalPattern(
      Localizations.localeOf(context).languageCode,
    );
    final seenMinutes = device?.lastSeen == null
        ? null
        : now.difference(device!.lastSeen!).inMinutes.clamp(0, 2147483647);
    final lastSeen = local
        ? s.homeJustNow
        : seenMinutes == null
        ? s.homeUnknown
        : s.homeMinutesAgo(seenMinutes);
    return [
      InkWell(
        onTap: () => context.goNamed(RemoriScreen.c16.name),
        child: RemoriCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 6,
            children: [
              Row(
                children: [
                  Expanded(child: Text(s.homeGlasses, style: _title(context))),
                  RemoriChip(
                    label: device == null
                        ? s.homeNotPaired
                        : connected
                        ? s.homeConnected
                        : s.homeDisconnected,
                    kind: connected
                        ? RemoriChipKind.success
                        : RemoriChipKind.neutral,
                  ),
                ],
              ),
              Text(
                s.homeDeviceDetail(
                  lastSeen,
                  battery == null
                      ? s.homeUnknown
                      : '${numbers.format(battery)}%',
                ),
                style: _small(context),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: RemoriChip(
                  label: memory,
                  kind: patient.memoryEnabled && local && link.paused == false
                      ? RemoriChipKind.success
                      : RemoriChipKind.neutral,
                ),
              ),
            ],
          ),
        ),
      ),
      RemoriCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 6,
          children: [
            Row(
              children: [
                Expanded(child: Text(s.patientToday, style: _title(context))),
                _link(
                  context,
                  s.homeOpenJournal,
                  () => context.goNamed(RemoriScreen.c12.name),
                ),
              ],
            ),
            if (cached && day != null)
              Text(s.homeCachedDay(day.date), style: _small(context)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _stat(
                  context,
                  day == null ? s.homeUnknown : numbers.format(day.peopleMet),
                  s.homePeopleMet,
                ),
                _stat(
                  context,
                  day == null
                      ? s.homeUnknown
                      : s.homeReminderProgress(
                          numbers.format(day.done),
                          numbers.format(day.total),
                        ),
                  s.homeRemindersDone,
                ),
                _stat(
                  context,
                  day == null ? s.homeUnknown : numbers.format(day.snoozed),
                  s.homeSnoozed,
                  RemoriColors.warningInk,
                ),
              ],
            ),
          ],
        ),
      ),
      RemoriCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 6,
          children: [
            Row(
              children: [
                Expanded(child: Text(s.homeAlerts, style: _title(context))),
                _link(
                  context,
                  s.homeSeeAll,
                  () => context.goNamed(RemoriScreen.c2.name),
                ),
              ],
            ),
            if (alerts.isEmpty) Text(s.homeNoAlerts, style: _small(context)),
            for (final alert in alerts)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RemoriChip(
                    label: switch (alert.type) {
                      'missed_medication' => s.homeMissed,
                      'unknown_person_flagged' => s.homeNewFace,
                      'low_battery' => s.homeLowBattery,
                      'device_offline' => s.homeDisconnected,
                      'daily_summary_ready' => s.homeSummary,
                      _ => s.homeAlert,
                    },
                    kind: alert.type == 'missed_medication'
                        ? RemoriChipKind.danger
                        : const [
                            'unknown_person_flagged',
                            'low_battery',
                            'device_offline',
                          ].contains(alert.type)
                        ? RemoriChipKind.warning
                        : RemoriChipKind.neutral,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(alert.message, style: _small(context))),
                ],
              ),
          ],
        ),
      ),
      RemoriCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 6,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(s.homeDailySummary, style: _title(context)),
                ),
                RemoriChip(
                  label: s.homePhaseTwo,
                  kind: RemoriChipKind.phaseTwo,
                ),
              ],
            ),
            Text(s.homeSummaryUnavailable, style: _small(context)),
            Semantics(
              enabled: false,
              child: Text(
                s.homeReadMore,
                style: _small(context)
                    ?.copyWith(color: RemoriColors.ink.withValues(alpha: .45)),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _link(BuildContext context, String label, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            label,
            style: _small(context)?.copyWith(
              color: RemoriColors.purple,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      );
  Widget _stat(
    BuildContext context,
    String value,
    String label, [
    Color? color,
  ]) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          textDirection: TextDirection.ltr,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(label, style: _small(context)),
      ],
    ),
  );
}
