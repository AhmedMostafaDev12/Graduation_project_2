import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/a0_splash_screen.dart';
import '../../features/caregiver_dashboard/presentation/c1_home_screen.dart';
import '../../features/caregiver_dashboard/presentation/c2_alerts_screen.dart';
import '../../features/caregiver_dashboard/presentation/home_providers.dart';
import '../../features/people/presentation/c3_people_screen.dart';
import '../../features/people/presentation/c4_add_person_screen.dart';
import '../../features/people/presentation/c5_person_detail_screen.dart';
import '../../features/people/presentation/c6_unknown_faces_screen.dart';
import '../../features/people/presentation/c7_unknown_detail_screen.dart';
import '../../features/reminders/presentation/c8_reminders_screen.dart';
import '../../features/reminders/presentation/c9_edit_reminder_screen.dart';
import '../../features/auth/presentation/a1_mode_select_screen.dart';
import '../../features/auth/presentation/a2_login_screen.dart';
import '../../features/auth/presentation/a3_signup_screen.dart';
import '../../features/enrollment/presentation/a4_patient_profile_screen.dart';
import '../../features/device_pairing/presentation/a5_pair_glasses_screen.dart';
import '../../features/device_pairing/presentation/a6_permissions_screen.dart';
import '../api/api_providers.dart';
import '../api/patient_session_provider.dart';
import '../l10n/app_localizations.dart';
import '../l10n/locale_providers.dart';
import '../theme/remori_background.dart';
import '../theme/remori_navigation_bar.dart';
import '../theme/remori_theme.dart';
import 'remori_routes.dart';

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
  final router = GoRouter(
    initialLocation: RemoriScreen.a0.path,
    refreshListenable: refresh,
    redirect: (context, state) {
      final screen = RemoriScreen.fromPath(state.uri.path);
      if (screen == null) return RemoriScreen.a0.path;
      final access = ref.read(routeAccessProvider);
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
              kind: RemoriBackgroundKind.onboarding,
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
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(screenBuildersProvider)[screen]?.call(context, state) ??
      SizedBox.expand(key: ValueKey(screen));
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
    final locale = patient
        ? ref.watch(patientLocaleProvider)
        : Localizations.localeOf(context);
    final destinations = patient
        ? const [
            RemoriScreen.p1,
            RemoriScreen.p2,
            RemoriScreen.p4,
            RemoriScreen.p7,
          ]
        : const [
            RemoriScreen.c1,
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
            Icons.home_outlined,
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
                        strings.caregiverHome,
                        strings.caregiverPeople,
                        strings.reminders,
                        strings.caregiverMore,
                      ],
                action: patient ? strings.ask : strings.addReminder,
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
                      Expanded(child: child),
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
                          selectedIndex: screen.navigationIndex,
                          onSelected: (index) =>
                              context.goNamed(destinations[index].name),
                          actionLabel: labels.action,
                          showAction:
                              patient || ref.watch(caregiverCanManageProvider),
                          actionIcon: Icon(
                            patient ? Icons.mic_none : Icons.add,
                          ),
                          onAction: () => context.pushNamed(
                            patient
                                ? RemoriScreen.p6.name
                                : RemoriScreen.c9.name,
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
