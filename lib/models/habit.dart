import 'package:flutter/material.dart';
import 'category.dart';

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
    return Habit(
      id: json['id'] as int?,
      name: json['name'] as String,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : null,
      notes: json['notes'] as String?,
      // Category will be set later by the provider
    );
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
} 