import 'package:flutter/material.dart';
import 'entering_ip.dart';
import '/app/theme/app_theme.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const IpEntryWrapper(),
      theme: AppTheme.basic,
    );
  }
}