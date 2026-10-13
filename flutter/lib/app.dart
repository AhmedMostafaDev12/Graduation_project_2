import 'package:flutter/material.dart';

import 'core/theme/remori_background.dart';
import 'core/theme/remori_theme.dart';

/// Routing and localized screens arrive in separate foundation changes.
class RemoriApp extends StatelessWidget {
  const RemoriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: RemoriTheme.forMode(RemoriMode.caregiver),
      home: const Scaffold(body: RemoriBackground(child: SizedBox.expand())),
    );
  }
}
