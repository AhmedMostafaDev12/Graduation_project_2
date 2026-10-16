import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/a0_splash_screen.dart';
import '../../features/caregiver_dashboard/presentation/c1_home_screen.dart';
import '../../features/caregiver_dashboard/presentation/c2_alerts_screen.dart';
import '../../features/caregiver_dashboard/presentation/c16_device_screen.dart';
import '../../features/caregiver_dashboard/presentation/c18_more_screen.dart';
import '../../features/caregiver_dashboard/presentation/c19_caregivers_screen.dart';
import '../../features/patient_today/presentation/p1_today_screen.dart';
import '../../features/patient_today/presentation/p6_ask_screen.dart';
import '../../features/patient_today/presentation/p2_reminders_screen.dart';
import '../../features/patient_today/presentation/p3_reminder_alert_screen.dart';
import '../../features/patient_journal/presentation/p4_my_day_screen.dart';
import '../../features/patient_journal/presentation/p5_memory_detail_screen.dart';
import '../../features/mind_games/presentation/p7_games_screen.dart';
import '../../features/mind_games/presentation/p8_gameplay_screen.dart';
import '../../features/mind_games/presentation/p8_practice_screen.dart';
import '../../features/mind_games/presentation/p9_game_result_screen.dart';
import '../../features/mind_games/domain/card_game.dart';
import '../../features/patient_journal/domain/patient_memory_detail.dart';
import '../../features/patient_today/presentation/patient_reminder_alert_host.dart';
import '../../features/patient_today/domain/patient_today_data.dart';
import '../../features/caregiver_dashboard/presentation/home_providers.dart';
import '../../features/people/presentation/c3_people_screen.dart';
import '../../features/people/presentation/c4_add_person_screen.dart';
import '../../features/people/presentation/c5_person_detail_screen.dart';
import '../../features/people/presentation/c6_unknown_faces_screen.dart';
import '../../features/people/presentation/c7_unknown_detail_screen.dart';
import '../../features/places/presentation/c10_places_screen.dart';
import '../../features/places/presentation/c11_edit_place_screen.dart';
import '../../features/journal/presentation/c12_journal_screen.dart';
import '../../features/journal/presentation/c13_media_screen.dart';
import '../../features/journal/presentation/c14_documents_screen.dart';
import '../../features/journal/presentation/c15_document_detail_screen.dart';
import '../../features/reminders/presentation/c8_reminders_screen.dart';
import '../../features/reminders/presentation/c9_edit_reminder_screen.dart';
import '../../features/auth/presentation/a1_mode_select_screen.dart';
import '../../features/auth/presentation/a2_login_screen.dart';
import '../../features/auth/presentation/d7_account_exists_screen.dart';
import '../../features/auth/presentation/a3_signup_screen.dart';
import '../../features/enrollment/presentation/a4_patient_profile_screen.dart';
import '../../features/device_pairing/presentation/a5_pair_glasses_screen.dart';
import '../../features/device_pairing/presentation/a6_permissions_screen.dart';
import '../api/api_providers.dart';
import '../api/patient_session_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/remori_background.dart';
import '../theme/remori_navigation_bar.dart';
import '../theme/remori_theme.dart';
import 'remori_routes.dart';
import 'patient_preview_provider.dart';

/// Authentication will supply these facts after secure credential restoration.
/// This holds no tokens and grants no API authorization.
class RouteAccess {
  const RouteAccess({
    this.caregiverAuthenticated = false,
    this.devicePaired = false,
    this.entryMode,
  });
  final bool caregiverAuthenticated;
  final bool devicePaired;
  final RemoriMode? entryMode;
}

final routeAccessProvider = Provider<RouteAccess>((ref) {
  final patient = ref.watch(patientSessionProvider).active;
  final caregiver = ref.watch(caregiverSessionProvider);
  return RouteAccess(
    caregiverAuthenticated: !patient && caregiver,
    devicePaired: patient,
    entryMode: patient
        ? RemoriMode.patient
        : caregiver
        ? RemoriMode.caregiver
        : null,
  );
});
typedef RemoriScreenBuilder = Widget Function(BuildContext, GoRouterState);

/// Feature PRs replace empty slots with the screen-ID presentation widgets.
final screenBuildersProvider = Provider<Map<RemoriScreen, RemoriScreenBuilder>>(
  (ref) => {
    RemoriScreen.p1: (_, _) => const P1TodayScreen(),
    RemoriScreen.p6: (_, _) => const P6AskScreen(),
    RemoriScreen.p2: (_, _) => const P2RemindersScreen(),
    RemoriScreen.p4: (_, _) => const P4MyDayScreen(),
    RemoriScreen.p7: (_, _) => const P7GamesScreen(),
    RemoriScreen.p8: (_, state) => state.extra is GameUiTarget
        ? P8PracticeScreen(target: state.extra as GameUiTarget)
        : P8GameplayScreen(
            scope: state.extra is PatientTodayKey
                ? state.extra as PatientTodayKey
                : null,
          ),
    RemoriScreen.p9: (_, state) => P9GameResultScreen(
      target: state.extra is GameResultTarget
          ? state.extra as GameResultTarget
          : null,
    ),
    RemoriScreen.p5: (_, state) => P5MemoryDetailScreen(
      target: state.extra is PatientMemoryTarget
          ? state.extra as PatientMemoryTarget
          : null,
    ),
    RemoriScreen.p3: (_, state) => P3ReminderAlertScreen(
      target: state.extra is PatientReminderAlertTarget
          ? state.extra as PatientReminderAlertTarget
          : null,
    ),
    RemoriScreen.c19: (_, _) => const C19CaregiversScreen(),
    RemoriScreen.c18: (_, _) => const C18MoreScreen(),
    RemoriScreen.c16: (_, _) => const C16DeviceScreen(),
    RemoriScreen.c15: (context, state) => C15DocumentDetailScreen(
      patientId: state.extra is Map
          ? (state.extra as Map)['patient_id'] as String?
          : null,
      documentId: state.extra is Map
          ? (state.extra as Map)['document_id'] as String?
          : null,
    ),
    RemoriScreen.c14: (context, state) =>
        const C14DocumentsScreen(key: ValueKey(RemoriScreen.c14)),
    RemoriScreen.c13: (context, state) => C13MediaScreen(
      patientId: state.extra is Map
          ? (state.extra as Map)['patient_id'] as String?
          : null,
      mediaId: state.extra is Map
          ? (state.extra as Map)['media_id'] as String?
          : null,
    ),
    RemoriScreen.c12: (context, state) =>
        const C12JournalScreen(key: ValueKey(RemoriScreen.c12)),
    RemoriScreen.c11: (context, state) => C11EditPlaceScreen(
      patientId:
          state.extra is Map && (state.extra as Map)['patient_id'] is String
          ? (state.extra as Map)['patient_id'] as String
          : null,
      placeId: state.extra is Map && (state.extra as Map)['place_id'] is String
          ? (state.extra as Map)['place_id'] as String
          : null,
    ),
    RemoriScreen.c10: (context, state) =>
        const C10PlacesScreen(key: ValueKey(RemoriScreen.c10)),
    RemoriScreen.c7: (context, state) => C7UnknownDetailScreen(
      patientId:
          state.extra is Map && (state.extra as Map)['patient_id'] is String
          ? (state.extra as Map)['patient_id'] as String
          : null,
      clusterId:
          state.extra is Map && (state.extra as Map)['cluster_id'] is String
          ? (state.extra as Map)['cluster_id'] as String
          : null,
    ),
    RemoriScreen.c6: (context, state) => C6UnknownFacesScreen(
      patientId: state.extra is String ? state.extra as String : null,
    ),
    RemoriScreen.c2: (context, state) =>
        const C2AlertsScreen(key: ValueKey(RemoriScreen.c2)),
    RemoriScreen.c9: (context, state) => C9EditReminderScreen(
      patientId:
          state.extra is Map && (state.extra as Map)['patient_id'] is String
          ? (state.extra as Map)['patient_id'] as String
          : null,
      reminderId:
          state.extra is Map && (state.extra as Map)['reminder_id'] is String
          ? (state.extra as Map)['reminder_id'] as String
          : null,
    ),
    RemoriScreen.c8: (context, state) =>
        const C8RemindersScreen(key: ValueKey(RemoriScreen.c8)),
    RemoriScreen.c5: (context, state) => C5PersonDetailScreen(
      patientId: state.extra is Map
          ? (state.extra as Map)['patient_id'] as String?
          : null,
      personId: state.extra is Map
          ? (state.extra as Map)['person_id'] as String?
          : null,
    ),
    RemoriScreen.c4: (context, state) => C4AddPersonScreen(
      patientId: state.extra is String ? state.extra as String : null,
    ),
    RemoriScreen.c3: (context, state) =>
        const C3PeopleScreen(key: ValueKey(RemoriScreen.c3)),
    RemoriScreen.c1: (context, state) =>
        const C1HomeScreen(key: ValueKey(RemoriScreen.c1)),
    RemoriScreen.a6: (context, state) => A6PermissionsScreen(
      patientId: state.extra is String ? state.extra as String : null,
    ),
    RemoriScreen.a5: (context, state) => A5PairGlassesScreen(
      patientId: state.extra is String ? state.extra as String : null,
    ),
    RemoriScreen.a4: (context, state) => const A4PatientProfileScreen(),
    RemoriScreen.a3: (context, state) => const A3SignupScreen(),
    RemoriScreen.a2: (context, state) => const A2LoginScreen(),
    RemoriScreen.d7: (context, state) => const D7AccountExistsScreen(),
    RemoriScreen.a1: (context, state) => A1ModeSelectScreen(
      onCaregiver: () => context.goNamed(RemoriScreen.a2.name),
      onPatientPhone: () => context.goNamed(RemoriScreen.a2.name),
    ),
    RemoriScreen.a0: (context, state) => A0SplashScreen(
      onGetStarted: () => context.goNamed(RemoriScreen.a1.name),
    ),
  },
);

class RemoriShellLabels {
  RemoriShellLabels({
    required List<String> destinations,
    required this.action,
    required this.direction,
  }) : assert(destinations.length == 4),
       destinations = List.unmodifiable(destinations);
  final List<String> destinations;
  final String action;
  final TextDirection direction;
}

/// Optional test overrides; production labels come from generated ARB resources.
final shellLabelsProvider = Provider<Map<RemoriMode, RemoriShellLabels>>(
  (ref) => const {},
);

final remoriRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(routeAccessProvider, (_, _) => refresh.value++);
  ref.listen(patientPreviewProvider, (_, _) => refresh.value++);
  final router = GoRouter(
    initialLocation: RemoriScreen.a0.path,
    refreshListenable: refresh,
    redirect: (context, state) {
      final screen = RemoriScreen.fromPath(state.uri.path);
      if (screen == null) return RemoriScreen.a0.path;
      final access = ref.read(routeAccessProvider);
      if (screen.isPatient && ref.read(patientPreviewProvider)) return null;
      if (access.entryMode == RemoriMode.patient &&
          access.devicePaired &&
          !screen.isPatient) {
        return RemoriScreen.p1.path;
      }
      if ((screen.isCaregiver || screen.isSetup) &&
          !access.caregiverAuthenticated) {
        return RemoriScreen.a2.path;
      }
      if (screen.isPatient && !access.devicePaired) {
        // The exported A1 patient-phone entry goes through caregiver setup.
        return RemoriScreen.a2.path;
      }
      if (screen == RemoriScreen.a0 || screen == RemoriScreen.a1) {
        if (access.entryMode == RemoriMode.patient && access.devicePaired) {
          return RemoriScreen.p1.path;
        }
        if (access.entryMode == RemoriMode.caregiver &&
            access.caregiverAuthenticated) {
          return RemoriScreen.c1.path;
        }
      }
      return null;
    },
    routes: [
      for (final screen in RemoriScreen.values.where(
        (screen) => !screen.isCaregiver && !screen.isPatient,
      ))
        GoRoute(
          path: screen.path,
          name: screen.name,
          builder: (context, state) => Scaffold(
            body: RemoriBackground(
              kind: screen == RemoriScreen.d7
                  ? RemoriBackgroundKind.wave
                  : RemoriBackgroundKind.onboarding,
              child: _ScreenSlot(screen: screen, state: state),
            ),
          ),
        ),
      for (final mode in RemoriMode.values)
        ShellRoute(
          builder: (context, state, child) => _ModeShell(
            mode: mode,
            screen: RemoriScreen.fromPath(state.uri.path)!,
            child: child,
          ),
          routes: [
            for (final screen in RemoriScreen.values.where(
              (screen) => mode == RemoriMode.caregiver
                  ? screen.isCaregiver
                  : screen.isPatient,
            ))
              GoRoute(
                path: screen.path,
                name: screen.name,
                builder: (context, state) =>
                    _ScreenSlot(screen: screen, state: state),
              ),
          ],
        ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: RemoriBackground(child: SizedBox.expand())),
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

class _ScreenSlot extends ConsumerWidget {
  const _ScreenSlot({required this.screen, required this.state});
  final RemoriScreen screen;
  final GoRouterState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child =
        ref.watch(screenBuildersProvider)[screen]?.call(context, state) ??
        SizedBox.expand(key: ValueKey(screen));
    if (!screen.isPatient || !ref.watch(patientPreviewProvider)) return child;
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          ref.read(patientPreviewProvider.notifier).stop();
          context.goNamed(RemoriScreen.c16.name);
        }
      },
      child: child,
    );
  }
}

class _ModeShell extends ConsumerWidget {
  const _ModeShell({
    required this.mode,
    required this.screen,
    required this.child,
  });
  final RemoriMode mode;
  final RemoriScreen screen;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patient = mode == RemoriMode.patient;
    final labelOverride = ref.watch(shellLabelsProvider)[mode];
    final locale = Localizations.localeOf(context);
    final destinations = patient
        ? const [
            RemoriScreen.p1,
            RemoriScreen.p2,
            RemoriScreen.p4,
            RemoriScreen.p7,
          ]
        : const [
            RemoriScreen.c12,
            RemoriScreen.c3,
            RemoriScreen.c8,
            RemoriScreen.c18,
          ];
    final icons = patient
        ? const [
            Icons.wb_sunny_outlined,
            Icons.notifications_none,
            Icons.book_outlined,
            Icons.sports_esports_outlined,
          ]
        : const [
            Icons.menu_book_outlined,
            Icons.people_outline,
            Icons.notifications_none,
            Icons.more_horiz,
          ];
    return Localizations.override(
      context: context,
      locale: locale,
      child: Builder(
        builder: (context) {
          final strings = AppLocalizations.of(context);
          final labels =
              labelOverride ??
              RemoriShellLabels(
                destinations: patient
                    ? [
                        strings.patientToday,
                        strings.reminders,
                        strings.patientMyDay,
                        strings.patientGames,
                      ]
                    : [
                        strings.journalTitle,
                        strings.caregiverPeople,
                        strings.reminders,
                        strings.caregiverMore,
                      ],
                action: patient ? strings.ask : strings.caregiverHome,
                direction: Directionality.of(context),
              );
          final direction = labels.direction;
          return Theme(
            data: RemoriTheme.forMode(
              mode,
              arabic: direction == TextDirection.rtl,
            ),
            child: Directionality(
              textDirection: direction,
              child: Scaffold(
                body: RemoriBackground(
                  child: Column(
                    children: [
                      if (patient && ref.watch(patientPreviewProvider))
                        SafeArea(
                          bottom: false,
                          child: TextButton.icon(
                            icon: const BackButtonIcon(),
                            onPressed: () {
                              ref.read(patientPreviewProvider.notifier).stop();
                              context.goNamed(RemoriScreen.c16.name);
                            },
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 64),
                              textStyle: const TextStyle(fontSize: 22),
                            ),
                            label: Text(strings.patientPreviewExit),
                          ),
                        ),
                      Expanded(
                        child: patient
                            ? PatientReminderAlertHost(
                                screen: screen,
                                child: child,
                              )
                            : child,
                      ),
                      if (screen.showsNavigation)
                        RemoriNavigationBar(
                          mode: mode,
                          items: [
                            for (var index = 0; index < 4; index++)
                              RemoriNavigationItem(
                                label: labels.destinations[index],
                                icon: Icon(icons[index]),
                              ),
                          ],
                          selectedIndex:
                              !patient &&
                                  screen != RemoriScreen.c12 &&
                                  screen.navigationIndex == 0
                              ? -1
                              : screen.navigationIndex,
                          onSelected: (index) {
                            final destination = destinations[index];
                            if (screen == destination) return;
                            if (destination == RemoriScreen.c12) {
                              context.pushNamed(destination.name);
                            } else {
                              context.goNamed(destination.name);
                            }
                          },
                          actionLabel: labels.action,
                          showAction: true,
                          showActionLabel: !patient,
                          actionSelected: !patient && screen == RemoriScreen.c1,
                          actionIcon: Icon(
                            patient ? Icons.mic_none : Icons.home_outlined,
                          ),
                          onAction: !patient
                              ? () => context.goNamed(RemoriScreen.c1.name)
                              : () => context.pushNamed(
                                  patient
                                      ? RemoriScreen.p6.name
                                      : RemoriScreen.c1.name,
                                  extra: patient
                                      ? null
                                      : {
                                          'patient_id': ref
                                              .read(selectedHomePatientProvider)
                                              ?.id,
                                        },
                                ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
