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
    Future.microtask(() async {
      final provider = context.read<HabitProvider>();
      await provider.loadHabits();
      await provider.loadLogs();
    });
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
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: habitLogs.isEmpty
              ? const Text('No logs for this date')
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
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  if (habitProvider.habits.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No habits yet. Add one to get started!'),
                    ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: habitProvider.habits.length,
                    itemBuilder: (context, index) {
                      final habit = habitProvider.habits[index];
                      final logs = habitProvider.getLogsForHabit(habit.id!);
                      
                      return Column(
                        children: [
                          HabitHeatmap(
                            habit: habit,
                            logs: logs,
                            onDaySelected: (date) => _showHabitDetails(context, habit, date),
                          ),
                          Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Column(
                              children: [
                                ListTile(
                                  title: Text(habit.name),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Started on: ${_formatDate(habit.startDate)}'),
                                      if (habit.notes != null) Text('Notes: ${habit.notes}'),
                                      Text('Total logs: ${logs.length}'),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.calendar_today),
                                        onPressed: () => _showLogHabitDialog(context, habit),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.check_circle_outline),
                                        onPressed: () => _logHabit(context, habit),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _deleteHabit(context, habit),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
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
  }

  Future<void> _showLogHabitDialog(BuildContext context, Habit habit) async {
    _selectedDate = null;
    _notesController.clear();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Habit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(_selectedDate == null ? 'Select date' : _formatDate(_selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
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
                final log = HabitLog(
                  habitId: habit.id!,
                  date: _selectedDate!,
                  completed: true,
                  notes: _notesController.text.isEmpty ? null : _notesController.text,
                );
                await context.read<HabitProvider>().logHabit(log);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Log'),
          ),
        ],
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

    if (confirmed == true && habit.id != null) {
      await context.read<HabitProvider>().deleteHabit(habit.id!);
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