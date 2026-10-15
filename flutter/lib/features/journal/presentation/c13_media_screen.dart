import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/remori_routes.dart';
import '../../../core/theme/remori_theme.dart';
import '../../caregiver_dashboard/presentation/home_providers.dart';
import '../../reminders/domain/reminder_data.dart';
import '../domain/media_detail.dart';
import 'journal_providers.dart';
import 'media_providers.dart';

class C13MediaScreen extends ConsumerWidget {
  const C13MediaScreen({super.key, this.patientId, this.mediaId});
  final String? patientId, mediaId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(journalScopeProvider);
    if (scope == null ||
        scope.patientId != patientId ||
        mediaId == null ||
        mediaId!.isEmpty) {
      return SafeArea(
        child: Column(
          children: [
            _header(context, AppLocalizations.of(context).mediaPhoto),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(AppLocalizations.of(context).mediaUnavailable),
            ),
          ],
        ),
      );
    }
    final key = (scope, mediaId!);
    return _MediaView(key: ValueKey(key), owner: key);
  }
}

void _back(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.goNamed(RemoriScreen.c12.name);
  }
}

Widget _header(BuildContext context, String title, {bool busy = false}) =>
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
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.chevron_left, size: 26),
              onPressed: busy ? null : () => _back(context),
            ),
          ),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
        ],
      ),
    );

class _MediaView extends ConsumerStatefulWidget {
  const _MediaView({super.key, required this.owner});
  final MediaKey owner;
  @override
  ConsumerState<_MediaView> createState() => _MediaViewState();
}

class _MediaViewState extends ConsumerState<_MediaView>
    with WidgetsBindingObserver {
  bool _visible = true, _foreground = true, _confirming = false;
  MediaController get _controller =>
      ref.read(mediaControllerProvider(widget.owner).notifier);
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
      _controller.refresh();
    } else {
      _controller.hidePhotos();
    }
  }

  Future<void> _write(bool delete) async {
    if (_confirming) return;
    final s = AppLocalizations.of(context), key = widget.owner;
    final state = ref.read(mediaControllerProvider(key));
    if (delete && !state.acknowledged) {
      setState(() => _confirming = true);
      final label = ref.read(mediaDataProvider(key)).value?.type == 'video'
          ? s.mediaDeleteVideo
          : s.mediaDeletePhoto;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(label),
          content: Text(s.mediaDeleteConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.detailCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(label),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (confirm != true ||
          ref.read(journalScopeProvider) != key.$1 ||
          !ref.read(caregiverCanManageProvider)) {
        setState(() => _confirming = false);
        _controller.refresh();
        return;
      }
    }
    final done = await _controller.write(delete: delete);
    if (mounted) setState(() => _confirming = false);
    if (mounted && ref.read(journalScopeProvider) == key.$1 && done) {
      _back(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = widget.owner,
        s = AppLocalizations.of(context),
        locale = Localizations.localeOf(context).languageCode;
    final visible = ModalRoute.isCurrentOf(context) ?? true;
    if (visible != _visible) {
      _visible = visible;
      Future.microtask(() {
        if (!mounted) return;
        if (_visible && _foreground && !_confirming) {
          _controller.refresh();
        } else {
          _controller.hidePhotos();
        }
      });
    }
    final state = ref.watch(mediaControllerProvider(key)),
        snapshot = ref.watch(mediaDataProvider(key));
    final detail = snapshot.isLoading || snapshot.hasError
        ? null
        : snapshot.value;
    final now =
        ref.watch(journalNowProvider).value ??
        ref.watch(journalClockProvider)();
    final live = ref.watch(mediaPhotoLiveProvider(key)).value ?? false;
    final manager = ref.watch(caregiverCanManageProvider),
        busy = state.writing || state.refreshing;
    final expired = detail?.expired(now) ?? false;
    final writable =
        detail != null &&
        !expired &&
        !state.missing &&
        !busy &&
        !state.uncertain &&
        !state.acknowledged;
    final video = detail?.type == 'video';
    Widget placeholder() => Container(
      alignment: Alignment.center,
      color: RemoriColors.lavender,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              video ? Icons.videocam_outlined : Icons.image_outlined,
              size: 48,
              color: RemoriColors.purple,
            ),
            const SizedBox(height: 12),
            Text(
              video ? s.mediaVideoPending : s.mediaPhotoUnavailable,
              textAlign: TextAlign.center,
              style: _sub,
            ),
          ],
        ),
      ),
    );
    Widget image() {
      if (detail == null ||
          video ||
          !live ||
          !state.previews ||
          busy ||
          !_foreground ||
          !_visible) {
        return placeholder();
      }
      return FutureBuilder<Uint8List>(
        key: ValueKey(state.revision),
        future: ref.watch(mediaPhotosProvider(key)).load(detail.photo()),
        builder: (context, value) {
          if (value.error case final Object error) {
            Future.microtask(() {
              if (context.mounted) _controller.photoFailed(error);
            });
          }
          return value.data == null
              ? placeholder()
              : Image.memory(
                  value.data!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 340,
                  semanticLabel: s.mediaPhoto,
                  errorBuilder: (_, _, _) => placeholder(),
                );
        },
      );
    }

    String eventTitle() {
      if (detail?.eventType == 'encounter' && detail?.person != null) {
        final p = detail!.person!;
        return s.mediaEncounter(p.name, p.relationship);
      }
      return switch (detail?.eventType) {
        'document_captured' => s.journalDocument,
        'user_requested_recording' => s.journalRecording,
        'notable_moment_captured' => s.journalNotable,
        _ => s.journalActivity,
      };
    }

    final instant = detail?.occurredAt ?? detail?.createdAt;
    final date = instant == null
        ? null
        : DateFormat(
            'EEE d MMM · HH:mm',
            locale,
          ).format(PatientTime.local(instant, key.$1.timezone));
    String trigger() => switch (detail?.trigger) {
      'encounter_keyframe' => s.mediaKeyframe,
      'document_signal' => s.mediaDocumentCapture,
      'salient_frame' => s.mediaNotableCapture,
      'user_requested' => s.mediaRequested,
      _ => s.mediaCaptured,
    };
    final retry = state.acknowledged;
    return PopScope(
      canPop: !state.writing,
      child: SafeArea(
        child: Column(
          children: [
            _header(
              context,
              video ? s.mediaVideo : s.mediaPhoto,
              busy: state.writing,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _controller.refresh(),
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - 30).clamp(
                          0,
                          double.infinity,
                        ),
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (state.refreshing && detail == null)
                              const Center(child: CircularProgressIndicator()),
                            if (state.missing)
                              Text(s.mediaUnavailable, style: _sub)
                            else if (state.failed || snapshot.hasError) ...[
                              Text(
                                retry
                                    ? s.mediaCacheFailed
                                    : state.uncertain
                                    ? s.mediaUncertain
                                    : s.mediaOffline,
                                style: _sub,
                              ),
                              TextButton(
                                onPressed: busy
                                    ? null
                                    : retry
                                    ? () => _write(false)
                                    : () => _controller.refresh(),
                                child: Text(s.homeRetry),
                              ),
                            ],
                            if (!state.missing) ...[
                              SizedBox(
                                height: 340,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: image(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (detail != null) ...[
                                Text(
                                  eventTitle(),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    fontFamilyFallback: ['Readex Pro'],
                                  ),
                                ),
                                if (date != null)
                                  Text('$date · ${trigger()}', style: _sub),
                                const SizedBox(height: 12),
                                if (detail.tags.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(s.mediaAiTags, style: _sub),
                                      for (final tag in detail.tags) _chip(tag),
                                    ],
                                  ),
                                if (detail.category == 'other' &&
                                    detail.reason != null)
                                  Text(detail.reason!, style: _sub),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    if (detail.kept)
                                      _chip(s.mediaKept)
                                    else if (detail.expiresAt != null)
                                      _chip(
                                        expired
                                            ? s.mediaExpired
                                            : s.mediaAutoDeletes(
                                                NumberFormat.decimalPattern(
                                                  locale,
                                                ).format(
                                                  (detail.expiresAt!
                                                              .difference(now)
                                                              .inSeconds /
                                                          86400)
                                                      .ceil(),
                                                ),
                                              ),
                                        warning: true,
                                      ),
                                  ],
                                ),
                                if (detail.containsOtherPeople == true &&
                                    !detail.kept)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      s.mediaRetentionNote,
                                      style: _sub,
                                    ),
                                  ),
                              ],
                            ],
                            const SizedBox(height: 20),
                            const Spacer(),
                            if (manager && !state.missing && !retry) ...[
                              FilledButton(
                                onPressed: writable && !detail.kept
                                    ? () => _write(false)
                                    : null,
                                child: Text(
                                  detail?.kept == true
                                      ? s.mediaKept
                                      : s.mediaPin,
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: writable ? () => _write(true) : null,
                                child: Text(
                                  video
                                      ? s.mediaDeleteVideo
                                      : s.mediaDeletePhoto,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                s.mediaAuditNote,
                                textAlign: TextAlign.center,
                                style: _sub,
                              ),
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
      ),
    );
  }
}

const _sub = TextStyle(
  fontSize: 13,
  color: RemoriColors.muted,
  fontFamilyFallback: ['Readex Pro'],
);
Widget _chip(String text, {bool warning = false}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
  decoration: BoxDecoration(
    color: warning ? const Color(0xFFFBE7B5) : RemoriColors.surface,
    borderRadius: BorderRadius.circular(26),
    border: warning ? null : Border.all(color: RemoriColors.purple),
    boxShadow: warning
        ? const [
            BoxShadow(
              color: Color(0x26000000),
              offset: Offset(0, 1),
              blurRadius: 3,
            ),
          ]
        : null,
  ),
  child: Text(
    text,
    style: TextStyle(
      fontSize: 12,
      color: warning ? const Color(0xFF7A5410) : RemoriColors.purple,
      fontWeight: warning ? FontWeight.w400 : FontWeight.w600,
      fontFamilyFallback: const ['Readex Pro'],
    ),
  ),
);
