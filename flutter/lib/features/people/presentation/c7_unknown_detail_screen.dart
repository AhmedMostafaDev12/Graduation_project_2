import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/remori_routes.dart';
import '../../../core/theme/remori_theme.dart';
import '../../../core/theme/remori_widgets.dart';
import '../../caregiver_dashboard/presentation/home_providers.dart';
import '../../reminders/domain/reminder_data.dart';
import '../domain/unknown_faces_data.dart';
import 'people_providers.dart';
import 'unknown_detail_providers.dart';
import 'unknown_faces_providers.dart';

class C7UnknownDetailScreen extends ConsumerWidget {
  const C7UnknownDetailScreen({super.key, this.patientId, this.clusterId});
  final String? patientId, clusterId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owner = ref.watch(peopleScopeProvider);
    if (owner == null ||
        owner.patientId != patientId ||
        clusterId == null ||
        clusterId!.isEmpty) {
      return SafeArea(
        child: Column(
          children: [
            _header(context),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                AppLocalizations.of(context).unknownDetailUnavailable,
              ),
            ),
          ],
        ),
      );
    }
    final key = (owner, clusterId!);
    return _Review(key: ValueKey(key), detail: key);
  }
}

Widget _header(BuildContext context, {bool busy = false}) => Container(
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
          onPressed: busy ? null : () => context.goNamed(RemoriScreen.c6.name),
        ),
      ),
      Expanded(
        child: Text(
          AppLocalizations.of(context).unknownDetailTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    ],
  ),
);

class _Review extends ConsumerStatefulWidget {
  const _Review({super.key, required this.detail});
  final UnknownDetailKey detail;
  @override
  ConsumerState<_Review> createState() => _ReviewState();
}

class _ReviewState extends ConsumerState<_Review> with WidgetsBindingObserver {
  final _name = TextEditingController(),
      _relationship = TextEditingController();
  bool _consent = false,
      _submitted = false,
      _visible = true,
      _foreground = true,
      _confirming = false;
  UnknownDetailController get _controller =>
      ref.read(unknownDetailControllerProvider(widget.detail).notifier);
  bool get _current =>
      mounted && ref.read(peopleScopeProvider) == widget.detail.$1;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _name.dispose();
    _relationship.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    _foreground = lifecycle == AppLifecycleState.resumed;
    if (_foreground && _visible) {
      _controller.refresh();
    } else {
      _controller.hidePhotos();
    }
  }

  bool _valid(String value, int max) =>
      value.trim().isNotEmpty && value.trim().runes.length <= max;
  Future<void> _save() async {
    setState(() => _submitted = true);
    final state = ref.read(unknownDetailControllerProvider(widget.detail));
    if (!state.acknowledged &&
        (!_valid(_name.text, 80) ||
            !_valid(_relationship.text, 40) ||
            !_consent)) {
      return;
    }
    final done = await _controller.decide(
      name: _name.text,
      relationship: _relationship.text,
      consent: _consent,
    );
    if (mounted && _current && done) context.goNamed(RemoriScreen.c3.name);
  }

  Future<void> _dismiss() async {
    if (_confirming) return;
    setState(() => _confirming = true);
    final s = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.unknownDetailDismiss),
        content: Text(s.unknownDetailDismissConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.detailCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.unknownDetailDismiss),
          ),
        ],
      ),
    );
    if (!_current) return;
    setState(() => _confirming = false);
    if (confirm != true || !ref.read(caregiverCanManageProvider)) return;
    final done = await _controller.decide();
    if (mounted && _current && done) context.goNamed(RemoriScreen.c3.name);
  }

  @override
  Widget build(BuildContext context) {
    final visible = ModalRoute.isCurrentOf(context) ?? true;
    if (visible != _visible) {
      _visible = visible;
      Future.microtask(() {
        if (!mounted) return;
        if (_visible && _foreground) {
          _controller.refresh();
        } else {
          _controller.hidePhotos();
        }
      });
    }
    final s = AppLocalizations.of(context);
    final state = ref.watch(unknownDetailControllerProvider(widget.detail));
    final snapshot = ref.watch(unknownFacesDataProvider);
    final patient = ref.watch(selectedHomePatientProvider);
    final face = snapshot.isLoading || snapshot.hasError
        ? null
        : snapshot.value?.faces
              .where((f) => f.id == widget.detail.$2)
              .firstOrNull;
    final manager = ref.watch(caregiverCanManageProvider);
    final locked =
        !manager ||
        state.writing ||
        state.refreshing ||
        state.acknowledged ||
        state.uncertain ||
        _confirming;
    final canDecide =
        manager &&
        !state.writing &&
        !state.refreshing &&
        !state.uncertain &&
        !_confirming;
    final locale = Localizations.localeOf(context).languageCode;
    final now =
        ref.watch(unknownFacesNowProvider).value ??
        ref.watch(unknownFacesClockProvider)();
    String summary(UnknownFace f) {
      final zone = patient!.timezone;
      final first = DateFormat(
        'd MMM',
        locale,
      ).format(PatientTime.local(f.firstSeenAt, zone));
      final last =
          PatientTime.day(f.lastSeenAt, zone) == PatientTime.day(now, zone)
          ? s.unknownFacesTodayTime(
              DateFormat.Hm(locale)
                  .format(PatientTime.local(f.lastSeenAt, zone)),
            )
          : DateFormat(
              'd MMM',
              locale,
            ).format(PatientTime.local(f.lastSeenAt, zone));
      final number = NumberFormat.decimalPattern(locale);
      return s.unknownDetailSummary(
        number.format(f.sightingCount),
        number.format(f.distinctDays),
        first,
        last,
      );
    }

    return PopScope(
      canPop: !state.writing,
      child: SafeArea(
        child: Column(
          children: [
            _header(context, busy: state.writing),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  if (state.refreshing && face == null)
                    const Center(child: CircularProgressIndicator()),
                  if (state.failed ||
                      snapshot.hasError ||
                      state.uncertain ||
                      state.failure != null) ...[
                    Text(
                      state.acknowledged
                          ? s.unknownDetailCacheRetry
                          : state.uncertain
                          ? s.unknownDetailUncertain
                          : state.failure != null
                          ? s.personSaveRetry
                          : s.unknownFacesOffline,
                      style: _small,
                    ),
                    TextButton(
                      onPressed: state.writing || state.refreshing
                          ? null
                          : state.acknowledged
                          ? () async {
                              final done = await _controller.decide();
                              if (context.mounted && _current && done) {
                                context.goNamed(RemoriScreen.c3.name);
                              }
                            }
                          : () => _controller.refresh(),
                      child: Text(s.homeRetry),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (state.acknowledged)
                    const SizedBox.shrink()
                  else if (face == null || patient == null)
                    Text(s.unknownDetailUnavailable, style: _small)
                  else ...[
                    Row(
                      children: [
                        for (var i = 0; i < 3; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(
                            child: _Sample(
                              key: ValueKey(
                                '${widget.detail}:$i:${state.revision}',
                              ),
                              detail: widget.detail,
                              face: i < face.samples.length
                                  ? face.samples[i].preview(face)
                                  : null,
                              allowed:
                                  _visible &&
                                  _foreground &&
                                  state.previews &&
                                  !state.refreshing &&
                                  !state.writing,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(summary(face), style: _small),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: RemoriColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: RemoriColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            s.unknownDetailKnow,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _field(
                            s.personName,
                            s.unknownDetailNameHint,
                            _name,
                            locked,
                            _submitted && !_valid(_name.text, 80)
                                ? s.unknownDetailNameRequired
                                : null,
                          ),
                          const SizedBox(height: 10),
                          _field(
                            s.personRelationship,
                            s.unknownDetailRelationshipHint,
                            _relationship,
                            locked,
                            _submitted && !_valid(_relationship.text, 40)
                                ? s.unknownDetailRelationshipRequired
                                : null,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 22,
                                child: Checkbox(
                                  activeColor: RemoriColors.purple,
                                  side: const BorderSide(
                                    color: RemoriColors.purple,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  value: _consent,
                                  onChanged: locked
                                      ? null
                                      : (value) => setState(
                                          () => _consent = value == true,
                                        ),
                                  semanticLabel: s.unknownDetailConsent,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  s.unknownDetailConsent,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          if (_submitted && !_consent)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                s.personConsentRequired,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: RemoriColors.dangerInk,
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          RemoriButton(
                            label: state.writing
                                ? s.personSaving
                                : s.unknownDetailSave,
                            onPressed: canDecide ? _save : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    RemoriButton(
                      label: s.unknownDetailDismiss,
                      outlined: true,
                      onPressed: canDecide ? _dismiss : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.unknownDetailDeleteHint,
                      textAlign: TextAlign.center,
                      style: _small,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    String hint,
    TextEditingController controller,
    bool locked,
    String? error,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: 4),
      TextField(
        controller: controller,
        enabled: !locked,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(hintText: hint, errorText: error),
      ),
    ],
  );
}

const _small = TextStyle(fontSize: 13, height: 1.3, color: RemoriColors.muted);

class _Sample extends ConsumerWidget {
  const _Sample({
    super.key,
    required this.detail,
    required this.face,
    required this.allowed,
  });
  final UnknownDetailKey detail;
  final UnknownFace? face;
  final bool allowed;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    Widget placeholder() => Semantics(
      label: s.unknownFacePhotoUnavailable,
      child: const ColoredBox(
        color: RemoriColors.lavender,
        child: Center(
          child: Icon(Icons.person_outline, color: RemoriColors.muted),
        ),
      ),
    );
    return SizedBox(
      height: 104,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: !allowed || face?.previewUrl == null
            ? placeholder()
            : FutureBuilder<Uint8List>(
                future: ref
                    .watch(unknownDetailPreviewsProvider(detail))
                    .load(face!),
                builder: (context, snapshot) {
                  if (snapshot.error case final Object error) {
                    Future.microtask(() {
                      if (context.mounted) {
                        ref
                            .read(
                              unknownDetailControllerProvider(detail).notifier,
                            )
                            .photoFailed(face!, error);
                      }
                    });
                  }
                  return snapshot.data == null
                      ? placeholder()
                      : Image.memory(
                          snapshot.data!,
                          fit: BoxFit.cover,
                          semanticLabel: s.unknownFacePhoto,
                          errorBuilder: (_, _, _) => placeholder(),
                        );
                },
              ),
      ),
    );
  }
}
