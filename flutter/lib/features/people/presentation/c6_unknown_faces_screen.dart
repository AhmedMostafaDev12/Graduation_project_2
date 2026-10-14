import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/remori_routes.dart';
import '../../../core/theme/remori_theme.dart';
import '../../caregiver_dashboard/presentation/home_providers.dart';
import '../../reminders/domain/reminder_data.dart';
import '../domain/people_data.dart';
import '../domain/unknown_faces_data.dart';
import 'people_providers.dart';
import 'unknown_faces_providers.dart';

class C6UnknownFacesScreen extends ConsumerStatefulWidget {
  const C6UnknownFacesScreen({super.key, this.patientId});
  final String? patientId;
  @override
  ConsumerState<C6UnknownFacesScreen> createState() =>
      _C6UnknownFacesScreenState();
}

class _C6UnknownFacesScreenState extends ConsumerState<C6UnknownFacesScreen>
    with WidgetsBindingObserver {
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
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed && _visible) {
      ref.invalidate(unknownFacesNowProvider);
      ref.read(unknownFacesRefreshProvider.notifier).refresh();
    } else if (lifecycle != AppLifecycleState.resumed) {
      ref.read(unknownFacesRefreshProvider.notifier).hidePreviews();
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = ModalRoute.isCurrentOf(context) ?? true;
    if (visible != _visible) {
      _visible = visible;
      Future.microtask(() {
        if (!mounted) return;
        final controller = ref.read(unknownFacesRefreshProvider.notifier);
        if (_visible) {
          controller.refresh();
        } else {
          controller.hidePreviews();
        }
      });
    }
    final s = AppLocalizations.of(context),
        scope = ref.watch(peopleScopeProvider);
    final patient = ref.watch(selectedHomePatientProvider);
    final state = ref.watch(unknownFacesRefreshProvider),
        snapshot = ref.watch(unknownFacesDataProvider);
    final allowed =
        scope != null &&
        patient != null &&
        (widget.patientId == null || widget.patientId == scope.patientId);
    final data = !allowed || snapshot.isLoading || snapshot.hasError
        ? const UnknownFacesData()
        : snapshot.value ?? const UnknownFacesData();
    final locale = Localizations.localeOf(context).languageCode,
        number = NumberFormat.decimalPattern(locale);
    final clock = ref.watch(unknownFacesNowProvider);
    final now = clock.isLoading
        ? ref.watch(unknownFacesClockProvider)()
        : clock.value ?? ref.watch(unknownFacesClockProvider)();
    String dates(UnknownFace face) {
      final zone = patient!.timezone;
      final first = DateFormat(
        'd MMM',
        locale,
      ).format(PatientTime.local(face.firstSeenAt, zone));
      final last =
          PatientTime.day(face.lastSeenAt, zone) == PatientTime.day(now, zone)
          ? s.unknownFacesTodayTime(
              DateFormat.Hm(locale)
                  .format(PatientTime.local(face.lastSeenAt, zone)),
            )
          : DateFormat(
              'd MMM',
              locale,
            ).format(PatientTime.local(face.lastSeenAt, zone));
      return s.unknownFacesDates(first, last);
    }

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
                    tooltip: MaterialLocalizations.of(context)
                        .backButtonTooltip,
                    padding: EdgeInsets.zero,
                    onPressed: () => context.goNamed(RemoriScreen.c3.name),
                    icon: const Icon(Icons.chevron_left, size: 26),
                  ),
                ),
                Expanded(
                  child: Text(
                    s.unknownFacesTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(unknownFacesRefreshProvider.notifier).refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Text(s.unknownFacesIntro, style: _small),
                  const SizedBox(height: 12),
                  if (state.failed || snapshot.hasError) ...[
                    Text(
                      data.faces.isEmpty
                          ? s.unknownFacesLoadFailed
                          : s.unknownFacesOffline,
                      style: _small,
                    ),
                    TextButton(
                      onPressed: state.busy
                          ? null
                          : () => ref
                                .read(unknownFacesRefreshProvider.notifier)
                                .refresh(),
                      child: Text(s.homeRetry),
                    ),
                  ],
                  if (!allowed && !state.busy && !snapshot.isLoading)
                    Text(s.unknownFacesUnavailable, style: _small)
                  else if (data.faces.isEmpty &&
                      (state.busy || snapshot.isLoading))
                    const Center(child: CircularProgressIndicator())
                  else if (data.faces.isEmpty)
                    Text(s.unknownFacesEmpty, style: _small),
                  for (final face in data.faces)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Semantics(
                        button: true,
                        enabled: true,
                        child: GestureDetector(
                          onTap: () => context.pushNamed(
                            RemoriScreen.c7.name,
                            extra: {
                              'patient_id': scope.patientId,
                              'cluster_id': face.id,
                            },
                          ),
                          child: Container(
                            key: ValueKey('unknown-face-${face.id}'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: RemoriColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: RemoriColors.border),
                            ),
                            child: Row(
                              children: [
                                _Preview(
                                  key: ValueKey(
                                    '${scope!.caregiverId}:${scope.patientId}:${face.id}:${state.revision}',
                                  ),
                                  scope: scope,
                                  face: face,
                                  allowed:
                                      _visible &&
                                      state.previewsAllowed &&
                                      !state.busy,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.unknownFacesSeen(
                                          number.format(face.sightingCount),
                                          number.format(face.distinctDays),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(dates(face), style: _small),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: RemoriColors.muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(s.unknownFacesRetention, style: _small),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _small => const TextStyle(
    fontSize: 13,
    height: 1.3,
    color: RemoriColors.muted,
    fontFamilyFallback: ['DM Sans', 'Readex Pro'],
  );
}

class _Preview extends ConsumerWidget {
  const _Preview({
    super.key,
    required this.scope,
    required this.face,
    required this.allowed,
  });
  final PeopleScope scope;
  final UnknownFace face;
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
      width: 72,
      height: 72,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: !allowed || face.previewUrl == null
            ? placeholder()
            : FutureBuilder<Uint8List>(
                future: ref
                    .watch(unknownFacePreviewsProvider(scope))
                    .load(face),
                builder: (context, snapshot) {
                  if (snapshot.error case final Object error) {
                    Future.microtask(() {
                      if (context.mounted) {
                        ref
                            .read(unknownFacesRefreshProvider.notifier)
                            .photoFailed(scope, face, error);
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
