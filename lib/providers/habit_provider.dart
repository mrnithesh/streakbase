import 'package:flutter/foundation.dart';
import 'package:streakbase/models/habit.dart';
import 'package:streakbase/models/habit_log.dart';
import 'package:streakbase/services/database_service.dart';

class HabitProvider with ChangeNotifier {
  final DatabaseService _db;
  
  List<Habit> _habits = [];
  List<HabitLog> _logs = [];
  bool _isLoading = false;

  HabitProvider({required DatabaseService db}) : _db = db;

  List<Habit> get habits => _habits;
  List<HabitLog> get logs => _logs;
  bool get isLoading => _isLoading;

  Future<void> loadHabits() async {
    _isLoading = true;
    notifyListeners();

    try {
      _habits = await _db.getHabits();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLogs() async {
    _isLoading = true;
    notifyListeners();

    try {
      _logs = [];
      for (var habit in _habits) {
        if (habit.id != null) {
          final habitLogs = await _db.getHabitLogs(habit.id!);
          _logs.addAll(habitLogs);
        }
      }
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addHabit(Habit habit) async {
    try {
      final id = await _db.insertHabit(habit);
      final newHabit = habit.copyWith(id: id);
      _habits.add(newHabit);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateHabit(Habit habit) async {
    try {
      if (habit.id == null) return;

      await _db.updateHabit(habit);
      final index = _habits.indexWhere((h) => h.id == habit.id);
      if (index != -1) {
        _habits[index] = habit;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteHabit(int id) async {
    try {
      await _db.deleteHabit(id);
      _habits.removeWhere((h) => h.id == id);
      _logs.removeWhere((log) => log.habitId == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logHabit(HabitLog log) async {
    try {
      final id = await _db.insertHabitLog(log);
      final newLog = log.copyWith(id: id);
      _logs.add(newLog);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteLog(int id) async {
    try {
      await _db.deleteHabitLog(id);
      _logs.removeWhere((log) => log.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  List<HabitLog> getLogsForDate(DateTime date) {
    return _logs.where((log) {
      final logDate = DateTime(log.date.year, log.date.month, log.date.day);
      final targetDate = DateTime(date.year, date.month, date.day);
      return logDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  List<HabitLog> getLogsForHabit(int habitId) {
    return _logs.where((log) => log.habitId == habitId).toList();
  }

  Habit? getHabitById(int id) {
    try {
      return _habits.firstWhere((h) => h.id == id);
    } catch (e) {
      return null;
    }
  }
} 