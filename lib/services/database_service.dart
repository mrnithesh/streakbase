import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/habit.dart';
import '../models/habit_log.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'streakbase.db');

    // Make sure the directory exists
    await Directory(dirname(path)).create(recursive: true);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
      onOpen: (db) async {
        // Enable foreign key support
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE habits(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        start_date TEXT,
        notes TEXT,
        category TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE habit_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        completed INTEGER NOT NULL,
        notes TEXT,
        FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color INTEGER NOT NULL
      )
    ''');
  }

  Future<void> initialize() async {
    await database;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // CRUD operations for habits
  Future<int> insertHabit(Habit habit) async {
    final db = await database;
    return await db.insert('habits', habit.toJson());
  }

  Future<List<Habit>> getHabits() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('habits');
    return maps.map((map) => Habit.fromJson(map)).toList();
  }

  Future<void> updateHabit(Habit habit) async {
    final db = await database;
    await db.update(
      'habits',
      habit.toJson(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<void> deleteHabit(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'habit_logs',
        where: 'habit_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'habits',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // CRUD operations for habit logs
  Future<int> insertHabitLog(HabitLog log) async {
    final db = await database;
    final map = log.toJson();
    map['completed'] = log.completed ? 1 : 0;
    return await db.insert('habit_logs', map);
  }

  Future<List<HabitLog>> getHabitLogs(int habitId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'habit_logs',
      where: 'habit_id = ?',
      whereArgs: [habitId],
    );
    return maps.map((map) {
      final newMap = Map<String, dynamic>.from(map);
      newMap['completed'] = newMap['completed'] == 1;
      return HabitLog.fromJson(newMap);
    }).toList();
  }

  Future<void> updateHabitLog(HabitLog log) async {
    final db = await database;
    final map = log.toJson();
    map['completed'] = log.completed ? 1 : 0;
    await db.update(
      'habit_logs',
      map,
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<void> deleteHabitLog(int id) async {
    final db = await database;
    await db.delete(
      'habit_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Export data to JSON
  Future<String> exportData() async {
    final db = await database;
    final habits = await db.query('habits');
    final logs = await db.query('habit_logs');
    final categories = await db.query('categories');

    final data = {
      'habits': habits,
      'logs': logs,
      'categories': categories,
    };

    return jsonEncode(data);
  }

  // Import data from JSON
  Future<void> importData(String jsonData) async {
    final db = await database;
    final data = jsonDecode(jsonData);

    await db.transaction((txn) async {
      // Clear existing data
      await txn.delete('habit_logs');
      await txn.delete('habits');
      await txn.delete('categories');

      // Import new data
      for (var habit in data['habits']) {
        await txn.insert('habits', habit);
      }
      for (var log in data['logs']) {
        await txn.insert('habit_logs', log);
      }
      for (var category in data['categories']) {
        await txn.insert('categories', category);
      }
    });
  }

  // Backup database
  Future<String> backup() async {
    final db = await database;
    await db.close();
    _database = null;
    
    final dbFile = File(join(await getDatabasesPath(), 'streakbase.db'));
    final documentsDir = await getApplicationDocumentsDirectory();
    final backupFile = File(join(documentsDir.path, 
        'streakbase_backup_${DateTime.now().toIso8601String()}.db'));
    
    await dbFile.copy(backupFile.path);
    
    return backupFile.path;
  }

  // Restore from backup
  Future<void> restore(String backupPath) async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    final dbPath = join(await getDatabasesPath(), 'streakbase.db');
    final backupFile = File(backupPath);
    
    if (await backupFile.exists()) {
      await backupFile.copy(dbPath);
    }
  }
} 