import 'package:flutter/material.dart';

/// Application entry point; design and routing arrive in separate foundations.
class RemoriApp extends StatelessWidget {
  const RemoriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: SafeArea(child: SizedBox.expand())),
    );
  }
}
