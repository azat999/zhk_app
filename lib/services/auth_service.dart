import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_model.dart';

class AuthService {
  static const String _profileUrl = 'https://sabahome.kz/main/profile/';

  // Проверка авторизации
  Future<User?> fetchUserProfile(String token) async {
    final response = await http.get(
      Uri.parse(_profileUrl),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return User.fromJson(data); // Преобразуем JSON в объект User
    } else {
      // Выводим в консоль ошибку с бэкенда
      print("Ошибка при проверке авторизации: ${response.statusCode}");
      print("Ответ от сервера: ${response.body}");

      if (response.statusCode == 401) {
        return null; // Пользователь не авторизован
      } else {
        throw Exception("Ошибка при проверке авторизации: ${response.body}");
      }
    }
  }
}
