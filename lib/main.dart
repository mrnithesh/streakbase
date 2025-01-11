import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streakbase/providers/habit_provider.dart';
import 'package:streakbase/providers/category_provider.dart';
import 'package:streakbase/services/database_service.dart';
import 'package:streakbase/screens/home_screen.dart';
import 'package:streakbase/providers/theme_provider.dart'; // Add this import

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
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(), // Add ThemeProvider
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
    final themeProvider = Provider.of<ThemeProvider>(context); // Listen to ThemeProvider

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

    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00796B),
      brightness: Brightness.dark,
      primary: const Color(0xFF80CBC4),
      secondary: const Color(0xFF004D40),
      surface: const Color(0xFF303030),
      background: const Color(0xFF121212),
      error: const Color(0xFFCF6679),
    ).copyWith(
      primaryContainer: const Color(0xFF004D40),
      secondaryContainer: const Color(0xFF80CBC4),
      onPrimary: Colors.black,
    );

    return MaterialApp(
      title: 'StreakBase',
      themeMode: themeProvider.themeMode, // Apply ThemeMode from provider
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
      darkTheme: ThemeData(
        colorScheme: darkColorScheme,
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: darkColorScheme.surfaceVariant.withOpacity(0.2),
            ),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: darkColorScheme.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}