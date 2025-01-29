class User {
  final String id; // Уникальный идентификатор пользователя
  final String name; // Имя пользователя
  final String email; // Email пользователя
  final String phone; // Телефон пользователя
  final UserRole role; // Роль пользователя

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });

  // Метод для преобразования JSON в объект User
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      role: UserRoleExtension.fromValue(json['role']),
    );
  }

  // Метод для преобразования объекта User в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.value,
    };
  }
}
enum UserRole {
  RESIDENT,       // Житель
  ADMIN,          // Администратор
  EXECUTOR,       // Исполнитель
  UNREGISTERED,   // Не зарегистрированный
}

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.RESIDENT:
        return "resident";
      case UserRole.ADMIN:
        return "admin";
      case UserRole.EXECUTOR:
        return "executor";
      case UserRole.UNREGISTERED:
        return "unregistered";
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.RESIDENT:
        return "Житель";
      case UserRole.ADMIN:
        return "Администратор";
      case UserRole.EXECUTOR:
        return "Исполнитель";
      case UserRole.UNREGISTERED:
        return "Не зарегистрированный";
    }
  }

  static UserRole fromValue(String value) {
    switch (value) {
      case "resident":
        return UserRole.RESIDENT;
      case "admin":
        return UserRole.ADMIN;
      case "executor":
        return UserRole.EXECUTOR;
      case "unregistered":
        return UserRole.UNREGISTERED;
      default:
        throw Exception("Неизвестная роль пользователя: $value");
    }
  }
}
