import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:streakbase/models/habit.dart';
import 'package:streakbase/models/habit_log.dart';
import 'package:intl/intl.dart';

class HabitHeatmap extends StatelessWidget {
  final Habit habit;
  final List<HabitLog> logs;
  final Function(DateTime) onDaySelected;
  final VoidCallback onLogToday;
  final Function(DateTime) onLogPastDate;
  final VoidCallback onDelete;

  const HabitHeatmap({
    Key? key,
    required this.habit,
    required this.logs,
    required this.onDaySelected,
    required this.onLogToday,
    required this.onLogPastDate,
    required this.onDelete,
  }) : super(key: key);

  Map<DateTime, int> _getHeatmapData() {
    Map<DateTime, int> data = {};
    
    // Filter logs for this habit and group by date
    final habitLogs = logs.where((log) => log.habitId == habit.id);
    for (var log in habitLogs) {
      if (!log.completed) continue;
      
      final date = DateTime(
        log.date.year,
        log.date.month,
        log.date.day,
      );
      
      data[date] = (data[date] ?? 0) + 1;
    }
    
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final heatmapData = _getHeatmapData();
    final maxValue = heatmapData.values.fold(0, (max, value) => value > max ? value : max);
    final currentStreak = _getCurrentStreak();
    final longestStreak = _getLongestStreak();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with habit name and actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Started on: ${DateFormat('MMM d, y').format(habit.startDate ?? DateTime.now())}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (habit.notes != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          habit.notes!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => onLogPastDate(DateTime.now()),
                      tooltip: 'Log past date',
                      style: IconButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      onPressed: onLogToday,
                      tooltip: 'Log today',
                      style: IconButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onDelete,
                      tooltip: 'Delete habit',
                      style: IconButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Logs',
                    logs.length.toString(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Current Streak',
                    '$currentStreak days',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Longest Streak',
                    '$longestStreak days',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Max/Day',
                    maxValue.toString(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Heatmap
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: HeatMap(
              datasets: heatmapData,
              colorMode: ColorMode.color,
              defaultColor: Theme.of(context).colorScheme.surfaceVariant,
              textColor: Theme.of(context).colorScheme.onSurface,
              showColorTip: false,
              showText: false,
              scrollable: true,
              size: 35,
              colorsets: {
                1: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                2: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                3: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                4: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                5: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                6: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                7: Theme.of(context).colorScheme.primary.withOpacity(0.9),
              },
              onClick: (value) {
                if (value != null) {
                  onDaySelected(value);
                }
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  int _getCurrentStreak() {
    if (logs.isEmpty) return 0;

    final sortedLogs = logs.where((log) => log.completed).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;
    DateTime? lastDate;

    for (var log in sortedLogs) {
      final logDate = DateTime(log.date.year, log.date.month, log.date.day);
      
      if (lastDate == null) {
        lastDate = logDate;
        streak = 1;
        continue;
      }

      final difference = lastDate.difference(logDate).inDays;
      if (difference == 1) {
        streak++;
        lastDate = logDate;
      } else {
        break;
      }
    }

    return streak;
  }

  int _getLongestStreak() {
    if (logs.isEmpty) return 0;

    final sortedLogs = logs.where((log) => log.completed).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    int currentStreak = 1;
    int longestStreak = 1;
    DateTime? lastDate;

    for (var log in sortedLogs) {
      final logDate = DateTime(log.date.year, log.date.month, log.date.day);
      
      if (lastDate == null) {
        lastDate = logDate;
        continue;
      }

      final difference = logDate.difference(lastDate).inDays;
      if (difference == 1) {
        currentStreak++;
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
      } else {
        currentStreak = 1;
      }
      lastDate = logDate;
    }

    return longestStreak;
  }
} 