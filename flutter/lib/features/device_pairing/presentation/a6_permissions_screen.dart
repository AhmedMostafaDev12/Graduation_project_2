import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/api/patient_session_provider.dart';
import '../../../core/relay/permission_service.dart';
import '../../../core/router/remori_routes.dart';
import '../../../core/theme/remori_theme.dart';
import '../../../core/theme/remori_widgets.dart';
import 'permissions_providers.dart';
import 'handover_providers.dart';

class A6PermissionsScreen extends ConsumerStatefulWidget {
  const A6PermissionsScreen({super.key, this.patientId});
  final String? patientId;
  @override
  ConsumerState<A6PermissionsScreen> createState() =>
      _A6PermissionsScreenState();
}

class _A6PermissionsScreenState extends ConsumerState<A6PermissionsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      if (mounted &&
          ref.read(permissionServiceProvider).platform ==
              PermissionPlatform.android) {
        ref.read(handoverConnectionProvider.notifier).prepare(widget.patientId);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(setupPermissionsProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final platform = ref.watch(permissionServiceProvider).platform;
    final android = platform == PermissionPlatform.android;
    final permissions = ref.watch(setupPermissionsProvider);
    final connection = ref.watch(handoverConnectionProvider);
    final session = ref.watch(patientSessionProvider);
    final ready = android && connection.readyFor(widget.patientId);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    child: InkWell(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.goNamed(
                            RemoriScreen.a5.name,
                            extra: widget.patientId,
                          );
                        }
                      },
                      child: Row(
                        children: [
                          Transform.flip(
                            flipX:
                                Directionality.of(context) == TextDirection.rtl,
                            child: const Icon(Icons.chevron_left, size: 22),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              s.permissionsTitle,
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  s.permissionsStep,
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: RemoriColors.purple,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: 1,
            minHeight: 3,
            color: RemoriColors.purple,
            backgroundColor: RemoriColors.purple.withValues(alpha: .18),
            semanticsLabel: s.permissionsStep,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                Text(
                  android ? s.permissionsIntro : s.permissionsCaregiverIntro,
                  style: theme.textTheme.bodySmall,
                ),
                if (android)
                  _permission(
                    SetupPermission.bluetooth,
                    s.permissionBluetooth,
                    s.permissionBluetoothDetail,
                  ),
                if (platform != PermissionPlatform.unsupported)
                  _permission(
                    SetupPermission.notifications,
                    s.permissionNotifications,
                    s.permissionNotificationsDetail,
                  ),
                if (android) ...[
                  _permission(
                    SetupPermission.location,
                    s.permissionLocation,
                    s.permissionLocationDetail,
                  ),
                  _permission(
                    SetupPermission.background,
                    s.permissionBackground,
                    s.permissionBackgroundDetail,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4D9E9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: RemoriColors.purple.withValues(alpha: .35),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SvgPicture.asset(
                          'assets/images/pair-info.svg',
                          width: 20,
                          height: 20,
                          excludeFromSemantics: true,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.permissionsHandoverTitle,
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                ready
                                    ? s.permissionsHandoverReady
                                    : s.permissionsHandoverPending,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (platform == PermissionPlatform.unsupported)
                  Text(
                    s.permissionsUnsupported,
                    style: theme.textTheme.bodySmall,
                  ),
                if (session.failed)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      s.permissionsHandoverFailed,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                if (permissions.failed)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      s.permissionsReadFailed,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                FilledButtonTheme(
                  data: FilledButtonThemeData(
                    style: theme.filledButtonTheme.style?.copyWith(
                      textStyle: WidgetStatePropertyAll(
                        theme.textTheme.labelLarge!.copyWith(
                          fontFamilyFallback: const ['DM Sans'],
                        ),
                      ),
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 10,
                    children: [
                      if (android)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: RemoriButton(
                            label: s.permissionsPatientMode,
                            onPressed: ready && !session.busy
                                ? () async {
                                    final success = await ref
                                        .read(patientSessionProvider.notifier)
                                        .handover(
                                          connection.context!,
                                          connected: () => ref
                                              .read(handoverConnectionProvider)
                                              .readyFor(widget.patientId),
                                        );
                                    if (context.mounted && success) {
                                      context.goNamed(RemoriScreen.p1.name);
                                    }
                                  }
                                : null,
                          ),
                        ),
                      RemoriButton(
                        label: s.permissionsCaregiverMode,
                        onPressed: session.busy
                            ? null
                            : () => context.goNamed(RemoriScreen.c1.name),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _permission(SetupPermission kind, String title, String detail) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(setupPermissionsProvider);
    final value = state.values[kind];
    final granted = value == PermissionAccess.granted;
    final label = state.busy
        ? s.permissionChecking
        : granted
        ? s.permissionGranted
        : value == PermissionAccess.limited ||
              value == PermissionAccess.blocked ||
              value == PermissionAccess.restricted
        ? s.permissionSettings
        : s.permissionAllow;
    return RemoriCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(detail, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (granted && !state.busy)
            Semantics(
              liveRegion: true,
              child: RemoriChip(label: label, kind: RemoriChipKind.success),
            )
          else
            FilledButton(
              onPressed: state.busy
                  ? null
                  : () => ref
                        .read(setupPermissionsProvider.notifier)
                        .request(kind),
              style: ButtonStyle(
                minimumSize: const WidgetStatePropertyAll(Size(0, 30)),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: WidgetStatePropertyAll(
                  theme.textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              child: Text(label, textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }
}
