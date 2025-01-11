import 'package:flutter/material.dart';
import 'category.dart';
import '../utils/exceptions.dart';  // Add this import

class Habit {
  final int? id;
  final String name;
  final DateTime? startDate;
  final String? notes;
  final Category? category;

  Habit({
    this.id,
    required this.name,
    this.startDate,
    this.notes,
    this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'start_date': startDate?.toIso8601String(),
      'notes': notes,
      'category_id': category?.id,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    try {
      final habit = Habit(
        id: json['id'] as int?,
        name: json['name'] as String,
        startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : null,
        notes: json['notes'] as String?,
        // Category will be set later by the provider
      );
      habit.validate();
      return habit;
    } catch (e) {
      throw ValidationException('Invalid habit data: ${e.toString()}');
    }
  }

  Habit copyWith({
    int? id,
    String? name,
    DateTime? startDate,
    String? notes,
    Category? category,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      notes: notes ?? this.notes,
      category: category ?? this.category,
    );
  }

  void validate() {
    if (name.trim().isEmpty) {
      throw ValidationException('Habit name cannot be empty');
    }
    if (name.length > 50) {
      throw ValidationException('Habit name too long');
    }
    if (notes != null && notes!.length > 500) {
      throw ValidationException('Notes too long');
    }
    if (startDate != null && startDate!.isAfter(DateTime.now())) {
      throw ValidationException('Start date cannot be in the future');
    }
  }
}

// No changes needed for dark mode