class HabitException implements Exception {
  final String message;
  final String? details;
  HabitException(this.message, [this.details]);
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
}

class CategoryException implements Exception {
  final String message;
  CategoryException(this.message);
}
