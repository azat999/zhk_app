import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AdminRequestDetailsPage extends StatefulWidget {
  final int requestId;

  const AdminRequestDetailsPage(Map<String, dynamic> request, {
    Key? key,
    required this.requestId,
  }) : super(key: key);

  @override
  _AdminRequestDetailsPageState createState() => _AdminRequestDetailsPageState();
}

class _AdminRequestDetailsPageState extends State<AdminRequestDetailsPage> {
  bool isLoading = true;
  bool isExecutorsLoading = true;

  Map<String, dynamic>? requestDetails;
  List<Map<String, dynamic>> executors = [];

  List<String> dateOptions = [];
  List<String> timeOptions = [];

  final List<Map<String, String>> statuses = [
    {'value': 'created', 'label': 'Подана'},
    {'value': 'in_progress', 'label': 'В процессе'},
    {'value': 'completed', 'label': 'Завершена'},
    {'value': 'rejected', 'label': 'Отклонена'},
    {'value': 'responsible_added', 'label': 'Ответственный назначен'},
    {'value': 'responsible_change', 'label': 'Ответственный переназначен'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchRequestDetails();
    _fetchExecutors();
  }

  Future<void> _fetchRequestDetails() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      debugPrint('Токен отсутствует.');
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final url = Uri.parse(
        'https://sabahome.kz/main/applications/${widget.requestId}/admin-details',
      );
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          requestDetails = json.decode(utf8.decode(response.bodyBytes));
          _generateDateOptions();
          _generateTimeOptions();
          isLoading = false;
        });
      } else {
        debugPrint('Ошибка загрузки данных: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки данных: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchExecutors() async {
    setState(() {
      isExecutorsLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final housingComplexName = prefs.getString('housing_complex_name');

    if (token == null) {
      debugPrint('Токен отсутствует.');
      setState(() {
        isExecutorsLoading = false;
      });
      return;
    }

    if (housingComplexName == null) {
      debugPrint('Название ЖК отсутствует в SharedPreferences.');
      setState(() {
        isExecutorsLoading = false;
      });
      return;
    }

    try {
      final encodedName = Uri.encodeComponent(housingComplexName);
      final url = Uri.parse(
        'https://sabahome.kz/main/users/executors-by-housing-complex/?name=$encodedName',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          executors = List<Map<String, dynamic>>.from(
            json.decode(utf8.decode(response.bodyBytes)),
          );
          isExecutorsLoading = false;
        });
      } else {
        debugPrint('Ошибка загрузки исполнителей: ${response.statusCode}');
        setState(() {
          isExecutorsLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка при выполнении запроса: $e');
      setState(() {
        isExecutorsLoading = false;
      });
    }
  }

  void _generateDateOptions() {
    if (requestDetails == null || requestDetails!['created_at'] == null) return;

    final startDate = DateTime.parse(requestDetails!['created_at']);
    final endDate = startDate.add(const Duration(days: 30));

    final List<String> dates = [];
    for (DateTime date = startDate;
        !date.isAfter(endDate);
        date = date.add(const Duration(days: 1))) {
      dates.add(DateFormat('yyyy-MM-dd').format(date));
    }

    setState(() {
      dateOptions = dates;
    });
  }

  void _generateTimeOptions() {
    final List<String> times = [];
    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += 15) {
        final hh = hour.toString().padLeft(2, '0');
        final mm = minute.toString().padLeft(2, '0');
        times.add('$hh:$mm');
      }
    }
    setState(() {
      timeOptions = times;
    });
  }

  Future<void> _saveChanges() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      debugPrint('Токен отсутствует.');
      return;
    }

    if (requestDetails == null) return;

    try {
      final url = Uri.parse(
        'https://sabahome.kz/main/applications/${widget.requestId}/admin-update/',
      );

      String? executeAt = requestDetails!['execute_at'];
      if (executeAt == null || executeAt.isEmpty) {
        // если почему-то не задано
        executeAt = DateTime.now().toIso8601String();
      }

      final parsedDateTime = DateTime.parse(executeAt);
      final formattedExecuteAt = parsedDateTime.toUtc().toIso8601String();

      final body = {
        'executor': requestDetails!['executor'],
        'execute_at': formattedExecuteAt,
        'status': requestDetails!['status'],
      };

      debugPrint('--- Отправка данных на сервер ---');
      debugPrint('Тело запроса: ${json.encode(body)}');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        debugPrint('Изменения успешно сохранены.');
        Navigator.pop(context); // возвращаемся на предыдущий экран
      } else {
        debugPrint('Ошибка при сохранении: ${response.statusCode}');
        debugPrint('Ответ сервера: ${response.body}');
      }
    } catch (e) {
      debugPrint('Ошибка при выполнении запроса: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Если еще грузим
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Если уже закончили грузить, но данные не пришли
    if (requestDetails == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Детали заявки')),
        body: const Center(
          child: Text('Ошибка загрузки данных', style: TextStyle(fontSize: 16)),
        ),
      );
    }

    // Здесь уже есть requestDetails
    final requestTitle = requestDetails!['title']?.toString() ?? 'Без названия';
    final requestComment = requestDetails!['comment']?.toString() ?? 'Нет комментария';
    final photoVideo = requestDetails!['photo_video'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали заявки'),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Если есть картинка (photo_video)
            if (photoVideo != null && photoVideo.toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'https://sabahome.kz$photoVideo',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),

            // Название заявки
            Text(
              requestTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Комментарий (заголовок + сам текст)
            const Text(
              'Комментарий',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              requestComment,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),

            // Блок "Исполнитель"
            const Text(
              'Исполнитель',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
           Container(
  height: 31,
  width: 175,
  child: DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFFFBA00)),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButton<String>(
        // Стиль текста для всех пунктов меню
        style: const TextStyle(
          fontSize: 14,     // размер шрифта
          color: Colors.black,
        ),
        // Высота одного пункта меню (по умолчанию ~48), можно менять
        itemHeight: 48,
        // Вместе с itemHeight можно задать menuMaxHeight, если нужно
        // menuMaxHeight: 300,

        value: requestDetails!['executor'],
        isExpanded: true,
        underline: const SizedBox(),
        items: executors.map((e) {
          return DropdownMenuItem<String>(
            value: e['id'],
            // Добавляем внутренний отступ в каждом пункте
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(e['full_name'].toString()),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            requestDetails!['executor'] = value;
          });
        },
      ),
    ),
  ),
),
            const SizedBox(height: 10),

            // Блок "Когда исполнить"
            const Text(
              'Когда исполнить',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
         
            Row(
              children: [
                // Dropdown "Дата"
                Expanded(
                  child: Container(
                    width: 133,
                    height: 31,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFFFBA00)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButton<String>(
                          value: dateOptions.contains(
                            requestDetails!['execute_at']?.split('T')[0],
                          )
                              ? requestDetails!['execute_at']?.split('T')[0]
                              : null,
                          isExpanded: true,
                          underline: const SizedBox(),
                          hint: const Text('д-д.м-м.г-г'),
                          items: dateOptions.map((date) {
                            return DropdownMenuItem<String>(
                              value: date,
                              child: Text(date),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              final timePart =
                                  requestDetails!['execute_at']?.split('T')[1] ?? '00:00:00';
                              requestDetails!['execute_at'] = '${value}T$timePart';
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Dropdown "Время"
                Expanded(
                  child: Container(
                    height: 31,
                    width: 72,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFFFBA00)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: DropdownButton<String>(
                            value: timeOptions.contains(
                              requestDetails!['execute_at']
                                  ?.split('T')[1]
                                  ?.substring(0, 5),
                            )
                                ? requestDetails!['execute_at']
                                    ?.split('T')[1]
                                    ?.substring(0, 5)
                                : null,
                            isExpanded: true,
                            underline: const SizedBox(),
                            hint: const Text('--:--'),
                            items: timeOptions.map((time) {
                              return DropdownMenuItem<String>(
                                value: time,
                                child: Text(time),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                final datePart =
                                    requestDetails!['execute_at']?.split('T')[0] ?? '';
                                requestDetails!['execute_at'] = '${datePart}T$value:00';
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Блок "Статус"
            const Text(
              'Статус',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 175,
              height: 31,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFFBA00)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    value: requestDetails!['status'],
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: statuses.map((st) {
                      return DropdownMenuItem<String>(
                        value: st['value'],
                        child: Text(st['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        requestDetails!['status'] = value;
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Кнопки "Сохранить" и "Отменить"
            Center(
              child: Column(
                children: [
                  // Сохранить (градиент)
                
                     Container(
                      height: 48,
                      width: 326,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
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
                            color: Color(0xFFFFBB00),
                            offset: Offset(0, 0),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: _saveChanges,
                        child: const Text(
                          'Сохранить',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 14,),
              
                  // Отменить (белая, с желтой рамкой)
                 
                    Container(
                      height: 48,
                      width: 326,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Color(0xFFFFBA00),
                          width: 1.5,
                        ),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Отменить',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFFBA00),
                          ),
                        ),
                      ),
                    ),
                  
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
