import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/database_service.dart';

class CategoryProvider with ChangeNotifier {
  final DatabaseService _db;
  List<Category> _categories = [];
  bool _isLoading = false;

  CategoryProvider({required DatabaseService db}) : _db = db {
    loadCategories();
  }

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  static final List<Category> defaultCategories = [
    Category(
      name: 'Health',
      color: Colors.red,
      icon: Icons.favorite,
    ),
    Category(
      name: 'Productivity',
      color: Colors.blue,
      icon: Icons.work,
    ),
    Category(
      name: 'Learning',
      color: Colors.green,
      icon: Icons.school,
    ),
    Category(
      name: 'Lifestyle',
      color: Colors.orange,
      icon: Icons.person_outline,
    ),
  ];

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await _db.getCategories();
      notifyListeners();
    } catch (e) {
      _categories = [];
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCategory(Category category) async {
    try {
      final id = await _db.insertCategory(category);
      final newCategory = category.copyWith(id: id);
      _categories.add(newCategory);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      await _db.updateCategory(category);
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _db.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Category? getCategoryById(int id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
} 