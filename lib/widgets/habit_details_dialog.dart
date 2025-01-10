import 'package:flutter/material.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/models/habit_log.dart';
import 'package:intl/intl.dart';

class HabitDetailsDialog extends StatelessWidget {
  final DateTime selectedDate;
  final List<Habit> habits;
  final List<HabitLog> logs;

  const HabitDetailsDialog({
    Key? key,
    required this.selectedDate,
    required this.habits,
    required this.logs,
  }) : super(key: key);

  List<HabitLog> _getLogsForDate() {
    return logs.where((log) =>
      log.date.year == selectedDate.year &&
      log.date.month == selectedDate.month &&
      log.date.day == selectedDate.day
    ).toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  String _getHabitName(int habitId) {
    final habit = habits.firstWhere(
      (h) => h.id == habitId,
      orElse: () => Habit(id: -1, name: 'Unknown Habit', createdAt: DateTime.now()),
    );
    return habit.name;
  }

  Map<int, List<HabitLog>> _groupLogsByHabit(List<HabitLog> logs) {
    Map<int, List<HabitLog>> grouped = {};
    for (var log in logs) {
      if (!grouped.containsKey(log.habitId)) {
        grouped[log.habitId] = [];
      }
      grouped[log.habitId]!.add(log);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM d, y');
    final timeFormat = DateFormat('h:mm a');
    final logsForDate = _getLogsForDate();
    final groupedLogs = _groupLogsByHabit(logsForDate);
    final completedCount = logsForDate.where((log) => log.completed).length;

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateFormat.format(selectedDate)),
          const SizedBox(height: 4),
          Text(
            '$completedCount completions',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: groupedLogs.length,
          itemBuilder: (context, index) {
            final habitId = groupedLogs.keys.elementAt(index);
            final habitLogs = groupedLogs[habitId]!;
            final completions = habitLogs.where((log) => log.completed).length;

            return ExpansionTile(
              leading: Icon(
                completions > 0 ? Icons.check_circle : Icons.circle_outlined,
                color: completions > 0 ? Colors.green : Colors.grey,
              ),
              title: Text(_getHabitName(habitId)),
              subtitle: Text('$completions completions'),
              children: habitLogs.map((log) {
                if (!log.completed) return const SizedBox.shrink();
                return ListTile(
                  leading: const SizedBox(width: 24),
                  title: Text(
                    timeFormat.format(log.timestamp),
                    style: const TextStyle(fontSize: 14),
                  ),
                  dense: true,
                );
              }).toList(),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
} 