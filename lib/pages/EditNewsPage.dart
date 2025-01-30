import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

class EditNewsPage extends StatefulWidget {
  final Map<String, dynamic> news;

  const EditNewsPage({Key? key, required this.news}) : super(key: key);

  @override
  _EditNewsPageState createState() => _EditNewsPageState();
}

class _EditNewsPageState extends State<EditNewsPage> {
  final _titleController = TextEditingController();
  final _shortDescriptionController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _coverImage;
  List<File> _additionalFiles = [];
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.news['title'] ?? '';
    _shortDescriptionController.text =
        widget.news['short_description'] ?? '';
    _descriptionController.text = widget.news['description'] ?? '';
  }

  Future<void> _selectCoverImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _coverImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _addAdditionalFile() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _additionalFiles.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _updateNews() async {
    if (_formKey.currentState?.validate() != true) return;

    final url = Uri.parse(
        'https://sabahome.kz/main/news/${widget.news['id']}/update/');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: токен не найден')),
      );
      return;
    }

    try {
      final request = http.MultipartRequest('PATCH', url)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['title'] = _titleController.text
        ..fields['short_description'] = _shortDescriptionController.text
        ..fields['description'] = _descriptionController.text;

      if (_coverImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'cover_image',
          _coverImage!.path,
        ));
      }

      for (var file in _additionalFiles) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
        ));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      debugPrint('Ответ от сервера: $responseBody');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Новость успешно обновлена')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $responseBody')),
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
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        title: const Text('Редактировать новость'),
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Заголовок статьи',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _shortDescriptionController,
                        decoration: _inputDecoration('Введите краткий заголовок'),
                        style: const TextStyle(fontSize: 14, color: Colors.black),
                        validator: (value) => value!.isEmpty
                            ? 'Введите краткий заголовок'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _selectCoverImage,
                        child: Row(
                          children: [
                            const Icon(Icons.image, size: 36),
                            const SizedBox(width: 12),
                            const Text(
                              'Добавить обложку',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Полный заголовок',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        decoration: _inputDecoration('Введите полный заголовок'),
                        style: const TextStyle(fontSize: 14, color: Colors.black),
                        validator: (value) =>
                            value!.isEmpty ? 'Введите полный заголовок' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Текст статьи',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 5,
                        decoration: _inputDecoration('Введите текст'),
                        style: const TextStyle(fontSize: 14, color: Colors.black),
                        validator: (value) =>
                            value!.isEmpty ? 'Введите текст статьи' : null,
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _addAdditionalFile,
                        child: Row(
                          children: const [
                            Icon(Icons.add),
                            SizedBox(width: 8),
                            Text(
                              'Добавить фото/видео',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        children: _additionalFiles.map((file) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Chip(
                              label: Text(p.basename(file.path)),
                              deleteIcon: const Icon(Icons.close),
                              onDeleted: () {
                                setState(() {
                                  _additionalFiles.remove(file);
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 15),
              child: SizedBox(
                width: double.infinity, // Кнопка занимает всю ширину
                height: 48, // Высота кнопки
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFD971),
                        Color(0xFFFFC832),
                        Color(0xFFFFBA00),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFBB00).withOpacity(0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _updateNews,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Опубликовать',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.grey, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE9E9E9), width: 2.0),
      ),
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
    );
  }
}
