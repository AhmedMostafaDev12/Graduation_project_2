import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/remori_routes.dart';
import '../../../core/theme/remori_theme.dart';
import '../../caregiver_dashboard/presentation/home_providers.dart';
import '../domain/places_data.dart';
import 'places_providers.dart';

class C10PlacesScreen extends ConsumerWidget {
  const C10PlacesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final scope = ref.watch(placesScopeProvider);
    final snapshot = ref.watch(placesDataProvider),
        state = ref.watch(placesRefreshProvider);
    final data = scope == null || snapshot.isLoading || snapshot.hasError
        ? const PlacesData()
        : snapshot.value ?? const PlacesData();
    final manager = ref.watch(caregiverCanManageProvider);
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).languageCode,
    );
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 18, 20, 12),
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
                    tooltip: MaterialLocalizations.of(context)
                        .backButtonTooltip,
                    onPressed: () => context.goNamed(RemoriScreen.c18.name),
                    icon: const Icon(Icons.chevron_left, size: 26),
                  ),
                ),
                Expanded(
                  child: Text(
                    s.placesTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (manager)
                  FilledButton(
                    onPressed: scope == null
                        ? null
                        : () => context.pushNamed(
                            RemoriScreen.c11.name,
                            extra: {'patient_id': scope.patientId},
                          ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      textStyle: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(s.placesAdd),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(placesRefreshProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
                children: [
                  Text(s.placesIntro, style: _small),
                  const SizedBox(height: 10),
                  if (state.failed || snapshot.hasError) ...[
                    Text(
                      data.places.isEmpty
                          ? s.placesLoadFailed
                          : s.placesOffline,
                      style: _small,
                    ),
                    TextButton(
                      onPressed: state.busy
                          ? null
                          : () => ref
                                .read(placesRefreshProvider.notifier)
                                .refresh(),
                      child: Text(s.homeRetry),
                    ),
                  ],
                  if (data.places.isEmpty && (state.busy || snapshot.isLoading))
                    const Center(child: CircularProgressIndicator())
                  else if (scope == null)
                    Text(s.placesUnavailable, style: _small)
                  else if (data.places.isEmpty)
                    Text(s.placesEmpty, style: _small),
                  for (final p in data.places)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Semantics(
                        button: true,
                        enabled: manager,
                        child: GestureDetector(
                          onTap: !manager || scope == null
                              ? null
                              : () => context.pushNamed(
                                  RemoriScreen.c11.name,
                                  extra: {
                                    'patient_id': scope.patientId,
                                    'place_id': p.id,
                                  },
                                ),
                          child: Container(
                            key: ValueKey('place-${p.id}'),
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
                                const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Color(0xFFEEE8F7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.location_on_outlined,
                                      size: 18,
                                      color: RemoriColors.purple,
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
                                        p.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          fontFamilyFallback: ['Readex Pro'],
                                        ),
                                      ),
                                      Text(
                                        s.placesRadius(
                                          number.format(p.radiusM),
                                        ),
                                        style: _small,
                                      ),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _small = TextStyle(fontSize: 13, height: 1.3, color: RemoriColors.muted);
