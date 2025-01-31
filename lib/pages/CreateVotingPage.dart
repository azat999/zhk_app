import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CreateVotingPage extends StatefulWidget {
  @override
  _CreateVotingPageState createState() => _CreateVotingPageState();
}

class _CreateVotingPageState extends State<CreateVotingPage> {
  final _questionController = TextEditingController();
  final List<TextEditingController> _answerControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _allowMultipleAnswers = false;
  bool _isAnonymousVoting = false;

  void _addAnswerField() {
    setState(() {
      _answerControllers.add(TextEditingController());
    });
  }

  void _removeAnswerField(int index) {
    setState(() {
      _answerControllers.removeAt(index);
    });
  }

  Future<void> _submitVoting() async {
  if (_questionController.text.isEmpty ||
      _answerControllers.any((controller) => controller.text.isEmpty)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Заполните все поля')),
    );
    return;
  }

  // Собираем данные для отправки
  final options = _answerControllers.map((controller) => controller.text).toList();
  final requestBody = {
    "question": _questionController.text,
    "options": options,
    "allow_multiple": _allowMultipleAnswers,
    "is_anonymous": _isAnonymousVoting,
  };

  // Получение токена
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  if (token == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ошибка: токен не найден')),
    );
    return;
  }

  try {
    // Отправка POST-запроса
    final response = await http.post(
      Uri.parse('https://sabahome.kz/main/polls/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    // Обработка ответа
    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Голосование успешно создано')),
      );
      Navigator.pop(context); // Возврат на предыдущую страницу
    } else {
      debugPrint('Ошибка ответа: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${response.body}')),
      );
    }
  } catch (e) {
    debugPrint('Ошибка сети: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ошибка сети: $e')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Голосование'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Вопрос',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _questionController,
              decoration: InputDecoration(
                hintText: 'Задайте вопрос',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Варианты ответа',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._answerControllers.asMap().entries.map((entry) {
              int index = entry.key;
              TextEditingController controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: 'Ответ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Colors.grey, width: 1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _removeAnswerField(index),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: _addAnswerField,
              icon: const Icon(Icons.add, color: Colors.orange),
              label: const Text(
                'Добавить ответ',
                style: TextStyle(color: Colors.orange),
              ),
            ),
            SwitchListTile(
              title: const Text('Выбор нескольких ответов'),
              value: _allowMultipleAnswers,
              onChanged: (value) {
                setState(() {
                  _allowMultipleAnswers = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Анонимное голосование'),
              value: _isAnonymousVoting,
              onChanged: (value) {
                setState(() {
                  _isAnonymousVoting = value;
                });
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitVoting,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Отправить'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Отменить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
