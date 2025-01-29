// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class UserRoleProvider extends ChangeNotifier {
//   String? _role;

//   String? get role => _role; // Геттер для роли пользователя

//   Future<void> loadRole() async {
//     // Загружаем роль пользователя из SharedPreferences
//     final prefs = await SharedPreferences.getInstance();
//     _role = prefs.getString('user_role');
//     notifyListeners(); // Уведомляем слушателей об изменении
//   }

//   Future<void> setUserRole(String role) async {
//     // Устанавливаем новую роль пользователя
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('user_role', role);
//     _role = role;
//     notifyListeners(); // Уведомляем слушателей об изменении
//   }
// }
