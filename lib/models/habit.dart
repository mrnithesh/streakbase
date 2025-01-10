import 'package:json_annotation/json_annotation.dart';

part 'habit.g.dart';

@JsonSerializable()
class Habit {
  final int? id;
  final String name;
  @JsonKey(name: 'start_date')
  final DateTime? startDate;
  final String? notes;
  final String? category;

  Habit({
    this.id,
    required this.name,
    this.startDate,
    this.notes,
    this.category,
  });

  // JSON serialization
  factory Habit.fromJson(Map<String, dynamic> json) => _$HabitFromJson(json);
  Map<String, dynamic> toJson() => _$HabitToJson(this);

  // Create a copy of the habit with some fields replaced
  Habit copyWith({
    int? id,
    String? name,
    DateTime? startDate,
    String? notes,
    String? category,
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