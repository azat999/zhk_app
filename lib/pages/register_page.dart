import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _apartmentController = TextEditingController();

  bool _isLoading = false;
  bool _isAgreed = false; // Состояние для чекбокса
  List<dynamic> housingComplexes = []; // Список ЖК
  String? selectedHousingComplex; // Выбранный ЖК

  @override
  void initState() {
    super.initState();
    _fetchHousingComplexes(); // Загрузка ЖК при инициализации
  }

  Future<void> _fetchHousingComplexes() async {
    try {
      final response = await http.get(
        Uri.parse('https://sabahome.kz/main/housing-complexes/'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          housingComplexes = data;
        });
      } else {
        debugPrint('Ошибка при загрузке ЖК: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке ЖК: $e');
    }
  }

  Future<void> _register() async {
    if (!_isAgreed) {
      _showError('Необходимо согласиться на обработку персональных данных');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('https://sabahome.kz/main/register/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': _emailController.text,
        'password': _passwordController.text,
        'full_name': _fullNameController.text,
        'phone': _phoneController.text,
        'housing_complex': selectedHousingComplex, // Используем выбранный ЖК
        'apartment': _apartmentController.text,
      }),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 201) {
      _showSuccess('Регистрация прошла успешно. Теперь вы можете авторизоваться.');
      Navigator.pop(context);
    } else {
      final responseBody = json.decode(response.body);
      _showError(responseBody['detail'] ?? 'Произошла ошибка при регистрации');
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

  void _showSuccess(String message) {
  showDialog(
    context: context,
    barrierDismissible: false, // Запрет закрытия диалога по нажатию вне
    builder: (context) => AlertDialog(
      title: const Text('Успех'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Закрыть диалог
            Navigator.pop(context); // Вернуться на предыдущий экран
          },
          child: const Text('ОК'),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // Белый фон
      appBar: AppBar(
        title: const Text('Регистрация'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w700,
          fontFamily: 'InstrumentSans',
          fontSize: 30,
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // Закрытие клавиатуры при нажатии на пустое место
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                label: 'Ваше ФИО',
                hint: 'Введите ФИО',
                controller: _fullNameController,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Ваш номер',
                hint: '+7...',
                controller: _phoneController,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Ваш e-mail',
                hint: 'Введите e-mail',
                controller: _emailController,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Пароль',
                hint: 'Введите пароль',
                controller: _passwordController,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              const Text(
                'Выберите ЖК',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'InstrumentSans',
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedHousingComplex,
                isExpanded: true,
                items: housingComplexes.map((complex) {
                  return DropdownMenuItem<String>(
                    value: complex['id'].toString(),
                    child: Text(
                      complex['name'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'InstrumentSans',
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedHousingComplex = value;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                hint: const Text('Выберите ЖК'),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Квартира/Этаж',
                hint: 'Введите квартиру/этаж',
                controller: _apartmentController,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _isAgreed,
                    onChanged: (value) {
                      setState(() {
                        _isAgreed = value ?? false;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'Я согласен на обработку персональных данных',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        fontFamily: 'InstrumentSans',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _isAgreed && !_isLoading ? _register : null,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: _isAgreed
                        ? const LinearGradient(
                            colors: [
                              Color(0xFFFFD971),
                              Color(0xFFFFC832),
                              Color(0xFFFFBA00),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : LinearGradient(
                            colors: [
                              Colors.grey.shade300,
                              Colors.grey.shade400,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                  ),
                  child: Center(
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : Text(
                            'Зарегистрироваться',
                            style: TextStyle(
                              color: _isAgreed ? Colors.white : Colors.grey.shade600,
                              fontFamily: 'InstrumentSans',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'InstrumentSans',
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
