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
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with habit name and actions
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
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
                          color: Theme.of(context).colorScheme.onSurface,
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
                    IconButton.filled(
                      icon: const Icon(Icons.calendar_today, size: 20),
                      onPressed: () => onLogPastDate(DateTime.now()),
                      tooltip: 'Log past date',
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      onPressed: onLogToday,
                      tooltip: 'Log today',
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: onDelete,
                      tooltip: 'Delete habit',
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.errorContainer,
                        foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Stats
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                    'Current',
                    '$currentStreak days',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Longest',
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
          // Heatmap
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: HeatMap(
              datasets: heatmapData,
              colorMode: ColorMode.color,
              defaultColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
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
                7: Theme.of(context).colorScheme.primary,
              },
              onClick: (value) {
                if (value != null) {
                  onDaySelected(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
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