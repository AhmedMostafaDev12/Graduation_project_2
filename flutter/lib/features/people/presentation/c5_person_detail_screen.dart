import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/remori_routes.dart';
import '../../../core/theme/remori_theme.dart';
import '../../../core/theme/remori_widgets.dart';
import '../../caregiver_dashboard/presentation/home_providers.dart';
import '../domain/people_data.dart';
import '../domain/person_detail.dart';
import 'people_providers.dart';
import 'person_detail_dialogs.dart';
import 'person_detail_providers.dart';

typedef DetailPhotoBuilder = Widget Function(
  BuildContext,
  PersonDetailScope,
  EnrolledPhoto,
  bool,
  void Function(Object),
);
final detailPhotoBuilderProvider = Provider<DetailPhotoBuilder>(
  (ref) => (context, scope, photo, full, onError) {
    final url = full ? photo.url : photo.thumbnailUrl ?? photo.url;
    final key = photo.key(scope, full: full);
    return CachedNetworkImage(
      key: ValueKey(Object.hash(key, url)),
      imageUrl: url,
      cacheKey: key,
      fit: BoxFit.cover,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (_, _) => _placeholder(),
      errorWidget: (_, _, _) => _placeholder(),
      errorListener: onError,
    );
  },
);
Widget _placeholder() => const ColoredBox(
  color: RemoriColors.lavender,
  child: Center(
    child: Icon(Icons.person_outline, size: 42, color: RemoriColors.purple),
  ),
);

class C5PersonDetailScreen extends ConsumerWidget {
  const C5PersonDetailScreen({super.key, this.patientId, this.personId});
  final String? patientId, personId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owner = ref.watch(peopleScopeProvider);
    if (owner == null ||
        owner.patientId != patientId ||
        personId == null ||
        personId!.isEmpty) {
      return SafeArea(
        child: Column(
          children: [
            _header(context, AppLocalizations.of(context).detailTitle),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(AppLocalizations.of(context).personUnavailable),
            ),
          ],
        ),
      );
    }
    final scope = PersonDetailScope(owner, personId!);
    return _PersonDetail(key: ValueKey(scope), scope: scope);
  }
}

Widget _header(
  BuildContext context,
  String title, {
  VoidCallback? edit,
  bool busy = false,
}) => Container(
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
          padding: EdgeInsets.zero,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.chevron_left, size: 26),
          onPressed: busy ? null : () => context.goNamed(RemoriScreen.c3.name),
        ),
      ),
      Expanded(
        child: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      if (edit != null)
        SizedBox(
          height: 38,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 38),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
            onPressed: busy ? null : edit,
            child: Text(AppLocalizations.of(context).detailEdit),
          ),
        ),
    ],
  ),
);

class _PersonDetail extends ConsumerStatefulWidget {
  const _PersonDetail({super.key, required this.scope});
  final PersonDetailScope scope;
  @override
  ConsumerState<_PersonDetail> createState() => _PersonDetailState();
}

class _PersonDetailState extends ConsumerState<_PersonDetail>
    with WidgetsBindingObserver {
  bool get _current =>
      mounted && ref.read(peopleScopeProvider) == widget.scope.owner;
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
    if (state == AppLifecycleState.resumed && _current) {
      ref.read(personDetailControllerProvider(widget.scope).notifier).refresh();
    }
  }

  Future<void> _confirm({EnrolledPhoto? photo}) async {
    final s = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(photo == null ? s.detailArchive : s.personRemovePhoto),
        content: Text(
          photo == null ? s.detailArchiveConfirm : s.detailRemoveConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.detailCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(photo == null ? s.detailArchive : s.personRemovePhoto),
          ),
        ],
      ),
    );
    if (!_current || confirmed != true) return;
    await ref
        .read(personDetailControllerProvider(widget.scope).notifier)
        .perform(
          photo == null ? PersonAction.archive : PersonAction.removePhoto,
          photoId: photo?.id,
        );
  }

  Widget _image(EnrolledPhoto photo, bool full) =>
      ref.read(detailPhotoBuilderProvider)(context, widget.scope, photo, full, (
        error,
      ) {
        if (_current) {
          ref
              .read(personDetailControllerProvider(widget.scope).notifier)
              .photoFailed(photo, error);
        }
      });
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final snapshot = ref.watch(personDetailDataProvider(widget.scope));
    final state = ref.watch(personDetailControllerProvider(widget.scope));
    final data =
        snapshot.isLoading ||
            snapshot.hasError ||
            state.pending ||
            state.archived
        ? null
        : snapshot.value;
    ref.listen(personDetailControllerProvider(widget.scope), (_, next) {
      if (next.archived) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_current) context.goNamed(RemoriScreen.c3.name);
        });
      }
    });
    final active = data?.person.status == PeopleFilter.active;
    final manage = ref.watch(caregiverCanManageProvider) && active;
    final enabled = manage && !state.busy && !state.pending;
    String relationship(String value) => switch (value.trim().toLowerCase()) {
      'son' => s.peopleSon,
      'daughter' => s.peopleDaughter,
      'doctor' => s.peopleDoctor,
      'nurse' => s.peopleNurse,
      _ => value,
    };
    return PopScope(
      canPop: !state.busy,
      child: SafeArea(
        child: Column(
          children: [
            _header(
              context,
              data?.person.name ?? s.detailTitle,
              busy: state.busy,
              edit: enabled && data != null
                  ? () => showDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) =>
                          PersonEditDialog(scope: widget.scope, data: data),
                    )
                  : null,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref
                    .read(personDetailControllerProvider(widget.scope).notifier)
                    .refresh(),
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20)
                        .copyWith(top: 16, bottom: 16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - 32).clamp(
                          0,
                          double.infinity,
                        ),
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (data != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: SizedBox(
                                  height: 220,
                                  child: data.photos.isEmpty
                                      ? _placeholder()
                                      : _image(data.photos.first, true),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                data.person.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                              Text(
                                data.enrolledByName == null
                                    ? relationship(data.person.relationship)
                                    : s.detailEnrolledBy(
                                        relationship(data.person.relationship),
                                        data.enrolledByName!,
                                      ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: RemoriColors.muted,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                s.detailPhotoCount(
                                  NumberFormat.decimalPattern(
                                    Localizations.localeOf(context)
                                        .languageCode,
                                  ).format(data.photos.length),
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final photo in data.photos)
                                    Semantics(
                                      label: s.detailPhotoLabel,
                                      button: enabled && data.photos.length > 1,
                                      child: InkWell(
                                        onTap: enabled && data.photos.length > 1
                                            ? () => _confirm(photo: photo)
                                            : null,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: SizedBox(
                                            width:
                                                ((constraints.maxWidth - 64) /
                                                        4)
                                                    .clamp(48, 100),
                                            height: 76,
                                            child: _image(photo, false),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                active ? s.detailPhotoTip : s.detailArchived,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: RemoriColors.muted,
                                  height: 1.3,
                                ),
                              ),
                              if (manage) ...[
                                const SizedBox(height: 12),
                                RemoriButton(
                                  outlined: true,
                                  label: s.detailAddPhotos,
                                  onPressed:
                                      !enabled || data.photos.length >= 20
                                      ? null
                                      : () => showDialog<void>(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (_) => PersonPhotosDialog(
                                            scope: widget.scope,
                                            capacity: 20 - data.photos.length,
                                          ),
                                        ),
                                ),
                              ],
                            ],
                            if (state.busy || snapshot.isLoading)
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            if (state.failure != null ||
                                snapshot.hasError ||
                                (!state.busy && data == null))
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        state.failure == null
                                            ? s.detailGone
                                            : detailFailureMessage(
                                                context,
                                                state,
                                              ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: state.busy
                                          ? null
                                          : () => ref
                                                .read(
                                                  personDetailControllerProvider(
                                                    widget.scope,
                                                  ).notifier,
                                                )
                                                .refresh(),
                                      child: Text(s.homeRetry),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 20),
                            const Spacer(),
                            if (manage) ...[
                              RemoriButton(
                                outlined: true,
                                label: s.detailArchive,
                                onPressed: enabled ? () => _confirm() : null,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                s.detailArchiveHint,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: RemoriColors.muted,
                                  height: 1.3,
                                ),
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
