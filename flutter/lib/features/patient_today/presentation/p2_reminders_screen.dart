import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/remori_theme.dart';
import '../../../core/theme/remori_widgets.dart';
import '../../reminders/domain/reminder_data.dart';
import '../domain/patient_today_data.dart';
import 'patient_today_providers.dart';

class P2RemindersScreen extends ConsumerStatefulWidget {
  const P2RemindersScreen({super.key});
  @override
  ConsumerState<P2RemindersScreen> createState() => _P2RemindersScreenState();
}

class _P2RemindersScreenState extends ConsumerState<P2RemindersScreen>
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
    final s = AppLocalizations.of(context);
    final key = ref.watch(patientTodayKeyProvider);
    final snapshot = key == null
        ? null
        : ref.watch(patientTodayDataProvider(key));
    final data = snapshot == null || snapshot.isLoading || snapshot.hasError
        ? const PatientTodayData()
        : snapshot.value ?? const PatientTodayData();
    final state = key == null
        ? const PatientTodayState()
        : ref.watch(patientTodayControllerProvider(key));
    final settings = data.settings;
    final offline = state.offline || snapshot?.hasError == true;
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
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) => RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
            children: [
              Text(
                s.patientRemindersTitle,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              if (offline) ...[
                Text(s.todayOffline, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 10),
                RemoriButton(
                  label: s.homeRetry,
                  outlined: true,
                  onPressed: key == null || state.busy ? null : _refresh,
                ),
                const SizedBox(height: 14),
              ],
              if (settings == null)
                Text(s.todayGettingReady, style: const TextStyle(fontSize: 22))
              else if (data.reminders.isEmpty)
                Text(
                  s.patientRemindersEmpty,
                  style: const TextStyle(fontSize: 22),
                )
              else
                for (final reminder in data.reminders) ...[
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight / 4,
                    ),
                    child: _ReminderCard(
                      reminder: reminder,
                      timezone: settings.timezone,
                      active: reminder.id == data.next?.id,
                      done: key == null || state.busy
                          ? null
                          : () => ref
                                .read(
                                  patientTodayControllerProvider(key).notifier,
                                )
                                .act(reminder.id, snooze: false),
                      later: key == null || state.busy
                          ? null
                          : () => ref
                                .read(
                                  patientTodayControllerProvider(key).notifier,
                                )
                                .act(reminder.id, snooze: true),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.timezone,
    required this.active,
    required this.done,
    required this.later,
  });
  final PatientReminder reminder;
  final String timezone;
  final bool active;
  final VoidCallback? done, later;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final completed = reminder.status == 'completed';
    final label = switch (reminder.status) {
      'completed' => s.todayDone,
      'snoozed' => s.patientReminderSnoozed,
      'missed' => s.patientReminderMissed,
      _ => s.patientReminderPending,
    };
    final large = MediaQuery.textScalerOf(context).scale(22) > 30;
    final title = Text(
      reminder.title,
      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
    );
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: completed ? RemoriColors.success : RemoriColors.surface,
        border: completed ? null : Border.all(color: RemoriColors.border),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 22,
          color: completed ? RemoriColors.successInk : RemoriColors.purple,
        ),
      ),
    );
    return Container(
      key: ValueKey('patient-reminder-${reminder.id}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFFF6EC) : RemoriColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? const Color(0xFFF4A261) : RemoriColors.border,
          width: active ? 2 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (active && reminder.status == 'pending')
            title
          else if (large) ...[
            title,
            const SizedBox(height: 10),
            Align(alignment: AlignmentDirectional.centerStart, child: badge),
          ] else
            LayoutBuilder(
              builder: (context, constraints) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * .45,
                    ),
                    child: badge,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(
            DateFormat.jm(Localizations.localeOf(context).languageCode)
                .format(PatientTime.local(reminder.dueAt, timezone)),
            style: const TextStyle(fontSize: 22, color: RemoriColors.muted),
          ),
          if (active) ...[
            const SizedBox(height: 12),
            if (large) ...[
              RemoriButton(label: s.todayDone, onPressed: done),
              const SizedBox(height: 10),
              RemoriButton(
                label: s.todayLater,
                outlined: true,
                onPressed: later,
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: RemoriButton(label: s.todayDone, onPressed: done),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RemoriButton(
                      label: s.todayLater,
                      outlined: true,
                      onPressed: later,
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}
