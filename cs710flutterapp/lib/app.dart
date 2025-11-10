import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/main_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/geiger_screen.dart';
import 'utils/theme.dart';

class CS710FlutterApp extends ConsumerWidget {
  const CS710FlutterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'CS710 QuickStart',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const MainScreen(),
        '/scan': (context) => const ScanScreen(),
        '/inventory': (context) => const InventoryScreen(),
        '/geiger': (context) => const GeigerScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
