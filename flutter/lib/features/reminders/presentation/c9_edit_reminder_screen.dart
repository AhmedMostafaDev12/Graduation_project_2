import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/api/api_failure.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/remori_routes.dart';
import '../../../core/theme/remori_theme.dart';
import '../../../core/theme/remori_widgets.dart';
import '../../caregiver_dashboard/presentation/home_providers.dart';
import '../domain/reminder_data.dart';
import '../domain/reminder_draft.dart';
import 'reminder_editor_providers.dart';
import 'reminders_providers.dart';

class C9EditReminderScreen extends ConsumerStatefulWidget {
  const C9EditReminderScreen({super.key, this.patientId, this.reminderId});
  final String? patientId, reminderId;
  @override
  ConsumerState<C9EditReminderScreen> createState() =>
      _C9EditReminderScreenState();
}

class _C9EditReminderScreenState extends ConsumerState<C9EditReminderScreen> {
  ReminderEditorKey? _owner;
  CaregiverReminder? _initial;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context),
        scope = ref.watch(reminderScopeProvider);
    final owner = scope == null
        ? null
        : ReminderEditorKey(scope, widget.reminderId);
    if (_owner != owner) {
      _owner = owner;
      _initial = null;
    }
    final allowed =
        scope != null &&
        (widget.patientId == null || widget.patientId == scope.patientId) &&
        ref.watch(caregiverCanManageProvider);
    if (!allowed) {
      return SafeArea(
        child: Column(
          children: [
            _header(context, widget.reminderId != null, false),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(s.reminderUnavailable),
            ),
          ],
        ),
      );
    }
    ref.watch(homeRefreshProvider);
    final refresh = ref.watch(remindersControllerProvider);
    final snapshot = ref.watch(remindersDataProvider);
    if (_initial == null &&
        widget.reminderId != null &&
        !snapshot.isLoading &&
        !snapshot.hasError) {
      for (final row in snapshot.value?.reminders ?? <CaregiverReminder>[]) {
        if (row.id == widget.reminderId) {
          _initial = row;
          break;
        }
      }
    }
    if (widget.reminderId != null && _initial == null) {
      return SafeArea(
        child: Column(
          children: [
            _header(context, true, false),
            if (snapshot.isLoading || refresh.busy)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      snapshot.hasError || refresh.failure != null
                          ? s.reminderLoadFailed
                          : s.reminderUnavailable,
                    ),
                    const SizedBox(height: 12),
                    RemoriButton(
                      label: s.homeRetry,
                      onPressed: () => ref
                          .read(remindersControllerProvider.notifier)
                          .refresh(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }
    return _ReminderForm(
      key: ValueKey(owner),
      owner: owner!,
      initial: _initial,
    );
  }
}

Widget _header(BuildContext context, bool editing, bool busy) => Container(
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
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: busy ? null : () => context.goNamed(RemoriScreen.c8.name),
          icon: const Icon(Icons.chevron_left, size: 26),
          padding: EdgeInsets.zero,
        ),
      ),
      Expanded(
        child: Text(
          editing
              ? AppLocalizations.of(context).reminderEditTitle
              : AppLocalizations.of(context).addReminder,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    ],
  ),
);

class _ReminderForm extends ConsumerStatefulWidget {
  const _ReminderForm({super.key, required this.owner, this.initial});
  final ReminderEditorKey owner;
  final CaregiverReminder? initial;
  @override
  ConsumerState<_ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends ConsumerState<_ReminderForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title, _speech, _timezone;
  late final ReminderScheduleDraft _schedule;
  late ReminderKind _kind;
  bool _preserved = false,
      _scheduleChanged = false,
      _submitted = false,
      _picking = false;
  bool get _current =>
      mounted &&
      ref.read(reminderScopeProvider) == widget.owner.scope &&
      ref.read(caregiverCanManageProvider);
  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _title = TextEditingController(text: initial?.title ?? '');
    _speech = TextEditingController(text: initial?.spokenText ?? '');
    _timezone = TextEditingController(
      text: initial?.timezone ?? widget.owner.scope.timezone,
    );
    _kind = initial?.kind ?? ReminderKind.medication;
    final parsed = initial == null
        ? null
        : ReminderScheduleDraft.parse(initial);
    _preserved = initial != null && parsed == null;
    final today = PatientTime.local(
      ref.read(reminderClockProvider)(),
      widget.owner.scope.timezone,
    );
    _schedule =
        parsed ??
        ReminderScheduleDraft(
          starts: DateTime(today.year, today.month, today.day),
          timezone: _timezone.text,
        );
  }

  @override
  void dispose() {
    _title.dispose();
    _speech.dispose();
    _timezone.dispose();
    super.dispose();
  }

  Future<void> _pickTime(int? index) async {
    setState(() => _picking = true);
    final value = index == null ? null : _schedule.minutes[index];
    try {
      final picked = await showTimePicker(
        context: context,
        initialTime: value == null
            ? const TimeOfDay(hour: 9, minute: 0)
            : TimeOfDay(hour: value ~/ 60, minute: value % 60),
      );
      if (!_current || picked == null) return;
      setState(() {
        final minute = picked.hour * 60 + picked.minute;
        if (index == null) {
          _schedule.minutes.add(minute);
        } else {
          _schedule.minutes[index] = minute;
        }
        _scheduleChanged = true;
      });
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _pickDate() async {
    setState(() => _picking = true);
    try {
      final date = await showDatePicker(
        context: context,
        initialDate: _schedule.starts,
        firstDate: DateTime(1),
        lastDate: DateTime(9999, 12, 31),
      );
      if (_current && date != null) {
        setState(() {
          _schedule.starts = date;
          _scheduleChanged = true;
        });
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    final state = ref.read(reminderEditorProvider(widget.owner));
    if (state.acknowledged) {
      final controller = ref.read(
        reminderEditorProvider(widget.owner).notifier,
      );
      final done = state.deleting
          ? await controller.delete()
          : await controller.save(const {});
      if (mounted && _current && done) context.goNamed(RemoriScreen.c8.name);
      return;
    }
    setState(() {
      _submitted = true;
      _schedule.timezone = _timezone.text.trim();
    });
    final fieldsValid = _form.currentState!.validate();
    if (!fieldsValid ||
        (!_preserved &&
            (widget.initial == null || _scheduleChanged) &&
            _schedule.error != null)) {
      return;
    }
    final text = _speech.text.trim();
    final payload = <String, Object?>{
      'title': _title.text.trim(),
      'spoken_text': text.isEmpty ? null : text,
      'type': _kind.name,
      if (widget.initial == null) 'active': true,
      if (!_preserved && (widget.initial == null || _scheduleChanged))
        ..._schedule.payload(),
    };
    final done = await ref
        .read(reminderEditorProvider(widget.owner).notifier)
        .save(payload);
    if (mounted && _current && done) context.goNamed(RemoriScreen.c8.name);
  }

  Future<void> _delete() async {
    final s = AppLocalizations.of(context);
    setState(() => _picking = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(s.reminderDelete),
          content: Text(s.reminderDeleteConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.detailCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(s.reminderDelete),
            ),
          ],
        ),
      );
      if (!_current || confirmed != true) return;
      final done = await ref
          .read(reminderEditorProvider(widget.owner).notifier)
          .delete();
      if (mounted && _current && done) context.goNamed(RemoriScreen.c8.name);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  String? _scheduleError(AppLocalizations s) {
    if (!_submitted ||
        _preserved ||
        (widget.initial != null && !_scheduleChanged)) {
      return null;
    }
    return switch (_schedule.error) {
      'times' => s.reminderTimesRequired,
      'days' => s.reminderDaysRequired,
      'timezone' => s.reminderTimezoneInvalid,
      'gap' => s.reminderStartGap,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context),
        state = ref.watch(reminderEditorProvider(widget.owner));
    final locked = state.busy || state.acknowledged || _picking;
    final scheduleLocked = locked || _preserved;
    final locale = Localizations.localeOf(context).languageCode;
    final days = [
      s.reminderWeekdaySunday,
      s.reminderWeekdayMonday,
      s.reminderWeekdayTuesday,
      s.reminderWeekdayWednesday,
      s.reminderWeekdayThursday,
      s.reminderWeekdayFriday,
      s.reminderWeekdaySaturday,
    ];
    final dayLabels = [
      s.reminderSunday,
      s.reminderMonday,
      s.reminderTuesday,
      s.reminderWednesday,
      s.reminderThursday,
      s.reminderFriday,
      s.reminderSaturday,
    ];
    final failure = state.failure;
    final missing =
        failure?.code == 'REMINDER_NOT_FOUND' ||
        failure?.code == 'PATIENT_NOT_FOUND';
    return PopScope(
      canPop: !state.busy && !_picking,
      child: SafeArea(
        child: Column(
          children: [
            _header(context, widget.initial != null, state.busy || _picking),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 28).clamp(
                        0,
                        double.infinity,
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _field(
                              s.reminderTitleLabel,
                              TextFormField(
                                key: const Key('reminder-title'),
                                controller: _title,
                                enabled: !locked,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamilyFallback: ['DM Sans', 'Readex Pro'],
                                ),
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  hintText: s.reminderTitleHint,
                                  errorText: _serverField(state, 'title')
                                      ? s.reminderFieldInvalid
                                      : null,
                                ),
                                validator: (v) =>
                                    v == null ||
                                        v.trim().isEmpty ||
                                        v.trim().runes.length > 120
                                    ? s.reminderTitleRequired
                                    : null,
                              ),
                            ),
                            _field(
                              s.reminderSpeechLabel,
                              TextFormField(
                                key: const Key('reminder-speech'),
                                controller: _speech,
                                enabled: !locked,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamilyFallback: ['DM Sans', 'Readex Pro'],
                                ),
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.right,
                                decoration: InputDecoration(
                                  hintText: s.reminderSpeechHint,
                                  errorText: _serverField(state, 'spoken_text')
                                      ? s.reminderFieldInvalid
                                      : null,
                                ),
                                validator: (v) =>
                                    (v?.trim().runes.length ?? 0) > 200
                                    ? s.reminderSpeechTooLong
                                    : null,
                              ),
                            ),
                            _field(
                              s.reminderTypeLabel,
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final kind in ReminderKind.values)
                                    _choice(
                                      switch (kind) {
                                        ReminderKind.medication =>
                                          s.reminderMedication,
                                        ReminderKind.appointment =>
                                          s.reminderAppointment,
                                        ReminderKind.task => s.reminderTask,
                                      },
                                      _kind == kind,
                                      locked
                                          ? null
                                          : () => setState(() => _kind = kind),
                                    ),
                                ],
                              ),
                            ),
                            _field(
                              s.reminderRepeatLabel,
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final repeat in ReminderRepeat.values)
                                    _choice(
                                      switch (repeat) {
                                        ReminderRepeat.once => s.reminderOnce,
                                        ReminderRepeat.daily =>
                                          s.reminderRepeatDaily,
                                        ReminderRepeat.weekly =>
                                          s.reminderRepeatWeekly,
                                      },
                                      !_preserved && _schedule.repeat == repeat,
                                      scheduleLocked
                                          ? null
                                          : () => setState(() {
                                              _schedule.repeat = repeat;
                                              _scheduleChanged = true;
                                            }),
                                    ),
                                ],
                              ),
                            ),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (var i = 0; i < 7; i++)
                                  Semantics(
                                    label: dayLabels[i],
                                    selected:
                                        !_preserved &&
                                        (_schedule.repeat ==
                                                ReminderRepeat.daily ||
                                            _schedule.repeat ==
                                                    ReminderRepeat.weekly &&
                                                _schedule.weekdays.contains(
                                                  i == 0 ? 7 : i,
                                                )),
                                    child: SizedBox(
                                      width: 34,
                                      height: 34,
                                      child: FilledButton(
                                        style: FilledButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(34, 34),
                                          backgroundColor:
                                              !_preserved &&
                                                  (_schedule.repeat ==
                                                          ReminderRepeat
                                                              .daily ||
                                                      _schedule.repeat ==
                                                              ReminderRepeat
                                                                  .weekly &&
                                                          _schedule.weekdays
                                                              .contains(
                                                                i == 0 ? 7 : i,
                                                              ))
                                              ? RemoriColors.purple
                                              : RemoriColors.surface,
                                          foregroundColor:
                                              !_preserved &&
                                                  (_schedule.repeat ==
                                                          ReminderRepeat
                                                              .daily ||
                                                      _schedule.repeat ==
                                                              ReminderRepeat
                                                                  .weekly &&
                                                          _schedule.weekdays
                                                              .contains(
                                                                i == 0 ? 7 : i,
                                                              ))
                                              ? RemoriColors.surface
                                              : RemoriColors.purple,
                                          disabledBackgroundColor:
                                              !_preserved &&
                                                  _schedule.repeat ==
                                                      ReminderRepeat.daily
                                              ? RemoriColors.purple
                                              : RemoriColors.surface,
                                          disabledForegroundColor:
                                              !_preserved &&
                                                  _schedule.repeat ==
                                                      ReminderRepeat.daily
                                              ? RemoriColors.surface
                                              : RemoriColors.purple,
                                          shape: const CircleBorder(
                                            side: BorderSide(
                                              color: RemoriColors.border,
                                            ),
                                          ),
                                        ),
                                        onPressed:
                                            scheduleLocked ||
                                                _schedule.repeat !=
                                                    ReminderRepeat.weekly
                                            ? null
                                            : () => setState(() {
                                                final d = i == 0 ? 7 : i;
                                                if (!_schedule.weekdays.add(
                                                  d,
                                                )) {
                                                  _schedule.weekdays.remove(d);
                                                }
                                                _scheduleChanged = true;
                                              }),
                                        child: Text(
                                          days[i],
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_preserved)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  s.reminderSchedulePreserved,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            _field(
                              s.reminderTimesLabel,
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  for (
                                    var i = 0;
                                    i < _schedule.minutes.length;
                                    i++
                                  )
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 116,
                                          child: _readOnly(
                                            'time-$i',
                                            s.reminderTimesLabel,
                                            DateFormat.Hm(locale).format(
                                              DateTime(
                                                2000,
                                                1,
                                                1,
                                                _schedule.minutes[i] ~/ 60,
                                                _schedule.minutes[i] % 60,
                                              ),
                                            ),
                                            scheduleLocked
                                                ? null
                                                : () => _pickTime(i),
                                          ),
                                        ),
                                        if (!scheduleLocked &&
                                            _schedule.minutes.length > 1)
                                          IconButton(
                                            tooltip: s.reminderRemoveTime,
                                            onPressed: () => setState(() {
                                              _schedule.minutes.removeAt(i);
                                              _scheduleChanged = true;
                                            }),
                                            icon: const Icon(
                                              Icons.close,
                                              size: 18,
                                            ),
                                          ),
                                      ],
                                    ),
                                  if (_schedule.minutes.isEmpty)
                                    SizedBox(
                                      width: 116,
                                      child: _readOnly(
                                        'time-empty',
                                        s.reminderTimesLabel,
                                        '',
                                        scheduleLocked
                                            ? null
                                            : () => _pickTime(null),
                                        hint: s.reminderTimeHint,
                                      ),
                                    ),
                                  if (_schedule.minutes.length < 4)
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      onPressed: scheduleLocked
                                          ? null
                                          : () => _pickTime(null),
                                      child: Text(
                                        s.reminderAddTime,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Builder(
                              builder: (context) {
                                final fields = [
                                  _field(
                                    s.reminderStartsLabel,
                                    _readOnly(
                                      'starts',
                                      s.reminderStartsLabel,
                                      _preserved
                                          ? DateFormat.yMMMd(locale).format(
                                              PatientTime.local(
                                                widget.initial!.dtstart,
                                                widget.initial!.timezone,
                                              ),
                                            )
                                          : DateFormat.yMMMd(locale)
                                                .format(_schedule.starts),
                                      scheduleLocked ? null : _pickDate,
                                    ),
                                  ),
                                  _field(
                                    s.reminderTimezoneLabel,
                                    TextFormField(
                                      key: const Key('reminder-timezone'),
                                      controller: _timezone,
                                      enabled: !scheduleLocked,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamilyFallback: [
                                          'DM Sans',
                                          'Readex Pro',
                                        ],
                                      ),
                                      textDirection: TextDirection.ltr,
                                      onChanged: (v) => setState(() {
                                        _schedule.timezone = v.trim();
                                        _scheduleChanged = true;
                                      }),
                                      decoration: InputDecoration(
                                        errorText:
                                            _serverField(state, 'timezone')
                                            ? s.reminderFieldInvalid
                                            : null,
                                      ),
                                    ),
                                  ),
                                ];
                                return MediaQuery.sizeOf(context).width - 40 <
                                            300 ||
                                        MediaQuery.textScalerOf(context)
                                                .scale(14) >
                                            21
                                    ? Column(children: fields)
                                    : Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: fields[0]),
                                          const SizedBox(width: 8),
                                          Expanded(child: fields[1]),
                                        ],
                                      );
                              },
                            ),
                            if (_scheduleError(s) case final String error)
                              _error(error),
                            if (failure != null)
                              _error(
                                state.acknowledged
                                    ? s.reminderSavedRetry
                                    : missing
                                    ? s.reminderUnavailable
                                    : failure.statusCode == 422
                                    ? s.reminderFieldInvalid
                                    : {
                                        ApiFailureKind.network,
                                        ApiFailureKind.timeout,
                                        ApiFailureKind.invalidResponse,
                                      }.contains(failure.kind)
                                    ? s.reminderWriteUncertain
                                    : s.reminderWriteFailed,
                              ),
                            const SizedBox(height: 20),
                            const Spacer(),
                            RemoriButton(
                              label: state.busy
                                  ? s.reminderSaving
                                  : state.acknowledged
                                  ? s.homeRetry
                                  : s.reminderSave,
                              onPressed: state.busy || _picking || missing
                                  ? null
                                  : _save,
                            ),
                            if (widget.initial != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    minimumSize: Size.zero,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: locked || missing ? null : _delete,
                                  child: Text(
                                    s.reminderDelete,
                                    style: const TextStyle(
                                      color: RemoriColors.dangerInk,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
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
      ),
    );
  }

  bool _serverField(ReminderEditorState state, String name) =>
      state.failure?.details.any(
        (e) => e.field == name || e.field == 'body.$name',
      ) ??
      false;
  Widget _field(String label, Widget input) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontFamilyFallback: ['Readex Pro'],
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        input,
      ],
    ),
  );
  Widget _readOnly(
    String key,
    String label,
    String value,
    VoidCallback? onTap, {
    String? hint,
  }) => TextFormField(
    key: ValueKey('$key-$value'),
    initialValue: value,
    readOnly: true,
    enabled: onTap != null,
    onTap: onTap,
    style: const TextStyle(fontSize: 14),
    decoration: InputDecoration(hintText: hint),
  );
  Widget _choice(
    String text,
    bool selected,
    VoidCallback? onTap,
  ) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      minimumSize: Size.zero,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: selected ? RemoriColors.purple : RemoriColors.surface,
      foregroundColor: selected ? RemoriColors.surface : RemoriColors.purple,
      disabledForegroundColor: selected
          ? RemoriColors.surface
          : RemoriColors.muted,
      textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        fontFamilyFallback: ['DM Sans', 'Readex Pro'],
      ),
      side: const BorderSide(color: RemoriColors.border),
    ),
    child: Text(text),
  );
  Widget _error(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13, color: RemoriColors.dangerInk),
    ),
  );
}
