import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/remori_routes.dart';
import '../../../core/theme/remori_theme.dart';
import '../../caregiver_dashboard/presentation/home_providers.dart';
import '../domain/people_data.dart';
import 'people_providers.dart';

typedef PeoplePhotoBuilder = Widget Function(
  BuildContext,
  KnownPerson,
  PeopleScope,
  void Function(Object),
);
final peoplePhotoBuilderProvider = Provider<PeoplePhotoBuilder>(
  (ref) => (context, person, scope, onError) {
    Widget placeholder() => const ColoredBox(
      color: RemoriColors.lavender,
      child: Center(
        child: Icon(Icons.person_outline, color: RemoriColors.purple, size: 42),
      ),
    );
    if (person.photoUrl == null) return placeholder();
    return CachedNetworkImage(
      // Recreate the image stream for a refreshed URL; the disk key stays by ID.
      // Hash the UI key so widget diagnostics never contain the signed URL.
      key: ValueKey(Object.hash(person.imageKey(scope), person.photoUrl)),
      imageUrl: person.photoUrl!,
      cacheKey: person.imageKey(scope),
      fit: BoxFit.cover,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (context, url) => placeholder(),
      errorWidget: (context, url, error) => placeholder(),
      errorListener: onError,
    );
  },
);

class C3PeopleScreen extends ConsumerStatefulWidget {
  const C3PeopleScreen({super.key});
  @override
  ConsumerState<C3PeopleScreen> createState() => _C3PeopleScreenState();
}

class _C3PeopleScreenState extends ConsumerState<C3PeopleScreen>
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
      ref.read(peopleRefreshProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final scope = ref.watch(peopleScopeProvider);
    final refresh = ref.watch(peopleRefreshProvider);
    // Keep bootstrap controller alive until a cold patient selection completes.
    ref.watch(homeRefreshProvider);
    final snapshot = ref.watch(peopleDataProvider);
    final data = snapshot.isLoading || snapshot.hasError
        ? const PeopleData()
        : snapshot.value ?? const PeopleData();
    final filter = ref.watch(peopleFilterProvider);
    final people = data.people.where((p) => p.status == filter).toList();
    final canAdd = scope != null && ref.watch(caregiverCanManageProvider);
    final numbers = NumberFormat.decimalPattern(
      Localizations.localeOf(context).languageCode,
    );
    final title = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 15,
      height: 1.3,
      fontFamilyFallback: const ['Readex Pro'],
    );
    final small = Theme.of(context).textTheme.bodySmall
        ?.copyWith(fontFamilyFallback: const ['Readex Pro']);
    return RefreshIndicator(
      onRefresh: () => ref.read(peopleRefreshProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: RemoriColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.caregiverPeople,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (canAdd)
                    FilledButton(
                      onPressed: () => context.pushNamed(
                        RemoriScreen.c4.name,
                        extra: scope.patientId,
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        textStyle: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      child: Text(s.peopleAdd),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  if (data.unknownCount > 0 && scope != null)
                    Material(
                      color: RemoriColors.warning,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => context.pushNamed(
                          RemoriScreen.c6.name,
                          extra: scope.patientId,
                        ),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.peopleReviewCount(data.unknownCount),
                                  style: title?.copyWith(
                                    color: RemoriColors.warningInk,
                                  ),
                                ),
                              ),
                              Icon(
                                Directionality.of(context) == TextDirection.rtl
                                    ? Icons.chevron_left
                                    : Icons.chevron_right,
                                color: RemoriColors.warningInk,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _filterChip(
                        data.loaded
                            ? s.peopleActive(
                                numbers.format(
                                  data.people
                                      .where(
                                        (p) => p.status == PeopleFilter.active,
                                      )
                                      .length,
                                ),
                              )
                            : s.peopleActiveLabel,
                        PeopleFilter.active,
                        filter,
                      ),
                      _filterChip(
                        s.peopleArchived,
                        PeopleFilter.archived,
                        filter,
                      ),
                    ],
                  ),
                  if (snapshot.isLoading || (refresh.busy && !data.loaded))
                    Semantics(
                      label: s.peopleLoading,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  if (refresh.failed || snapshot.hasError)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data.loaded ? s.peopleOffline : s.peopleLoadFailed,
                            style: small,
                          ),
                        ),
                        TextButton(
                          onPressed: refresh.busy
                              ? null
                              : () => ref
                                    .read(peopleRefreshProvider.notifier)
                                    .refresh(),
                          child: Text(s.homeRetry),
                        ),
                      ],
                    ),
                  if (!refresh.busy &&
                      !snapshot.isLoading &&
                      !refresh.failed &&
                      !snapshot.hasError &&
                      people.isEmpty)
                    Text(
                      scope == null
                          ? s.homeNoPatients
                          : filter == PeopleFilter.active
                          ? s.peopleNoActive
                          : s.peopleNoArchived,
                      style: small,
                    ),
                  for (var i = 0; i < people.length; i += 2)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _personCard(
                            context,
                            people[i],
                            scope!,
                            title,
                            small,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: i + 1 < people.length
                              ? _personCard(
                                  context,
                                  people[i + 1],
                                  scope,
                                  title,
                                  small,
                                )
                              : const SizedBox(),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, PeopleFilter value, PeopleFilter selected) =>
      ChoiceChip(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        label: Text(label),
        selected: value == selected,
        showCheckmark: false,
        onSelected: (_) =>
            ref.read(peopleFilterProvider.notifier).select(value),
        visualDensity: VisualDensity.compact,
        backgroundColor: RemoriColors.surface,
        selectedColor: RemoriColors.purple,
        side: const BorderSide(color: RemoriColors.border),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: value == selected ? RemoriColors.surface : RemoriColors.purple,
          fontWeight: FontWeight.w600,
        ),
      );
  Widget _personCard(
    BuildContext context,
    KnownPerson person,
    PeopleScope scope,
    TextStyle? title,
    TextStyle? small,
  ) {
    final s = AppLocalizations.of(context);
    final relationship = switch (person.relationship.trim().toLowerCase()) {
      'son' => s.peopleSon,
      'daughter' => s.peopleDaughter,
      'doctor' => s.peopleDoctor,
      'nurse' => s.peopleNurse,
      _ => person.relationship,
    };
    return Material(
      color: RemoriColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.pushNamed(
          RemoriScreen.c5.name,
          extra: {'patient_id': scope.patientId, 'person_id': person.id},
        ),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: RemoriColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 6,
            children: [
              ExcludeSemantics(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 130,
                    child: ref.watch(peoplePhotoBuilderProvider)(
                      context,
                      person,
                      scope,
                      (error) {
                        if (mounted) {
                          ref
                              .read(peopleRefreshProvider.notifier)
                              .photoFailed(scope, person, error);
                        }
                      },
                    ),
                  ),
                ),
              ),
              Text(person.name, style: title),
              Text(relationship, style: small),
            ],
          ),
        ),
      ),
    );
  }
}
