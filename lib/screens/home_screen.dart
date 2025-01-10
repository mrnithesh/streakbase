import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streakbase/models/habit.dart';
import 'package:streakbase/models/habit_log.dart';
import 'package:streakbase/providers/habit_provider.dart';
import 'package:streakbase/widgets/habit_heatmap.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Load habits when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<HabitProvider>();
    await provider.loadHabits();
    await provider.loadLogs();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return DateFormat('MMM d, y').format(date);
  }

  void _showHabitDetails(BuildContext context, Habit habit, DateTime date) {
    final logs = context.read<HabitProvider>().getLogsForDate(date);
    final habitLogs = logs.where((log) => log.habitId == habit.id).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(habit.name),
            Text(
              _formatDate(date),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: habitLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No logs for this date'),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          final now = date;
                          final log = HabitLog(
                            habitId: habit.id!,
                            date: now,
                            completed: true,
                          );
                          await context.read<HabitProvider>().logHabit(log);
                          await _loadData();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Log'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: habitLogs.length,
                  itemBuilder: (context, index) {
                    final log = habitLogs[index];
                    return ListTile(
                      leading: Icon(
                        log.completed ? Icons.check_circle : Icons.circle_outlined,
                        color: log.completed ? Colors.green : Colors.grey,
                      ),
                      title: Text(DateFormat('h:mm a').format(log.date)),
                      subtitle: log.notes != null ? Text(log.notes!) : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await context.read<HabitProvider>().deleteLog(log.id!);
                          await _loadData();
                          Navigator.of(context).pop();
                        },
                      ),
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
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StreakBase'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddHabitDialog(context),
          ),
        ],
      ),
      body: Consumer<HabitProvider>(
        builder: (context, habitProvider, child) {
          if (habitProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              await habitProvider.loadHabits();
              await habitProvider.loadLogs();
            },
            child: habitProvider.habits.isEmpty
                ? const Center(
                    child: Text('No habits yet. Add one to get started!'),
                  )
                : ListView.builder(
                    itemCount: habitProvider.habits.length,
                    itemBuilder: (context, index) {
                      final habit = habitProvider.habits[index];
                      final logs = habitProvider.getLogsForHabit(habit.id!);
                      
                      return HabitHeatmap(
                        habit: habit,
                        logs: logs,
                        onDaySelected: (date) => _showHabitDetails(context, habit, date),
                        onLogToday: () => _logHabit(context, habit),
                        onLogPastDate: (_) => _showLogHabitDialog(context, habit),
                        onDelete: () => _deleteHabit(context, habit),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  Future<void> _logHabit(BuildContext context, Habit habit) async {
    final log = HabitLog(
      habitId: habit.id!,
      date: DateTime.now(),
      completed: true,
    );
    await context.read<HabitProvider>().logHabit(log);
    await _loadData(); // Reload data after logging
  }

  Future<void> _showLogHabitDialog(BuildContext context, Habit habit) async {
    _selectedDate = null;
    _notesController.clear();
    TimeOfDay selectedTime = TimeOfDay.now();

    return showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Log Past Date'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(_selectedDate == null ? 'Select date' : _formatDate(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
              ListTile(
                title: Text('Time: ${selectedTime.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    setState(() {
                      selectedTime = picked;
                    });
                  }
                },
              ),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Add notes about this completion',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_selectedDate != null) {
                  final now = _selectedDate!;
                  final dateTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );
                  final log = HabitLog(
                    habitId: habit.id!,
                    date: dateTime,
                    completed: true,
                    notes: _notesController.text.isEmpty ? null : _notesController.text,
                  );
                  await context.read<HabitProvider>().logHabit(log);
                  await _loadData(); // Reload data after logging
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Log'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteHabit(BuildContext context, Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Are you sure you want to delete "${habit.name}"? This will also delete all logs for this habit.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<HabitProvider>().deleteHabit(habit.id!);
      await _loadData(); // Reload data after deleting
    }
  }

  Future<void> _showAddHabitDialog(BuildContext context) async {
    _nameController.clear();
    _notesController.clear();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Habit'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Habit Name',
                  hintText: 'Enter habit name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a habit name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Add notes about this habit',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final habit = Habit(
                  name: _nameController.text,
                  startDate: DateTime.now(),
                  notes: _notesController.text.isEmpty ? null : _notesController.text,
                );
                await context.read<HabitProvider>().addHabit(habit);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }
} 