import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class RequestDetailsPage extends StatefulWidget {
  final int requestId;

  const RequestDetailsPage({Key? key, required this.requestId})
      : super(key: key);

  @override
  _RequestDetailsPageState createState() => _RequestDetailsPageState();
}

class _RequestDetailsPageState extends State<RequestDetailsPage> {
  bool isLoading = true;
  Map<String, dynamic>? requestData;

  @override
  void initState() {
    super.initState();
    _fetchRequestDetails();
  }

  Future<void> _fetchRequestDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        debugPrint('Токен отсутствует.');
        setState(() {
          isLoading = false;
        });
        return;
      }

      final url = Uri.parse(
        'https://sabahome.kz/main/applications/${widget.requestId}/',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = json.decode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;

        setState(() {
          requestData = decodedBody;
          isLoading = false;
        });
      } else {
        debugPrint('Ошибка загрузки данных: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка при выполнении запроса: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Форматируем дату: 2025-01-15T12:58:26.385224+00:00 → 15.01.2025
  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    final parsed = DateTime.tryParse(dateString);
    if (parsed == null) return '';
    return '${parsed.day}.${parsed.month}.${parsed.year}';
  }

  /// Если нужно расширять таймлайн, чтобы искусственно добавить пункты
  /// (например, "Работа выполнена" и т.д.), делайте это тут.
  /// Если это не нужно – упростите до возврата originalTimeline, 
  /// или уберите метод совсем.
  List<Map<String, dynamic>> _expandTimeline(List<dynamic> originalTimeline) {
    final result = <Map<String, dynamic>>[];

    for (final item in originalTimeline) {
      final map = item as Map<String, dynamic>;
      final code = map['code'];
      final timestamp = map['timestamp']?.toString() ?? '';
      final executor = map['executor']?.toString() ?? '';
      final description = map['description']?.toString() ?? '';
      final newValue = map['new_value']?.toString() ?? '';

      // Пример: если code == 40, добавляем три шага:
      // "Работа выполнена", "Предоставлена обратная связь", "Заявка закрыта".
      if (code == 40) {
        result.add({
          'description': 'Работа выполнена',
          'timestamp': timestamp,
        });
        result.add({
          'description': 'Предоставлена обратная связь',
          'timestamp': timestamp,
        });
        result.add({
          'description': 'Заявка закрыта',
          'timestamp': timestamp,
        });
      } 
      // Если есть свои служебные статусы ("responsible_added"),
      // и вы хотите показать "Ответственный назначен Иванов И.И.",
      // то подставляйте executor, если именно там лежит имя.
      else if (newValue == 'responsible_added') {
        result.add({
          'description':
              'Ответственный назначен${executor.isNotEmpty ? ' $executor' : ''}',
          'timestamp': timestamp,
        });
      } else if (newValue == 'responsible_change') {
        result.add({
          'description':
              'Ответственный переназначен${executor.isNotEmpty ? ' $executor' : ''}',
          'timestamp': timestamp,
        });
      } else {
        // Иначе берём описание, как есть
        result.add({
          'description': description,
          'timestamp': timestamp,
          'executor': executor,
        });
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFFFFF),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (requestData == null) {
      return Scaffold(
        backgroundColor: Color(0xFFFFFFFF),
        appBar: AppBar(
          title: const Text('Детали заявки'),
        ),
        body: const Center(
          child: Text(
            'Ошибка загрузки данных',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    final title = requestData!['title']?.toString() ?? 'Без названия';
    final timeline = requestData!['timeline'] as List<dynamic>? ?? [];

    // Если нужно что-то "подменять" или "расширять" в timeline:
    var expandedTimeline = _expandTimeline(timeline);

    // Сортируем так, чтобы самые свежие события (бОльшая дата) были "сверху".
    // То есть по убыванию даты.
    expandedTimeline.sort((a, b) {
      final tA = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime(1970);
      final tB = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime(1970);
      return tB.compareTo(tA); 
      // Так в expandedTimeline[0] окажется самое новое событие.
    });

    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      appBar: AppBar(
        
        title: const Text(
          'Детали заявки',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Название заявки
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Таймлайн
            Expanded(
              child: ListView.builder(
                itemCount: expandedTimeline.length,
                itemBuilder: (context, index) {
                  // Получаем элемент
                  final item = expandedTimeline[index];
                  final description = item['description']?.toString() ?? '';
                  final timestamp = item['timestamp']?.toString() ?? '';

                  // Логика: если index < expandedTimeline.length - 1,
                  // то нужно рисовать вертикальную оранжевую линию "вниз" к следующему пункту
                  final isNotLast = index < expandedTimeline.length - 1;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Колонка с точкой и (при необходимости) линией
                      Column(
                        children: [
                          // Оранжевая точка
                          const Icon(
                            Icons.circle,
                            size: 14,
                            color: Colors.orange,
                          ),
                          // Если не последний элемент – рисуем вертикальную оранжевую линию
                          if (isNotLast)
                            Container(
                              width: 2,
                              height: 50, // Можно поиграться с высотой
                              color: Colors.orange,
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      // Текст и дата
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Описание события (работа выполнена, заявка закрыта, ...)
                            Expanded(
                              child: Text(
                                description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Дата в правом углу
                            Text(
                              _formatDate(timestamp),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
