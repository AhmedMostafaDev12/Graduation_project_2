import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/remori_theme.dart';
import '../../reminders/domain/reminder_data.dart';
import '../domain/journal_data.dart';
import 'journal_providers.dart';

class C12JournalScreen extends ConsumerStatefulWidget {
  const C12JournalScreen({super.key});
  @override
  ConsumerState<C12JournalScreen> createState() => _C12JournalScreenState();
}

class _C12JournalScreenState extends ConsumerState<C12JournalScreen>
    with WidgetsBindingObserver {
  bool _visible = true, _foreground = true;
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
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground && _visible) {
      ref.invalidate(journalNowProvider);
      ref.read(journalRefreshProvider.notifier).refresh();
    } else {
      ref.read(journalRefreshProvider.notifier).hidePreviews();
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = ModalRoute.isCurrentOf(context) ?? true;
    if (visible != _visible) {
      _visible = visible;
      Future.microtask(() {
        if (!mounted) return;
        final c = ref.read(journalRefreshProvider.notifier);
        if (_visible && _foreground) {
          c.refresh();
        } else {
          c.hidePreviews();
        }
      });
    }
    final s = AppLocalizations.of(context),
        locale = Localizations.localeOf(context).languageCode;
    final key = ref.watch(journalKeyProvider),
        day = ref.watch(journalDayProvider),
        filter = ref.watch(journalFilterProvider);
    final state = ref.watch(journalRefreshProvider),
        snapshot = ref.watch(journalDataProvider);
    final now =
        ref.watch(journalNowProvider).value ??
        ref.watch(journalClockProvider)();
    Future.microtask(() {
      if (mounted) ref.read(journalRefreshProvider.notifier).expire(now);
    });
    final data = key == null || snapshot.isLoading || snapshot.hasError
        ? const JournalData()
        : snapshot.value ?? const JournalData();
    final entries = data.entries.where(filter.includes).toList();
    final names = [
      s.journalAll,
      s.journalPeople,
      s.journalTalk,
      s.journalQuestions,
      s.reminders,
      s.journalMedia,
      s.journalDocs,
    ];
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: RemoriColors.border)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final date = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: s.journalPreviousDay,
                      onPressed: () =>
                          ref.read(journalDayProvider.notifier).shift(-1),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 36,
                      ),
                      icon: const Icon(Icons.chevron_left, size: 18),
                    ),
                    Flexible(
                      child: Text(
                        DateFormat(
                          'EEE d MMM',
                          locale,
                        ).format(DateTime.parse(day)),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: s.journalNextDay,
                      onPressed: () =>
                          ref.read(journalDayProvider.notifier).shift(1),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 36,
                      ),
                      icon: const Icon(Icons.chevron_right, size: 18),
                    ),
                  ],
                );
                final title = Text(
                  s.journalTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                );
                return MediaQuery.textScalerOf(context).scale(14) > 20
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [title, date],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(child: title),
                          Flexible(flex: 2, child: date),
                        ],
                      );
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(journalRefreshProvider.notifier).refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final f in JournalFilter.values)
                        Semantics(
                          button: true,
                          selected: filter == f,
                          child: GestureDetector(
                            onTap: () => ref
                                .read(journalFilterProvider.notifier)
                                .select(f),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: filter == f
                                    ? RemoriColors.purple
                                    : RemoriColors.surface,
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(color: RemoriColors.border),
                              ),
                              child: Text(
                                names[f.index],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: filter == f
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: filter == f
                                      ? RemoriColors.surface
                                      : RemoriColors.purple,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  if (state.failed || snapshot.hasError) ...[
                    Text(
                      data.entries.isEmpty
                          ? s.journalLoadFailed
                          : s.journalOffline,
                      style: _small,
                    ),
                    TextButton(
                      onPressed: state.busy
                          ? null
                          : () => ref
                                .read(journalRefreshProvider.notifier)
                                .refresh(),
                      child: Text(s.homeRetry),
                    ),
                  ],
                  if (entries.isEmpty &&
                      (state.busy || snapshot.isLoading) &&
                      data.entries.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (key == null)
                    Text(s.journalUnavailable, style: _small)
                  else if (entries.isEmpty)
                    Text(s.journalEmpty, style: _small),
                  if (key != null)
                    for (final e in entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: _EntryCard(
                          key: ValueKey(
                            '${key.$1.caregiverId}:${key.$1.patientId}:$day:${e.id}:${state.revision}',
                          ),
                          owner: key,
                          entry: e,
                          now: now,
                          previews:
                              _visible &&
                              _foreground &&
                              state.previews &&
                              !state.busy,
                        ),
                      ),
                  const SizedBox(height: 8),
                  Text(s.journalDetailsPending, style: _small),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _small = TextStyle(
  fontSize: 12,
  height: 1.3,
  color: RemoriColors.muted,
  fontFamilyFallback: ['Readex Pro'],
);

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    super.key,
    required this.owner,
    required this.entry,
    required this.now,
    required this.previews,
  });
  final JournalKey owner;
  final JournalEntry entry;
  final DateTime now;
  final bool previews;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context),
        locale = Localizations.localeOf(context).languageCode,
        e = entry;
    final time = DateFormat.Hm(locale)
        .format(PatientTime.local(e.occurredAt, owner.$1.timezone));
    final person = e.person;
    final media = e.media.where((p) => p.available(now)).firstOrNull;
    final paused = {'memory_paused', 'memory_resumed'}.contains(e.type);
    String kind() => switch (e.type) {
      'encounter' => s.journalEncounter,
      'conversation_segment' => s.journalConversation,
      'voice_query' => s.journalQuestion,
      'reminder' => s.journalReminder,
      'user_requested_recording' => s.journalRecording,
      'document_captured' => s.journalDocument,
      'notable_moment_captured' => s.journalNotable,
      'mind_game_session' => s.journalGame,
      'manual_note' => s.journalNote,
      _ => s.journalActivity,
    };
    String duration(int seconds) =>
        '${NumberFormat('0', locale).format(seconds ~/ 60)}:${NumberFormat('00', locale).format(seconds % 60)}';
    String body() {
      if (e.type == 'encounter') {
        final name = person == null
            ? s.journalUnknownPerson
            : '${person.name} (${person.relationship})';
        return e.endedAt == null
            ? name
            : '$name · $time–${DateFormat.Hm(locale).format(PatientTime.local(e.endedAt!, owner.$1.timezone))}';
      }
      if (e.type == 'document_captured') {
        return [
          e.document?.title ?? s.journalDocument,
          e.document?.headline,
        ].whereType<String>().where((v) => v.isNotEmpty).join(' · ');
      }
      if (e.type == 'voice_query') {
        return [
          e.transcript,
          e.renderedText,
        ].whereType<String>().where((v) => v.trim().isNotEmpty).join(' → ');
      }
      if (e.type == 'user_requested_recording') {
        return media?.durationSeconds == null
            ? s.journalRecorded
            : s.journalRecordingDuration(duration(media!.durationSeconds!));
      }
      return e.renderedText ??
          e.transcript ??
          (e.type == 'reminder'
              ? s.journalReminderActivity
              : s.journalActivity);
    }

    final text = body();
    return Semantics(
      button: e.media.isNotEmpty || e.document != null,
      enabled: e.media.isNotEmpty || e.document != null ? false : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: paused ? RemoriColors.lavender.withValues(alpha: .35) : null,
          border: Border.all(color: const Color(0xFFDCD3EC)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 40,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(time, style: _small),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: paused
                  ? Text(
                      e.type == 'memory_paused'
                          ? s.journalPaused
                          : s.journalResumed,
                      style: _small,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kind().toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontFamilyFallback: ['Readex Pro'],
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: RemoriColors.purple,
                            letterSpacing: .4,
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (e.type == 'conversation_segment') ...[
                          if (person != null)
                            Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: RemoriColors.lavender,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    person.name.trim().characters.first,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    e.endedAt == null
                                        ? s.journalWithPerson(person.name)
                                        : s.journalConversationDuration(
                                            person.name,
                                            NumberFormat.decimalPattern(locale)
                                                .format(
                                                  e.endedAt!
                                                      .difference(e.occurredAt)
                                                      .inMinutes,
                                                ),
                                          ),
                                    style: _small,
                                  ),
                                ),
                              ],
                            ),
                          if (e.transcript != null || e.renderedText != null)
                            Text(
                              e.transcript ?? e.renderedText!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textDirection: e.language == 'ar'
                                  ? TextDirection.rtl
                                  : null,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamilyFallback: ['Readex Pro'],
                              ),
                            ),
                        ] else if (e.type == 'notable_moment_captured') ...[
                          if (media?.tags.isNotEmpty == true)
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                for (final tag in media!.tags)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: RemoriColors.surface,
                                      borderRadius: BorderRadius.circular(26),
                                      border: Border.all(
                                        color: RemoriColors.border,
                                      ),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamilyFallback: ['Readex Pro'],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          if (media?.category == 'other' &&
                              media?.reason != null)
                            Text(
                              media!.reason!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: _small,
                            ),
                          if (media?.tags.isNotEmpty != true &&
                              e.renderedText != null)
                            Text(e.renderedText!, style: _small),
                        ] else
                          Text(
                            text.isEmpty ? s.journalActivity : text,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: e.type == 'voice_query' ? 12 : 14,
                              fontWeight: e.type == 'voice_query'
                                  ? FontWeight.w400
                                  : FontWeight.w600,
                              fontFamilyFallback: const ['Readex Pro'],
                            ),
                          ),
                      ],
                    ),
            ),
            if (e.media.isNotEmpty) ...[
              const SizedBox(width: 8),
              _Preview(owner: owner, media: media, now: now, allowed: previews),
            ] else if (e.type == 'encounter' && person != null) ...[
              const SizedBox(width: 8),
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: RemoriColors.lavender,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  person.name
                      .trim()
                      .split(RegExp(r'\s+'))
                      .take(2)
                      .map((word) => word.characters.first)
                      .join()
                      .toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: RemoriColors.purple,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Preview extends ConsumerWidget {
  const _Preview({
    required this.owner,
    required this.media,
    required this.now,
    required this.allowed,
  });
  final JournalKey owner;
  final JournalMedia? media;
  final DateTime now;
  final bool allowed;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context), p = media;
    final live = allowed && p != null
        ? ref.watch(journalPreviewAvailableProvider((owner, p))).value ??
              p.available(now)
        : false;
    Widget placeholder() => Semantics(
      label: s.journalPreviewUnavailable,
      child: ColoredBox(
        color: RemoriColors.lavender,
        child: Center(
          child: Icon(
            p?.type == 'video' ? Icons.videocam_outlined : Icons.image_outlined,
            size: 20,
            color: RemoriColors.purple,
          ),
        ),
      ),
    );
    return SizedBox(
      width: 44,
      height: 44,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: !live || p.previewUrl == null
            ? placeholder()
            : FutureBuilder<Uint8List>(
                future: ref.watch(journalPreviewsProvider(owner)).load(p),
                builder: (context, snapshot) {
                  if (snapshot.error case final Object error) {
                    Future.microtask(() {
                      if (context.mounted) {
                        ref
                            .read(journalRefreshProvider.notifier)
                            .photoFailed(owner, p, error);
                      }
                    });
                  }
                  return snapshot.data == null
                      ? placeholder()
                      : Image.memory(
                          snapshot.data!,
                          fit: BoxFit.cover,
                          semanticLabel: s.journalPreview,
                          errorBuilder: (_, _, _) => placeholder(),
                        );
                },
              ),
      ),
    );
  }
}
