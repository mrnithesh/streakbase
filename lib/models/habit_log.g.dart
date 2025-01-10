// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HabitLog _$HabitLogFromJson(Map<String, dynamic> json) => HabitLog(
      id: (json['id'] as num?)?.toInt(),
      habitId: (json['habit_id'] as num).toInt(),
      date: DateTime.parse(json['date'] as String),
      completed: json['completed'] as bool,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$HabitLogToJson(HabitLog instance) => <String, dynamic>{
      'id': instance.id,
      'habit_id': instance.habitId,
      'date': instance.date.toIso8601String(),
      'completed': instance.completed,
      'notes': instance.notes,
    };
