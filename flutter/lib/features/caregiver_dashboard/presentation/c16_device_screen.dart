import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/remori_routes.dart';
import '../../../core/theme/remori_theme.dart';
import '../../../core/theme/remori_widgets.dart';
import '../domain/home_data.dart';
import 'device_providers.dart';
import 'home_providers.dart';

class C16DeviceScreen extends ConsumerStatefulWidget {
  const C16DeviceScreen({super.key});
  @override
  ConsumerState<C16DeviceScreen> createState() => _C16DeviceScreenState();
}

class _C16DeviceScreenState extends ConsumerState<C16DeviceScreen>
    with WidgetsBindingObserver {
  bool _confirming = false;
  bool _visible = true;
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
    final scope = ref.read(deviceScopeProvider);
    if (state == AppLifecycleState.resumed && scope != null) {
      ref.invalidate(deviceNowProvider);
      ref.read(deviceControllerProvider(scope).notifier).refresh();
    }
  }

  Future<void> _unpair(DeviceScope scope, HomeDevice device) async {
    if (_confirming ||
        !ref.read(deviceControllerProvider(scope).notifier).canWrite) {
      return;
    }
    setState(() => _confirming = true);
    final s = AppLocalizations.of(context);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.deviceUnpair),
        content: Text(s.deviceUnpairConfirm(device.serial)),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(s.deviceUnpair),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _confirming = false);
    if (accepted != true || ref.read(deviceScopeProvider) != scope) return;
    final success = await ref
        .read(deviceControllerProvider(scope).notifier)
        .change(unpairId: device.id);
    if (mounted && success && ref.read(deviceScopeProvider) == scope) {
      context.goNamed(RemoriScreen.a1.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context),
        scope = ref.watch(deviceScopeProvider);
    final snapshot = ref.watch(homeDataProvider);
    final data = scope == null || snapshot.isLoading || snapshot.hasError
        ? const HomeData()
        : snapshot.value ?? const HomeData();
    final patient = data.patients.where((p) => p.id == scope?.$2).firstOrNull;
    final devices = data.devices.where((d) => d.patientId == scope?.$2).toList()
      ..sort(
        (a, b) => (b.pairedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.pairedAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
    final state = scope == null
        ? const DeviceState()
        : ref.watch(deviceControllerProvider(scope));
    final visible = ModalRoute.isCurrentOf(context) ?? true;
    if (visible != _visible) {
      _visible = visible;
      if (visible && scope != null) {
        Future.microtask(() {
          if (mounted && ref.read(deviceScopeProvider) == scope) {
            ref.read(deviceControllerProvider(scope).notifier).refresh();
          }
        });
      }
    }
    final writable =
        scope != null &&
        patient?.permission == 'manager' &&
        !state.busy &&
        !state.pending &&
        !state.uncertain &&
        !_confirming;
    final tick = ref.watch(deviceNowProvider);
    final now = tick.value ?? ref.watch(deviceClockProvider)();
    final locale = Localizations.localeOf(context).languageCode;
    String seen(DateTime? time) {
      if (time == null) return s.deviceUnknown;
      final minutes = now.difference(time).inMinutes;
      if (minutes < 1) return s.deviceJustNow;
      if (minutes < 60) return s.deviceMinutesAgo(minutes);
      if (minutes < 1440) return s.deviceHoursAgo(minutes ~/ 60);
      return s.deviceDaysAgo(minutes ~/ 1440);
    }

    Widget row(String label, String value, {bool last = false}) => Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFE6DFF2))),
      ),
      child: Builder(
        builder: (context) {
          final name = Text(label, style: _sub.copyWith(fontSize: 14));
          final content = Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          );
          return MediaQuery.textScalerOf(context).scale(14) > 21
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [name, const SizedBox(height: 6), content],
                )
              : Row(
                  children: [
                    Expanded(child: name),
                    const SizedBox(width: 12),
                    Expanded(child: content),
                  ],
                );
        },
      ),
    );
    Widget unpair(HomeDevice device) => TextButton(
      onPressed: writable ? () => _unpair(scope, device) : null,
      style: TextButton.styleFrom(foregroundColor: const Color(0xFFA6412A)),
      child: Text(s.deviceUnpair),
    );
    Widget card(HomeDevice device) {
      final connected =
          state.loaded &&
          !state.failed &&
          device.online &&
          device.lastSeen != null &&
          now.difference(device.lastSeen!) < const Duration(minutes: 5) &&
          !device.lastSeen!.isAfter(now);
      final label = !state.loaded || state.failed
          ? s.deviceStatusUnavailable
          : connected
          ? s.deviceConnected
          : s.deviceOffline;
      return _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(s.deviceGlasses, style: _heading),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: connected
                        ? RemoriColors.success
                        : RemoriColors.lavender,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Text(label, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            row(s.deviceSerial, device.serial),
            row(
              s.deviceFirmware,
              device.firmware?.isNotEmpty == true
                  ? device.firmware!
                  : s.deviceUnknown,
            ),
            row(
              s.deviceBattery,
              device.battery == null
                  ? s.deviceUnknown
                  : NumberFormat.percentPattern(locale)
                        .format(device.battery! / 100),
            ),
            row(s.deviceLastSeen, seen(device.lastSeen), last: true),
            if (devices.length > 1 && patient?.permission == 'manager')
              unpair(device),
          ],
        ),
      );
    }

    return SafeArea(
      bottom: false,
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
                    tooltip: MaterialLocalizations.of(context)
                        .backButtonTooltip,
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.chevron_left, size: 26),
                    onPressed: () => context.goNamed(RemoriScreen.c18.name),
                  ),
                ),
                Expanded(
                  child: Text(
                    s.deviceTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (scope != null) {
                  await ref
                      .read(deviceControllerProvider(scope).notifier)
                      .refresh();
                }
              },
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 26).clamp(
                        0,
                        double.infinity,
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (scope == null || patient == null)
                            Text(s.deviceUnavailable, style: _sub)
                          else ...[
                            if (state.failed) ...[
                              Text(
                                state.pending
                                    ? s.deviceSavedLocallyPending
                                    : state.uncertain
                                    ? s.deviceUncertain
                                    : s.deviceLoadFailed,
                                style: _sub,
                              ),
                              TextButton(
                                onPressed: state.busy
                                    ? null
                                    : () => ref
                                          .read(
                                            deviceControllerProvider(scope)
                                                .notifier,
                                          )
                                          .refresh(),
                                child: Text(s.homeRetry),
                              ),
                            ],
                            if (state.busy) const LinearProgressIndicator(),
                            for (final device in devices) ...[
                              card(device),
                              const SizedBox(height: 12),
                            ],
                            if (devices.isEmpty && !state.busy) ...[
                              Text(s.deviceNone, style: _sub),
                              const SizedBox(height: 12),
                            ],
                            _card(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          s.deviceMemory,
                                          style: _heading,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Switch(
                                        value: patient.memoryEnabled,
                                        onChanged: writable
                                            ? (value) => ref
                                                  .read(
                                                    deviceControllerProvider(
                                                      scope,
                                                    ).notifier,
                                                  )
                                                  .change(memoryEnabled: value)
                                            : null,
                                      ),
                                    ],
                                  ),
                                  Text(s.deviceMemoryHelp, style: _sub),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(s.deviceHeartbeatHelp, style: _sub),
                            const Spacer(),
                            const SizedBox(height: 20),
                            if (patient.permission == 'manager') ...[
                              RemoriButton(
                                label: s.deviceRepair,
                                outlined: true,
                                onPressed: writable
                                    ? () => context.pushNamed(
                                        RemoriScreen.a5.name,
                                        extra: scope.$2,
                                      )
                                    : null,
                              ),
                              if (devices.length == 1) unpair(devices.single),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _card(Widget child) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  decoration: BoxDecoration(
    color: RemoriColors.surface,
    border: Border.all(color: RemoriColors.border),
    borderRadius: BorderRadius.circular(10),
  ),
  child: child,
);
const _heading = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
const _sub = TextStyle(
  fontSize: 13,
  height: 1.3,
  color: RemoriColors.muted,
  fontFamilyFallback: ['Readex Pro'],
);
