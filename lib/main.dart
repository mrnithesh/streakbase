import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streakbase/providers/habit_provider.dart';
import 'package:streakbase/screens/home_screen.dart';
import 'package:streakbase/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  final databaseService = DatabaseService();
  await databaseService.initialize();

  runApp(MyApp(databaseService: databaseService));
}

class MyApp extends StatelessWidget {
  final DatabaseService databaseService;

  const MyApp({
    super.key,
    required this.databaseService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DatabaseService>.value(
          value: databaseService,
        ),
        ChangeNotifierProxyProvider<DatabaseService, HabitProvider>(
          create: (context) => HabitProvider(db: databaseService),
          update: (context, db, previous) => previous ?? HabitProvider(db: db),
        ),
      ],
      child: MaterialApp(
        title: 'StreakBase',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
} 