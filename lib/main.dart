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
      seedColor: const Color(0xFF37474F), // Blue-gray as base
      primary: const Color(0xFF37474F),
      secondary: const Color(0xFF78909C),
      surface: const Color(0xFFF5F5F5),
      background: const Color(0xFFFFFFFF),
      error: const Color(0xFFE57373),
    ).copyWith(
      primaryContainer: const Color(0xFFECEFF1),
      secondaryContainer: const Color(0xFFCFD8DC),
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