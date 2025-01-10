import 'package:json_annotation/json_annotation.dart';

part 'habit_log.g.dart';

@JsonSerializable()
class HabitLog {
  final int? id;
  @JsonKey(name: 'habit_id')
  final int habitId;
  final DateTime date;
  final bool completed;
  final String? notes;

  HabitLog({
    this.id,
    required this.habitId,
    required this.date,
    required this.completed,
    this.notes,
  });

  // JSON serialization
  factory HabitLog.fromJson(Map<String, dynamic> json) => _$HabitLogFromJson(json);
  Map<String, dynamic> toJson() => _$HabitLogToJson(this);

  // Create a copy of the habit log with some fields replaced
  HabitLog copyWith({
    int? id,
    int? habitId,
    DateTime? date,
    bool? completed,
    String? notes,
  }) {
    return HabitLog(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      completed: completed ?? this.completed,
      notes: notes ?? this.notes,
    );
  }
} 