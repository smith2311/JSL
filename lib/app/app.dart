import 'package:flutter/material.dart';
import 'router.dart';

class JhaveriJslApp extends StatelessWidget {
  const JhaveriJslApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Jhaveri Securities',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Figtree',
        scaffoldBackgroundColor: const Color(0xFFF6F8FB),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Figtree'),
          bodyMedium: TextStyle(fontFamily: 'Figtree'),
          bodySmall: TextStyle(fontFamily: 'Figtree'),
          titleMedium: TextStyle(
            fontFamily: 'Figtree',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      routerConfig: AppRouter.router,
    );
  }
}