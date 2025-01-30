import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ComplaintsSuggestionsPage extends StatefulWidget {
  @override
  _ComplaintsSuggestionsPageState createState() =>
      _ComplaintsSuggestionsPageState();
}

class _ComplaintsSuggestionsPageState extends State<ComplaintsSuggestionsPage> {
  final _complaintController = TextEditingController();
  File? _selectedFile;
  bool _isComplaintAgainstExecutor = false; // Состояние чекбокса
  final _formKey = GlobalKey<FormState>();

  Future<void> _selectFile() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitComplaint() async {
  if (_formKey.currentState?.validate() != true) return;

  const url = 'https://sabahome.kz/main/complaints/';
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
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['description'] = _complaintController.text
      ..fields['is_complaint_against_executor'] = _isComplaintAgainstExecutor.toString();

    if (_selectedFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'photo_video',
        _selectedFile!.path,
      ));
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    debugPrint('Ответ от сервера: $responseBody');

    if (response.statusCode == 201) {
      // Показать диалоговое окно
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Color(0xFFFFFFFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Спасибо, за обратную связь,\nдля нас это много значит!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEFAF00),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Постараемся решить ваш\nвопрос в ближайшее время',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEFAF00),
                    ),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 48,
                  width: double.infinity,
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
                     borderRadius: BorderRadius.circular(30),
                    ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Закрыть диалог
                      Navigator.pop(context); // Вернуться назад
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC832),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Закрыть', style: TextStyle(fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 255, 255, 255),),),
                  ),
                ),
              ],
            ),
          );
        },
      );
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
      backgroundColor: Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text('Жалобы/Предложения', style: TextStyle(fontWeight: FontWeight.bold),),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 40, bottom: 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Описание жалобы/предложения',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _complaintController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Можете написать жалобу или предложение анонимно, это поможет нам улучшить качество обслуживания',
                  hintStyle: TextStyle(fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Введите описание жалобы/предложения' : null,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _selectFile,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Center(
                    child: _selectedFile == null
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.image, color: Colors.orange),
                              Text(
                                'Добавить фото/видео',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ],
                          )
                        : Image.file(_selectedFile!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _isComplaintAgainstExecutor,
                    onChanged: (value) {
                      setState(() {
                        _isComplaintAgainstExecutor = value!;
                      });
                    },
                  ),
                  const Text('Жалоба на исполнителя'),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
               child: Container(
                  height: 58,
                  width: double.infinity,
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
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: InkWell(
                    onTap: _submitComplaint,
                    borderRadius: BorderRadius.circular(30), // Для эффекта нажатия
                    child: const Center(
                      child: Text(
                        'Отправить',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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
}
