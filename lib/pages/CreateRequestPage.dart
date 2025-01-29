import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class CreateRequestPage extends StatefulWidget {
  @override
  _CreateRequestPageState createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends State<CreateRequestPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  XFile? _selectedMedia;
  bool _isSubmitting = false;

  Future<void> _pickMedia() async {
    final ImagePicker picker = ImagePicker();
    final XFile? media = await picker.pickImage(source: ImageSource.gallery);
    if (media != null) {
      setState(() {
        _selectedMedia = media;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Заявка',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Поле "Название заявки"
            const Text(
              'Название заявки',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Введите название вашей заявки',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),

            // Поле "Описание услуги"
            const Text(
              'Описание услуги',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Укажите больше подробностей по вашей услуге',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),

            // Поле "Добавить фото/видео"
            GestureDetector(
              onTap: _pickMedia,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFFBA00)),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: _selectedMedia == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.image, color: Color(0xFFFFBA00), size: 40),
                            SizedBox(height: 8),
                            Text(
                              'Добавить фото/видео',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFBA00),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Выбрано: ${_selectedMedia!.name}',
                          style: const TextStyle(fontSize: 14),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Поле "Комментарий"
            const Text(
              'Комментарий',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Можете добавить комментарий к вашей заявке',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const Spacer(),

            // Кнопка "Отправить"
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  backgroundColor: const Color(0xFFFFBA00),
                  foregroundColor: Colors.white,
                ),
                onPressed: _isSubmitting ? null : _submitRequest,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Отправить',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitRequest() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  if (token == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Токен недоступен')),
    );
    print('Ошибка: Токен недоступен');
    return;
  }

  final title = _titleController.text.trim();
  final description = _descriptionController.text.trim();
  final comment = _commentController.text.trim();

  if (title.isEmpty || description.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Заполните обязательные поля')),
    );
    print('Ошибка: Обязательные поля не заполнены');
    return;
  }

  setState(() {
    _isSubmitting = true;
  });

  final uri = Uri.parse('https://sabahome.kz/main/applications/');
  final request = http.MultipartRequest('POST', uri)
    ..headers['Authorization'] = 'Bearer $token'
    ..fields['title'] = title
    ..fields['description'] = description;

  if (comment.isNotEmpty) {
    request.fields['comment'] = comment;
  }

  if (_selectedMedia != null) {
    try {
      final mediaFile = await http.MultipartFile.fromPath(
        'photo_video',
        _selectedMedia!.path,
      );
      request.files.add(mediaFile);
    } catch (e) {
      print('Ошибка при добавлении медиа: $e');
    }
  }

  try {
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Успешно отправлено: ${response.body}');
      _showSuccessDialog();
    } else {
      print('Ошибка при отправке: Код ${response.statusCode}');
      print('Причина: ${response.reasonPhrase}');
      print('Ответ сервера: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${response.reasonPhrase}')),
      );
    }
  } catch (e) {
    print('Ошибка при выполнении запроса: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ошибка при отправке: $e')),
    );
  } finally {
    setState(() {
      _isSubmitting = false;
    });
  }
}

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ваша заявка принята!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Можете увидеть статус заявки в разделе "Сообщения"',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFBA00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'ОК',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
