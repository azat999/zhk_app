import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddNewsPage extends StatefulWidget {
  @override
  _AddNewsPageState createState() => _AddNewsPageState();
}

class _AddNewsPageState extends State<AddNewsPage> {
  final _titleController = TextEditingController();
  final _shortDescriptionController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _selectedImage; // Для обложки
  List<File> _additionalFiles = []; // Для дополнительных файлов
  final _formKey = GlobalKey<FormState>();

  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
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
    // Выводим информацию о добавленных файлах
    debugPrint('Файл добавлен: ${pickedFile.path}');
    debugPrint('Текущий список файлов: ${_additionalFiles.map((file) => file.path).toList()}');
  } else {
    debugPrint('Файл не был выбран');
  }
}


  Future<void> _publishNews() async {
  if (_formKey.currentState?.validate() != true) return;

  const url = 'https://sabahome.kz/main/news/create/';
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  if (token == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ошибка: токен не найден')),
    );
    return;
  }

  try {
    final request = http.MultipartRequest('POST', Uri.parse(url))
      ..headers['Authorization'] = 'Bearer $token';

    request.fields['title'] = _titleController.text;
    request.fields['short_description'] = _shortDescriptionController.text;
    request.fields['description'] = _descriptionController.text;

    if (_selectedImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'cover_image',
        _selectedImage!.path,
      ));
    }

    for (int i = 0; i < _additionalFiles.length; i++) {
      request.files.add(await http.MultipartFile.fromPath(
        'file[]', // Или используйте 'file_$i', если сервер ожидает индивидуальные поля
        _additionalFiles[i].path,
      ));
    }

    // Вывод файлов в запросе
    for (var file in request.files) {
      debugPrint('Файл в запросе: ${file.filename}, поле: ${file.field}');
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    debugPrint('Ответ от сервера: $responseBody');

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Новость успешно опубликована')),
      );
      Navigator.pop(context);
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF232323),
        title: const Text(
          'Добавление новости',
          style: TextStyle(color: Colors.yellow),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Заголовок статьи',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Введите заголовок' : null,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _selectImage,
                child: Row(
                  children: [
                    Icon(Icons.image, color: Colors.black),
                    const SizedBox(width: 8),
                    Text(
                      _selectedImage == null
                          ? 'Добавить обложку'
                          : 'Обложка выбрана',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _shortDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Краткое описание',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Введите краткое описание' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Текст',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Введите текст' : null,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _addAdditionalFile,
                child: Row(
                  children: [
                    const Icon(Icons.add, color: Colors.black),
                    const SizedBox(width: 8),
                    const Text('Добавить фото/видео'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                children: _additionalFiles.map((file) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                    child: Chip(
                      label: Text(file.path.split('/').last),
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
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _publishNews,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Опубликовать'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
