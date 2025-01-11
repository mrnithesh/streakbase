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
      seedColor: const Color(0xFF1976D2), // Blue as base
      primary: const Color(0xFF1976D2),   // Primary color
      secondary: const Color(0xFF1565C0), // Dark blue as secondary color
      surface: const Color(0xFFF5F5F5),   // Light grey for surface
      background: const Color(0xFFFFFFFF), // White background
      error: const Color(0xFFD32F2F),     // Red for errors
    ).copyWith(
      primaryContainer: const Color(0xFFBBDEFB), // Light blue for containers
      secondaryContainer: const Color(0xFF1565C0), // Dark blue for containers
      onPrimary: Colors.white, // Ensure good contrast for buttons
    );

    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1976D2), // Blue as base
      brightness: Brightness.dark,
      primary: const Color(0xFF90CAF9),
      secondary: const Color(0xFF1E88E5),
      surface: const Color.fromARGB(255, 28, 27, 27),
      background: const Color(0xFF121212),
      error: const Color(0xFFCF6679),
    ).copyWith(
      primaryContainer: const Color(0xFF1565C0),
      secondaryContainer: const Color(0xFF90CAF9),
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