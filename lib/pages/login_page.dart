import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhk_app/services/UserRoleProvider.dart';
import 'package:http/http.dart' as http;
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('https://sabahome.kz/main/login/');
      final response = await http.post(
        url,
        body: {
          'email': _emailController.text,
          'password': _passwordController.text,
        },
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', responseData['access']);
        await prefs.setString('refresh_token', responseData['refresh']);
        await prefs.setString('user_role', responseData['role']);

        final userRoleProvider = Provider.of<UserRoleProvider>(context, listen: false);
        await userRoleProvider.setUserRole(responseData['role']);

        debugPrint('Успешная авторизация. Роль: ${responseData['role']}');
        Navigator.pop(context, true); // Возвращаемся на предыдущий экран
      } else {
        _showError('Неверный email или пароль');
        debugPrint('Ошибка авторизации: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Ошибка сети. Попробуйте позже.');
      debugPrint('Ошибка сети: $e');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Container(
            color: const Color(0xFFFFFFFF),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Text(
                    'Введите почту и пароль',
                    style: TextStyle(
                      fontFamily: 'InstrumentSans',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Center(
                  child: Text(
                    'Чтобы войти или зарегистрироваться',
                    style: TextStyle(
                      fontFamily: 'InstrumentSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: -0.3,
                      color: Color(0xFF9C9C9C),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _buildInputField(
                  controller: _emailController,
                  hintText: 'Введите e-mail',
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  controller: _passwordController,
                  hintText: 'Введите пароль',
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                _buildLoginButton(),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterPage()),
                    );
                  },
                  child: const Text(
                    'Регистрация',
                    style: TextStyle(
                      color: Color(0xFF000000),
                      fontFamily: 'InstrumentSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFBB00).withOpacity(0.6),
            blurRadius: 4,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontFamily: 'InstrumentSans',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF9C9C9C),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _login,
      child: Container(
        height: 58,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFD971),
              Color(0xFFFFC832),
              Color(0xFFFFBA00),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFBB00).withOpacity(0.4),
              blurRadius: 4,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Войти',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'InstrumentSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}
