import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class VotingPage extends StatefulWidget {
  @override
  _VotingPageState createState() => _VotingPageState();
}

class _VotingPageState extends State<VotingPage> {
  List<dynamic> _polls = [];
  Map<int, List<bool>> _selectedCheckboxes = {};
  Map<int, int?> _selectedRadioButtons = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPolls();
  }

  Future<void> _fetchPolls() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      debugPrint('Ошибка: токен не найден');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: токен не найден')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final url = Uri.parse('https://sabahome.kz/main/polls/');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _polls = data;

          for (var poll in data) {
            _selectedCheckboxes[poll['id']] =
                List<bool>.filled((poll['options'] as List).length, false);
            _selectedRadioButtons[poll['id']] = null;
          }

          _isLoading = false;
        });
      } else {
        debugPrint('Ошибка загрузки данных: ${response.body}');
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: ${response.body}')),
        );
      }
    } catch (e) {
      debugPrint('Ошибка сети: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сети: $e')),
      );
    }
  }

  Future<void> _submitVote(int pollId, List<String> selectedOptions) async {
    if (selectedOptions.isEmpty) {
      debugPrint('Ошибка: пользователь не выбрал ни одного ответа');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: выберите хотя бы один вариант ответа')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      debugPrint('Ошибка: токен не найден');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: токен не найден')),
      );
      return;
    }

    final url = Uri.parse('https://sabahome.kz/main/polls/$pollId/vote/');

    final body = json.encode({'selected_options': selectedOptions});

    try {
      debugPrint('Отправка голосов для опроса ID: $pollId - Данные: $body');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        debugPrint('Голос успешно отправлен');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ваш голос принят')),
        );

        _fetchPolls();
      } else {
        debugPrint('Ошибка голосования: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка голосования: ${response.body}')),
        );
      }
    } catch (e) {
      debugPrint('Ошибка сети при отправке голосования: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сети: $e')),
      );
    }
  }

  String formatDateTime(String isoDate) {
    final parsedDate = DateTime.parse(isoDate);
    return '${parsedDate.day.toString().padLeft(2, '0')}.${parsedDate.month.toString().padLeft(2, '0')}.${parsedDate.year}';
  }

  Widget _buildCheckboxOptions(List<dynamic> options, int pollId) {
    final optionsAsString = options.cast<String>();

    return Column(
      children: optionsAsString.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;

        return Row(
          children: [
            Checkbox(
              value: _selectedCheckboxes[pollId]![index],
              onChanged: (value) {
                setState(() {
                  _selectedCheckboxes[pollId]![index] = value!;
                });
              },
            ),
            Expanded(
              child: Text(
                option,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildRadioOptions(List<dynamic> options, int pollId) {
    final optionsAsString = options.cast<String>();

    return Column(
      children: optionsAsString.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;

        return Row(
          children: [
            Radio<int>(
              value: index,
              groupValue: _selectedRadioButtons[pollId],
              onChanged: (value) {
                setState(() {
                  _selectedRadioButtons[pollId] = value;
                });
              },
            ),
            Expanded(
              child: Text(
                option,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPollCard(Map<String, dynamic> poll) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            poll['question'],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                poll['is_anonymous'] ? 'Анонимный опрос' : 'Публичный опрос',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 36),
              Text(
                '${formatDateTime(poll['created_at'])} - ${formatDateTime(poll['ends_at'])}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFFF5858),
                  fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          poll['allow_multiple']
              ? _buildCheckboxOptions(poll['options'], poll['id'])
              : _buildRadioOptions(poll['options'], poll['id']),
          const SizedBox(height: 6),

          
          

          Container(
            height: 48,
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
            child: ElevatedButton(
              onPressed: () {
                final List<String> selectedOptions = [];
            
                if (poll['allow_multiple']) {
                  for (var i = 0; i < poll['options'].length; i++) {
                    if (_selectedCheckboxes[poll['id']]![i]) {
                      selectedOptions.add(poll['options'][i].toString());
                    }
                  }
                } else {
                  if (_selectedRadioButtons[poll['id']] != null) {
                    selectedOptions.add(
                        poll['options'][_selectedRadioButtons[poll['id']]!].toString());
                  }
                }
            
                _submitVote(poll['id'], selectedOptions);
              },
              style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
              child: const Text('Проголосовать', style: TextStyle(
                color: Color(0xFFFFFFFF,),
                fontSize: 16,
                fontWeight: FontWeight.bold
              ),),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              '${poll['total_votes']} голосов',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      appBar: AppBar(title: const Text('Голосование'),backgroundColor: const Color(0xFFFFFFFF),),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _polls.length,
              itemBuilder: (context, index) {
                return _buildPollCard(_polls[index]);
              },
            ),
    );
  }
}
