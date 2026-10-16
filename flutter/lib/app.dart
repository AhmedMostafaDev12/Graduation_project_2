import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/app_localizations.dart';
import 'core/l10n/locale_providers.dart';
import 'core/router/remori_router.dart';
import 'core/router/remori_routes.dart';
import 'core/relay/relay_service_host.dart';
import 'core/relay/reminder_notification_host.dart';
import 'core/theme/remori_theme.dart';

class RemoriApp extends ConsumerWidget {
  const RemoriApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => RelayServiceHost(
    onOpenPatient: () =>
        ref.read(remoriRouterProvider).goNamed(RemoriScreen.p1.name),
    child: ReminderNotificationHost(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        locale: ref.watch(appLocaleProvider),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: RemoriTheme.forMode(RemoriMode.caregiver),
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: RemoriColors.cream,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: Theme(
            data: RemoriTheme.forMode(
              RemoriMode.caregiver,
              arabic: Localizations.localeOf(context).languageCode == 'ar',
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
        routerConfig: ref.watch(remoriRouterProvider),
      ),
    ),
  );
}
