import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import 'package:streakbase/utils/exceptions.dart';  // Add this import

class DatabaseException implements Exception {
  final String message;
  final String? details;
  DatabaseException(this.message, [this.details]);
}

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
      version: 2,
      onCreate: _createDb,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        // Enable foreign key support
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        icon INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE habits(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        start_date TEXT,
        notes TEXT,
        category_id INTEGER,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE habit_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE
      )
    ''');

    // Insert default categories
    for (var category in CategoryProvider.defaultCategories) {
      await db.insert('categories', category.toJson());
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add missing columns
      await db.execute('ALTER TABLE habits ADD COLUMN category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL');
      
      // For categories table, we need to recreate it since SQLite doesn't support adding multiple columns in one statement
      await db.execute('DROP TABLE IF EXISTS categories');
      await db.execute('''
        CREATE TABLE categories(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          color INTEGER NOT NULL,
          icon INTEGER NOT NULL
        )
      ''');
      
      // Insert default categories
      for (var category in CategoryProvider.defaultCategories) {
        await db.insert('categories', category.toJson());
      }
    }
  }

  Future<void> initialize() async {
    try {
      await database;
    } catch (e) {
      throw DatabaseException('Failed to initialize database', e.toString());
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<T> runInTransaction<T>(Future<T> Function(Database db) action) async {
    try {
      final db = await database;
      return await db.transaction((txn) async {
        // Convert Transaction to Database for the action
        return await action(txn as Database);
      });
    } catch (e) {
      throw DatabaseException('Transaction failed', e.toString());
    }
  }

  // CRUD operations for habits
  Future<int> insertHabit(Habit habit) async {
    final db = await database;
    return await db.insert('habits', habit.toJson());
  }

  Future<List<Habit>> getHabits() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('habits');
    final habits = maps.map((map) => Habit.fromJson(map)).toList();

    // Load categories for habits
    for (var i = 0; i < habits.length; i++) {
      final categoryId = maps[i]['category_id'] as int?;
      if (categoryId != null) {
        final categoryMaps = await db.query(
          'categories',
          where: 'id = ?',
          whereArgs: [categoryId],
        );
        if (categoryMaps.isNotEmpty) {
          final category = Category.fromJson(categoryMaps.first);
          habits[i] = habits[i].copyWith(category: category);
        }
      }
    }

    return habits;
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

  // CRUD operations for categories
  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toJson());
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return maps.map((map) => Category.fromJson(map)).toList();
  }

  Future<void> updateCategory(Category category) async {
    final db = await database;
    await db.update(
      'categories',
      category.toJson(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      // Update habits to remove category reference
      await txn.update(
        'habits',
        {'category_id': null},
        where: 'category_id = ?',
        whereArgs: [id],
      );
      // Delete the category
      await txn.delete(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
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