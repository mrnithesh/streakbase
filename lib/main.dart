import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streakbase/providers/habit_provider.dart';
import 'package:streakbase/providers/category_provider.dart';
import 'package:streakbase/services/database_service.dart';
import 'package:streakbase/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  final databaseService = DatabaseService();
  await databaseService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(db: databaseService),
        ),
        ChangeNotifierProvider(
          create: (_) => HabitProvider(db: databaseService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00796B), // Teal as base
      primary: const Color(0xFF00796B),   // Primary color
      secondary: const Color(0xFF004D40), // Dark teal as secondary color
      surface: const Color(0xFFF5F5F5),   // Light grey for surface
      background: const Color(0xFFFFFFFF), // White background
      error: const Color(0xFFD32F2F),     // Red for errors
    ).copyWith(
      primaryContainer: const Color(0xFFB2DFDB), // Light teal for containers
      secondaryContainer: const Color(0xFF004D40), // Dark teal for containers
      onPrimary: Colors.white, // Ensure good contrast for buttons
    );

    return MaterialApp(
      title: 'StreakBase',
      theme: ThemeData(
        colorScheme: lightColorScheme,
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: lightColorScheme.surfaceVariant.withOpacity(0.2),
            ),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: lightColorScheme.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}