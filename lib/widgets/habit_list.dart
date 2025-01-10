import 'package:flutter/material.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/models/habit_log.dart';
import 'package:intl/intl.dart';

class HabitList extends StatelessWidget {
  final List<Habit> habits;
  final List<HabitLog> logs;
  final Function(Habit, DateTime, bool) onHabitToggled;
  final Function(Habit) onHabitDeleted;

  const HabitList({
    Key? key,
    required this.habits,
    required this.logs,
    required this.onHabitToggled,
    required this.onHabitDeleted,
  }) : super(key: key);

  List<HabitLog> _getLogsForHabitAndDate(int habitId, DateTime date) {
    return logs.where((log) =>
      log.habitId == habitId &&
      log.date.year == date.year &&
      log.date.month == date.month &&
      log.date.day == date.day
    ).toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  void _confirmDelete(BuildContext context, Habit habit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Are you sure you want to delete "${habit.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onHabitDeleted(habit);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateFormat = DateFormat('h:mm a');

    if (habits.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No habits yet. Tap the + button to add one!',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        final logsForToday = _getLogsForHabitAndDate(habit.id!, today);
        final completionsToday = logsForToday.where((log) => log.completed).length;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ExpansionTile(
            leading: IconButton(
              icon: Icon(
                completionsToday > 0 ? Icons.check_circle : Icons.circle_outlined,
                color: completionsToday > 0 ? Colors.green : Colors.grey,
              ),
              onPressed: () => onHabitToggled(habit, today, true),
            ),
            title: Text(habit.name),
            subtitle: Text('$completionsToday completions today'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDelete(context, habit),
                ),
                const Icon(Icons.expand_more),
              ],
            ),
            children: [
              if (logsForToday.isNotEmpty) ...[
                const Divider(height: 1),
                ...logsForToday.map((log) {
                  if (!log.completed) return const SizedBox.shrink();
                  return ListTile(
                    leading: const SizedBox(width: 24),
                    title: Text(
                      'Completed at ${dateFormat.format(log.timestamp)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => onHabitToggled(habit, log.date, false),
                    ),
                    dense: true,
                  );
                }).toList(),
              ],
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton.icon(
                  onPressed: () => onHabitToggled(habit, today, true),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Completion'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 