import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:streakbase/models/habit.dart';
import 'package:streakbase/models/habit_log.dart';
import 'package:intl/intl.dart';

class HabitHeatmap extends StatelessWidget {
  final Habit habit;
  final List<HabitLog> logs;
  final Function(DateTime) onDaySelected;

  const HabitHeatmap({
    Key? key,
    required this.habit,
    required this.logs,
    required this.onDaySelected,
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

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              habit.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Started on: ${DateFormat('MMM d, y').format(habit.startDate ?? DateTime.now())}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            HeatMap(
              datasets: heatmapData,
              colorMode: ColorMode.color,
              defaultColor: Colors.grey[200],
              textColor: Colors.black,
              showColorTip: false,
              showText: false,
              scrollable: true,
              size: 30,
              colorsets: {
                1: Colors.green[300]!,
                2: Colors.green[400]!,
                3: Colors.green[500]!,
                4: Colors.green[600]!,
                5: Colors.green[700]!,
                6: Colors.green[800]!,
                7: Colors.green[900]!,
              },
              onClick: (value) {
                if (value != null) {
                  onDaySelected(value);
                }
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('No activity', Colors.grey[200]!),
                const SizedBox(width: 8),
                _buildLegendItem('${maxValue} completions', Colors.green[900]!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
} 