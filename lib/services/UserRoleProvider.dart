import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserRoleProvider extends ChangeNotifier {
  String? _role;
  bool _isAuthenticated = false;

  String? get role => _role;
  bool get isAuthenticated => _isAuthenticated;

  // Метод для инициализации провайдера
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _role = prefs.getString('user_role');
      _isAuthenticated = prefs.getString('access_token') != null;
      debugPrint('Инициализация: роль - $_role, авторизован - $_isAuthenticated');
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка при инициализации UserRoleProvider: $e');
    }
  }

  // Метод для установки роли пользователя
  Future<void> setUserRole(String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', role);
      _role = role;
      _isAuthenticated = true;
      debugPrint('Роль установлена: $_role');
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка при установке роли: $e');
    }
  }

  // Метод для загрузки роли пользователя из SharedPreferences
  Future<void> loadRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _role = prefs.getString('user_role');
      _isAuthenticated = prefs.getString('access_token') != null;
      debugPrint('Роль загружена: $_role, авторизован - $_isAuthenticated');
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка при загрузке роли: $e');
    }
  }

  // Метод для выхода из системы
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_role');
      await prefs.remove('access_token');
      _role = null;
      _isAuthenticated = false;
      debugPrint('Пользователь вышел из системы');
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка при выходе из системы: $e');
    }
  }
}
