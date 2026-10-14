import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/remori_routes.dart';
import '../../../core/theme/remori_theme.dart';
import '../../../core/theme/remori_widgets.dart';
import '../../caregiver_dashboard/presentation/home_providers.dart';
import '../domain/reminder_data.dart';
import 'reminders_providers.dart';

class C8RemindersScreen extends ConsumerStatefulWidget {
  const C8RemindersScreen({super.key});
  @override
  ConsumerState<C8RemindersScreen> createState() => _C8RemindersScreenState();
}

class _C8RemindersScreenState extends ConsumerState<C8RemindersScreen>
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
      ref.invalidate(reminderNowProvider);
      ref.read(remindersControllerProvider.notifier).refresh();
    }
  }

  void _edit(ReminderScope scope, [String? id]) => context.pushNamed(
    RemoriScreen.c9.name,
    extra: {'patient_id': scope.patientId, 'reminder_id': ?id},
  );
  String _time(DateTime instant, String timezone) =>
      DateFormat.Hm(Localizations.localeOf(context).languageCode)
          .format(PatientTime.local(instant, timezone));
  String _schedule(CaregiverReminder reminder, ReminderScope scope) {
    final s = AppLocalizations.of(context),
        parsed = SimpleReminderSchedule.parse(reminder, scope.timezone);
    if (parsed == null) return s.reminderCustomSchedule;
    final locale = Localizations.localeOf(context).languageCode;
    final times = parsed.minutes
        .map(
          (v) =>
              DateFormat.Hm(locale)
                  .format(DateTime(2000, 1, 1, v ~/ 60, v % 60)),
        )
        .toList();
    String join(List<String> values) => values.length == 1
        ? values.single
        : s.reminderJoin(
            values.take(values.length - 1).join(locale == 'ar' ? '، ' : ', '),
            values.last,
          );
    final text = join(times);
    if (parsed.weekdays.isEmpty) return s.reminderDaily(text);
    final days = [
      s.reminderMonday,
      s.reminderTuesday,
      s.reminderWednesday,
      s.reminderThursday,
      s.reminderFriday,
      s.reminderSaturday,
      s.reminderSunday,
    ];
    return s.reminderWeekly(
      join(parsed.weekdays.map((v) => days[v - 1]).toList()),
      text,
    );
  }

  Widget _status(ReminderOccurrence log, ReminderScope scope) {
    final s = AppLocalizations.of(context);
    final via = switch (log.confirmedVia) {
      'voice' => s.reminderVoice,
      'app' => s.reminderApp,
      'caregiver' => s.reminderCaregiver,
      _ => null,
    };
    final until = log.snoozedUntil;
    String snoozeTime() {
      final time = _time(until!, scope.timezone);
      if (PatientTime.day(until, scope.timezone) ==
          PatientTime.day(log.scheduledAt, scope.timezone)) {
        return time;
      }
      return '${DateFormat.MMMd(Localizations.localeOf(context).languageCode).format(PatientTime.local(until, scope.timezone))} $time';
    }

    return DefaultTextStyle.merge(
      style: const TextStyle(
        height: 1.5,
        fontFamilyFallback: ['DM Sans', 'Readex Pro'],
      ),
      child: RemoriChip(
        label: switch (log.status) {
          'completed' => via == null ? s.reminderDone : s.reminderDoneVia(via),
          'snoozed' =>
            until == null
                ? s.reminderSnoozed
                : s.reminderSnoozedUntil(snoozeTime()),
          'missed' => s.reminderMissed,
          _ => s.reminderPending,
        },
        kind: switch (log.status) {
          'completed' => RemoriChipKind.success,
          'snoozed' => RemoriChipKind.warning,
          'missed' => RemoriChipKind.danger,
          _ => RemoriChipKind.neutral,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final scope = ref.watch(reminderScopeProvider),
        day = ref.watch(reminderDayProvider);
    final state = ref.watch(remindersControllerProvider);
    ref.watch(homeRefreshProvider);
    final snapshot = ref.watch(remindersDataProvider);
    final data = snapshot.isLoading || snapshot.hasError
        ? const ReminderListData()
        : snapshot.value ?? const ReminderListData();
    final manager = scope != null && ref.watch(caregiverCanManageProvider);
    final enabled = manager && !state.busy && !state.pending;
    final locale = Localizations.localeOf(context).languageCode;
    final group = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: RemoriColors.muted,
      letterSpacing: locale == 'ar' ? 0 : .48,
      height: 1.3,
    );
    final small = Theme.of(context).textTheme.bodySmall
        ?.copyWith(fontSize: 13, height: 1.3);
    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: RemoriColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s.reminders,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (manager)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: const [RemoriTheme.buttonShadow],
                    ),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(fontSize: 14),
                      ),
                      onPressed: enabled ? () => _edit(scope) : null,
                      child: Text(s.reminderAdd),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(remindersControllerProvider.notifier).refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      day == null
                          ? s.reminderToday
                          : s.reminderTodayDate(
                              DateFormat(
                                'EEE d MMM',
                                locale,
                              ).format(DateTime.parse(day)).toUpperCase(),
                            ),
                      style: group,
                    ),
                    const SizedBox(height: 8),
                    if (scope != null)
                      for (final log in data.occurrences) ...[
                        _ReminderCard(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final content = Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width:
                                        MediaQuery.textScalerOf(context)
                                                .scale(15) >
                                            18
                                        ? 90
                                        : 46,
                                    child: Text(
                                      _time(log.scheduledAt, scope.timezone),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      log.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                              if (MediaQuery.textScalerOf(context).scale(15) >
                                      18 ||
                                  constraints.maxWidth < 280) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    content,
                                    const SizedBox(height: 8),
                                    _status(log, scope),
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  Expanded(child: content),
                                  const SizedBox(width: 8),
                                  _status(log, scope),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    if (data.occurrences.isEmpty &&
                        !state.busy &&
                        !snapshot.isLoading)
                      Text(
                        data.todayAvailable
                            ? s.reminderNoLogs
                            : s.reminderNoSavedToday,
                        style: small,
                      ),
                    const SizedBox(height: 8),
                    Text(s.reminderAll, style: group),
                    const SizedBox(height: 8),
                    if (scope != null)
                      for (final reminder in data.reminders) ...[
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: enabled
                                ? () => _edit(scope, reminder.id)
                                : null,
                            child: _ReminderCard(
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEE8F7),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Padding(
                                        padding: const EdgeInsets.all(3),
                                        child: Text(
                                          switch (reminder.kind) {
                                            ReminderKind.medication =>
                                              s.reminderMed,
                                            ReminderKind.appointment =>
                                              s.reminderAppt,
                                            ReminderKind.task => s.reminderTask,
                                          },
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: RemoriColors.purple,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          reminder.title,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            height: 1.3,
                                          ),
                                        ),
                                        Text(
                                          _schedule(reminder, scope),
                                          style: small,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Semantics(
                                    label: s.reminderEnabledLabel(
                                      reminder.title,
                                    ),
                                    child: SizedBox(
                                      width: 40,
                                      height: 32,
                                      child: FittedBox(
                                        child: Switch(
                                          value: reminder.active,
                                          onChanged: enabled
                                              ? (value) => ref
                                                    .read(
                                                      remindersControllerProvider
                                                          .notifier,
                                                    )
                                                    .toggle(reminder.id, value)
                                              : null,
                                          activeThumbColor: Colors.white,
                                          activeTrackColor: RemoriColors.purple,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    if (data.reminders.isEmpty && data.loaded && !state.busy)
                      Text(s.reminderNone, style: small),
                    if (state.busy || snapshot.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (state.failure != null || snapshot.hasError)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              state.pending
                                  ? s.reminderSavedRetry
                                  : data.loaded
                                  ? s.reminderOffline
                                  : s.reminderLoadFailed,
                              style: small,
                            ),
                          ),
                          TextButton(
                            onPressed: state.busy
                                ? null
                                : () => ref
                                      .read(
                                        remindersControllerProvider.notifier,
                                      )
                                      .refresh(),
                            child: Text(s.homeRetry),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: RemoriColors.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: RemoriColors.border),
    ),
    child: child,
  );
}
