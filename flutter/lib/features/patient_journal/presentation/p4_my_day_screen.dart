import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/remori_theme.dart';
import '../../../core/theme/remori_widgets.dart';
import '../../patient_today/presentation/patient_today_providers.dart';
import '../../reminders/domain/reminder_data.dart';
import '../domain/patient_journal_data.dart';
import 'patient_journal_providers.dart';

class P4MyDayScreen extends ConsumerStatefulWidget {
  const P4MyDayScreen({super.key});
  @override
  ConsumerState<P4MyDayScreen> createState() => _P4MyDayScreenState();
}

class _P4MyDayScreenState extends ConsumerState<P4MyDayScreen>
    with WidgetsBindingObserver {
  bool _foreground = true, _visible = true;
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() => _foreground = state == AppLifecycleState.resumed);
    if (_foreground && _visible) {
      ref.invalidate(patientTodayNowProvider);
      ref.read(patientJournalRefreshProvider.notifier).refresh();
    } else {
      ref.read(patientJournalRefreshProvider.notifier).hidePreviews();
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = ModalRoute.isCurrentOf(context) ?? true;
    if (visible != _visible) {
      _visible = visible;
      Future.microtask(() {
        if (!mounted) return;
        final c = ref.read(patientJournalRefreshProvider.notifier);
        if (_visible && _foreground) {
          c.refresh();
        } else {
          c.hidePreviews();
        }
      });
    }
    final s = AppLocalizations.of(context),
        key = ref.watch(patientJournalKeyProvider);
    final yesterday = ref.watch(patientJournalYesterdayProvider),
        state = ref.watch(patientJournalRefreshProvider),
        snapshot = ref.watch(patientJournalDataProvider);
    final data = key == null || snapshot.isLoading || snapshot.hasError
        ? const PatientJournalData()
        : snapshot.value ?? const PatientJournalData();
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.patientMyDay,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _DayButton(
                      label: s.patientDayToday,
                      selected: !yesterday,
                      onPressed: () => ref
                          .read(patientJournalYesterdayProvider.notifier)
                          .select(false),
                    ),
                    _DayButton(
                      label: s.patientDayYesterday,
                      selected: yesterday,
                      onPressed: () => ref
                          .read(patientJournalYesterdayProvider.notifier)
                          .select(true),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                if (state.failed || snapshot.hasError) ...[
                  Text(
                    s.patientDayOffline,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(height: 10),
                  RemoriButton(
                    label: s.homeRetry,
                    outlined: true,
                    onPressed: state.busy
                        ? null
                        : () => ref
                              .read(patientJournalRefreshProvider.notifier)
                              .refresh(),
                  ),
                  const SizedBox(height: 14),
                ],
                if (key == null || (data.refreshedAt == null && state.busy))
                  Text(
                    s.todayGettingReady,
                    style: const TextStyle(fontSize: 22),
                  )
                else if (data.entries.isEmpty)
                  Text(s.patientDayEmpty, style: const TextStyle(fontSize: 22)),
                for (final entry in data.entries) ...[
                  Container(
                    key: ValueKey('patient-day-${entry.id}'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: RemoriColors.border),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _EntryPreview(
                          entry: entry,
                          journalKey: key!,
                          visible: _foreground && _visible,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            _description(context, entry, key.$3),
                            style: const TextStyle(fontSize: 22, height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                if (data.entries.any(
                  (e) => e.media.isNotEmpty || e.type == 'encounter',
                ))
                  Text(
                    s.patientDayDetailPending,
                    style: const TextStyle(
                      fontSize: 22,
                      color: RemoriColors.muted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _description(BuildContext context, JournalEntry e, String zone) {
    if (e.renderedText?.trim().isNotEmpty == true) return e.renderedText!;
    final s = AppLocalizations.of(context),
        time = DateFormat.jm(Localizations.localeOf(context).languageCode)
            .format(PatientTime.local(e.occurredAt, zone));
    return switch (e.type) {
      'encounter' =>
        e.person == null
            ? s.patientDayEncounter(time)
            : s.patientDayMet(e.person!.name, time),
      'conversation_segment' => s.patientDayTalk(time),
      'reminder' => s.patientDayReminder(time),
      'user_requested_recording' => s.patientDayRecording(time),
      'notable_moment_captured' => s.patientDayMoment(time),
      'document_captured' => s.patientDayDocument(time),
      'voice_query' => s.patientDayQuestion(time),
      'mind_game_session' => s.patientDayGame(time),
      'memory_paused' => s.patientDayPaused(time),
      'memory_resumed' => s.patientDayResumed(time),
      _ => s.patientDayEvent(time),
    };
  }
}

class _DayButton extends StatelessWidget {
  const _DayButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });
  final String label;
  final bool selected;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: selected
        ? FilledButton(
            onPressed: onPressed,
            child: Text(label, style: const TextStyle(fontSize: 22)),
          )
        : OutlinedButton(
            onPressed: onPressed,
            child: Text(label, style: const TextStyle(fontSize: 22)),
          ),
  );
}

class _EntryPreview extends ConsumerWidget {
  const _EntryPreview({
    required this.entry,
    required this.journalKey,
    required this.visible,
  });
  final JournalEntry entry;
  final PatientJournalKey journalKey;
  final bool visible;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final person = entry.person;
    final fallback = Container(
      width: 76,
      height: 76,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: RemoriColors.lavender,
        borderRadius: BorderRadius.circular(person == null ? 12 : 38),
      ),
      child: person != null
          ? Text(
              person.name
                  .trim()
                  .split(RegExp(r'\s+'))
                  .take(2)
                  .map((w) => w.characters.first)
                  .join(),
              style: const TextStyle(fontSize: 24),
            )
          : Icon(
              switch (entry.type) {
                'reminder' => Icons.notifications_none,
                'conversation_segment' => Icons.chat_bubble_outline,
                'user_requested_recording' => Icons.videocam_outlined,
                'document_captured' => Icons.description_outlined,
                _ => Icons.book_outlined,
              },
              size: 36,
              color: RemoriColors.purple,
            ),
    );
    final state = ref.watch(patientJournalRefreshProvider);
    final media = entry.media.where((m) => m.previewUrl != null).firstOrNull;
    if (!visible ||
        media == null ||
        state.previewUntil == null ||
        !state.allowedPreviews.contains(patientJournalPreviewIdentity(media))) {
      return ExcludeSemantics(child: fallback);
    }
    final value = (journalKey, media, state.previewUntil!, state.revision);
    if (ref.watch(patientJournalPreviewAvailableProvider(value)).value !=
        true) {
      return ExcludeSemantics(child: fallback);
    }
    final bytes = ref.watch(patientJournalPreviewBytesProvider(value));
    if (bytes.hasError) {
      Future.microtask(() {
        if (context.mounted) {
          ref
              .read(patientJournalRefreshProvider.notifier)
              .photoFailed(journalKey, media, bytes.error!);
        }
      });
    }
    final image = bytes.value;
    return ExcludeSemantics(
      child: image == null || bytes.hasError
          ? fallback
          : ClipRRect(
              borderRadius: BorderRadius.circular(person == null ? 12 : 38),
              child: Image.memory(
                image,
                width: 76,
                height: 76,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
            ),
    );
  }
}
