import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/remori_router.dart';
import 'core/theme/remori_theme.dart';

class RemoriApp extends ConsumerWidget {
  const RemoriApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    theme: RemoriTheme.forMode(RemoriMode.caregiver),
    routerConfig: ref.watch(remoriRouterProvider),
  );
}
