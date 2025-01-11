import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streakbase/models/habit.dart';
import 'package:streakbase/models/habit_log.dart';
import 'package:streakbase/models/category.dart';
import 'package:streakbase/providers/habit_provider.dart';
import 'package:streakbase/providers/category_provider.dart';
import 'package:streakbase/widgets/habit_heatmap.dart';
import 'package:streakbase/widgets/category_selector.dart';
import 'package:intl/intl.dart';
import 'package:streakbase/utils/exceptions.dart';  // Add this import

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
  Category? _selectedFilterCategory;
  String _sortBy = 'name'; // 'name', 'date', 'streak'
  bool _sortAscending = true;

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
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          _formatDate(date),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (habitLogs.isEmpty)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'No logs for this date',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          _showLogHabitDialog(context, habit, date);
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Log'),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: habitLogs.length,
                      itemBuilder: (context, index) {
                        final log = habitLogs[index];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            log.completed ? Icons.check_circle : Icons.circle_outlined,
                            color: log.completed ? Colors.green : Colors.grey,
                            size: 20,
                          ),
                          title: Text(
                            DateFormat('h:mm a').format(log.date),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          subtitle: log.notes != null ? Text(
                            log.notes!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ) : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () async {
                              await context.read<HabitProvider>().deleteLog(log.id!);
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        _showLogHabitDialog(context, habit, date);
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Another Log'),
                    ),
                  ],
                ),
            ],
          ),
        ),
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

  // Add this helper method
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError 
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500), // Reduced from default 4000ms
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'OK',  // Changed from 'Dismiss' to be more concise
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _handleError(Function action, String errorMessage) async {
    try {
      await action();
    } catch (e) {
      _showSnackBar(
        errorMessage + (e is HabitException ? ': ${e.message}' : ''),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'StreakBase',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: _selectedFilterCategory != null ? PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Filtered by: ${_selectedFilterCategory!.name}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () => setState(() => _selectedFilterCategory = null),
                  tooltip: 'Clear filter',
                ),
              ],
            ),
          ),
        ) : null,
        actions: [
          // Sort button
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.sort),
                if (_sortBy != 'name')
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 8,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showSortDialog(context),
            tooltip: 'Sort habits',
          ),
          // Filter button
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _selectedFilterCategory != null ? Theme.of(context).colorScheme.primary : null,
            ),
            onPressed: () => _showFilterDialog(context),
            tooltip: 'Filter habits',
          ),
          // Add habit button
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton.filled(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddHabitDialog(context, _selectedFilterCategory),
              tooltip: 'Add new habit',
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
      body: Consumer<HabitProvider>(
        builder: (context, habitProvider, child) {
          if (habitProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          }

          // Filter and sort habits
          var filteredHabits = habitProvider.habits;
          if (_selectedFilterCategory != null) {
            filteredHabits = filteredHabits.where((h) => h.category?.id == _selectedFilterCategory!.id).toList();
          }

          // Sort habits
          filteredHabits.sort((a, b) {
            int comparison;
            switch (_sortBy) {
              case 'name':
                comparison = a.name.compareTo(b.name);
                break;
              case 'date':
                final aDate = a.startDate ?? DateTime.now();
                final bDate = b.startDate ?? DateTime.now();
                comparison = aDate.compareTo(bDate);
                break;
              case 'streak':
                final aLogs = habitProvider.getLogsForHabit(a.id!);
                final bLogs = habitProvider.getLogsForHabit(b.id!);
                final aStreak = _calculateStreak(aLogs);
                final bStreak = _calculateStreak(bLogs);
                comparison = aStreak.compareTo(bStreak);
                break;
              default:
                comparison = 0;
            }
            return _sortAscending ? comparison : -comparison;
          });

          return RefreshIndicator(
            onRefresh: () async {
              await habitProvider.loadHabits();
              await habitProvider.loadLogs();
            },
            child: filteredHabits.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.track_changes,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilterCategory != null
                              ? 'No habits in this category'
                              : 'No habits yet',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedFilterCategory != null
                              ? 'Add a habit to this category'
                              : 'Add one to get started!',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => _showAddHabitDialog(context, _selectedFilterCategory),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Habit'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredHabits.length,
                    itemBuilder: (context, index) {
                      final habit = filteredHabits[index];
                      final logs = habitProvider.getLogsForHabit(habit.id!);
                      
                      return HabitHeatmap(
                        habit: habit,
                        logs: logs,
                        onDaySelected: (date) => _showHabitDetails(context, habit, date),
                        onLogToday: () => _logHabit(context, habit),
                        onLogPastDate: (_) => _showLogHabitDialog(context, habit),
                        onDelete: () => _deleteHabit(context, habit),
                        onEditCategory: () => _showEditHabitCategory(habit),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  Future<void> _logHabit(BuildContext context, Habit habit) async {
    await _handleError(
      () async {
        final log = HabitLog(
          habitId: habit.id!,
          date: DateTime.now(),
          completed: true,
        );
        await context.read<HabitProvider>().logHabit(log);
        _showSnackBar('Habit logged successfully');
      },
      'Failed to log habit',
    );
  }

  Future<void> _showLogHabitDialog(BuildContext context, Habit habit, [DateTime? selectedDate]) async {
    _selectedDate = selectedDate;
    _notesController.clear();
    TimeOfDay selectedTime = TimeOfDay.now();
    int completionCount = 1;

    return showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(selectedDate != null ? 'Add Log' : 'Log Past Date'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectedDate == null)
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Number of completions',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: completionCount > 1
                        ? () => setState(() => completionCount--)
                        : null,
                  ),
                  Text(
                    completionCount.toString(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => setState(() => completionCount++),
                  ),
                ],
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
                final date = selectedDate ?? _selectedDate;
                if (date != null) {
                  final dateTime = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );

                  // Create multiple logs based on completionCount
                  for (var i = 0; i < completionCount; i++) {
                    final log = HabitLog(
                      habitId: habit.id!,
                      date: dateTime.add(Duration(minutes: i)), // Slightly offset each log
                      completed: true,
                      notes: _notesController.text.isEmpty ? null : _notesController.text,
                    );
                    await context.read<HabitProvider>().logHabit(log);
                  }
                  Navigator.of(context).pop();
                  _showSnackBar('Added ${completionCount} log${completionCount > 1 ? 's' : ''}');
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
      _showSnackBar('Habit deleted', isError: true);
    }
  }

  Future<void> _showAddHabitDialog(BuildContext context, [Category? defaultCategory]) async {
    _nameController.clear();
    _notesController.clear();
    Category? selectedCategory = defaultCategory;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Add New Habit',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Habit Name',
                      hintText: 'Enter habit name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a habit name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'Add notes about this habit',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  CategorySelector(
                    selectedCategory: selectedCategory,
                    onCategorySelected: (category) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                    onAddCategory: () {
                      CategorySelector.showAddCategoryDialog(context, () {
                        // Preserve the dialog state and update categories
                        setState(() {});
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
            FilledButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await _handleError(
                    () async {
                      final habit = Habit(
                        name: _nameController.text.trim(),
                        startDate: DateTime.now(),
                        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                        category: selectedCategory,
                      );
                      await context.read<HabitProvider>().addHabit(habit);
                      Navigator.of(context).pop();
                      _showSnackBar('Habit created successfully');
                    },
                    'Failed to create habit',
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateStreak(List<HabitLog> logs) {
    if (logs.isEmpty) return 0;

    final sortedLogs = logs.where((log) => log.completed).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (sortedLogs.isEmpty) return 0;

    // Check if the streak is current (has a log for today or yesterday)
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final latestLogDate = DateTime(
      sortedLogs.first.date.year,
      sortedLogs.first.date.month,
      sortedLogs.first.date.day,
    );
    final difference = today.difference(latestLogDate).inDays;
    if (difference > 1) return 0; // Streak is broken if no log for today or yesterday

    int streak = 1;
    DateTime lastDate = latestLogDate;

    for (var i = 1; i < sortedLogs.length; i++) {
      final logDate = DateTime(
        sortedLogs[i].date.year,
        sortedLogs[i].date.month,
        sortedLogs[i].date.day,
      );
      
      final dayDifference = lastDate.difference(logDate).inDays;
      if (dayDifference == 1) {
        streak++;
        lastDate = logDate;
      } else {
        break;
      }
    }

    return streak;
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Habits'),
        content: SingleChildScrollView(
          child: Consumer<CategoryProvider>(
            builder: (context, categoryProvider, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Clear filter option
                  ListTile(
                    leading: const Icon(Icons.clear_all),
                    title: const Text('All Habits'),
                    selected: _selectedFilterCategory == null,
                    onTap: () {
                      setState(() => _selectedFilterCategory = null);
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(),
                  // Category options
                  ...categoryProvider.categories.map((category) {
                    return ListTile(
                      leading: Icon(category.icon, color: category.color),
                      title: Text(category.name),
                      selected: _selectedFilterCategory?.id == category.id,
                      onTap: () {
                        setState(() => _selectedFilterCategory = category);
                        Navigator.pop(context);
                      },
                    );
                  }),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              CategorySelector.showAddCategoryDialog(context, () {
                _showFilterDialog(context);
              });
            },
            child: const Text('Add Category'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Habits'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('By Name'),
              trailing: _sortBy == 'name' ? Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
              ) : null,
              selected: _sortBy == 'name',
              onTap: () {
                setState(() {
                  if (_sortBy == 'name') {
                    _sortAscending = !_sortAscending;
                  } else {
                    _sortBy = 'name';
                    _sortAscending = true;
                  }
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('By Date Added'),
              trailing: _sortBy == 'date' ? Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
              ) : null,
              selected: _sortBy == 'date',
              onTap: () {
                setState(() {
                  if (_sortBy == 'date') {
                    _sortAscending = !_sortAscending;
                  } else {
                    _sortBy = 'date';
                    _sortAscending = false;
                  }
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_fire_department),
              title: const Text('By Current Streak'),
              trailing: _sortBy == 'streak' ? Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
              ) : null,
              selected: _sortBy == 'streak',
              onTap: () {
                setState(() {
                  if (_sortBy == 'streak') {
                    _sortAscending = !_sortAscending;
                  } else {
                    _sortBy = 'streak';
                    _sortAscending = false;
                  }
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditHabitCategory(Habit habit) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        Category? tempCategory = habit.category;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Edit Category', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                CategorySelector(
                  selectedCategory: tempCategory,
                  onCategorySelected: (newCategory) {
                    setState(() {
                      tempCategory = newCategory;
                    });
                  },
                  onAddCategory: () {
                    Navigator.pop(context);
                    CategorySelector.showAddCategoryDialog(context, () {
                      _showEditHabitCategory(habit);
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        final updatedHabit = habit.copyWith(category: tempCategory);
                        await context.read<HabitProvider>().updateHabit(updatedHabit);
                        Navigator.of(dialogContext).pop();
                        _showSnackBar('Category updated');
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}