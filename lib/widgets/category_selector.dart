import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';

class CategorySelector extends StatelessWidget {
  final Category? selectedCategory;
  final Function(Category?) onCategorySelected;
  final VoidCallback? onAddCategory;

  const CategorySelector({
    Key? key,
    this.selectedCategory,
    required this.onCategorySelected,
    this.onAddCategory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Category',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (onAddCategory != null)
                  TextButton.icon(
                    onPressed: onAddCategory,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Category'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // No category option
                FilterChip(
                  label: const Text('None'),
                  selected: selectedCategory == null,
                  onSelected: (_) => onCategorySelected(null),
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                ),
                // Category options
                ...categoryProvider.categories.map((category) {
                  return FilterChip(
                    avatar: Icon(
                      category.icon,
                      color: category.color,
                      size: 18,
                    ),
                    label: Text(category.name),
                    selected: selectedCategory?.id == category.id,
                    onSelected: (_) => onCategorySelected(category),
                    onDeleted: () => _showCategoryOptionsDialog(context, category),
                    backgroundColor: category.color.withOpacity(0.1),
                    selectedColor: category.color.withOpacity(0.2),
                    checkmarkColor: category.color,
                  );
                }),
              ],
            ),
          ],
        );
      },
    );
  }

  static Future<void> showAddCategoryDialog(BuildContext context, [VoidCallback? onComplete]) {
    return showDialog(
      context: context,
      builder: (dialogContext) {
        final nameController = TextEditingController();
        Color selectedColor = Colors.blue;
        IconData selectedIcon = Icons.star;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Add Category'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Color',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Colors.blue,
                              Colors.red,
                              Colors.green,
                              Colors.orange,
                              Colors.purple,
                              Colors.teal,
                            ].map((color) {
                              return InkWell(
                                onTap: () => setState(() => selectedColor = color),
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: color,
                                  child: selectedColor == color
                                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Icon',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Icons.star,
                              Icons.favorite,
                              Icons.work,
                              Icons.school,
                              Icons.fitness_center,
                              Icons.book,
                            ].map((icon) {
                              return InkWell(
                                onTap: () => setState(() => selectedIcon = icon),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: selectedIcon == icon
                                        ? selectedColor.withOpacity(0.1)
                                        : null,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    icon,
                                    color: selectedColor,
                                    size: 24,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty) {
                    await context.read<CategoryProvider>().addCategory(
                      Category(
                        name: nameController.text.trim(),
                        color: selectedColor,
                        icon: selectedIcon,
                      ),
                    );
                    Navigator.of(dialogContext).pop(); // Close the dialog first
                    if (onComplete != null) {
                      onComplete(); // Then call the completion callback
                    }
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCategoryOptionsDialog(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage ${category.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Category'),
              onTap: () {
                Navigator.pop(context);
                _showEditCategoryDialog(context, category);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
              title: Text('Delete Category', 
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Category'),
                    content: Text(
                      'Are you sure you want to delete "${category.name}"? '
                      'Habits in this category will be moved to "No Category".',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    await context.read<CategoryProvider>().deleteCategory(category.id!);
                    if (selectedCategory?.id == category.id) {
                      onCategorySelected(null);
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, Category category) {
    final nameController = TextEditingController(text: category.name);
    Color selectedColor = category.color;
    IconData selectedIcon = category.icon;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Color',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Colors.blue,
                            Colors.red,
                            Colors.green,
                            Colors.orange,
                            Colors.purple,
                            Colors.teal,
                          ].map((color) {
                            return InkWell(
                              onTap: () => setState(() => selectedColor = color),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: color,
                                child: selectedColor == color
                                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Icon',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Icons.star,
                            Icons.favorite,
                            Icons.work,
                            Icons.school,
                            Icons.fitness_center,
                            Icons.book,
                          ].map((icon) {
                            return InkWell(
                              onTap: () => setState(() => selectedIcon = icon),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: selectedIcon == icon
                                      ? selectedColor.withOpacity(0.1)
                                      : null,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  icon,
                                  color: selectedColor,
                                  size: 24,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final updatedCategory = Category(
                    id: category.id,
                    name: nameController.text,
                    color: selectedColor,
                    icon: selectedIcon,
                  );
                  context.read<CategoryProvider>().updateCategory(updatedCategory);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}