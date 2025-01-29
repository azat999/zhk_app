// import 'package:flutter/material.dart';
// import 'package:zhk_app/services/news_service.dart';
// import 'package:zhk_app/models/news_model.dart';

// // Главная страница с новостями
// class NewsPage extends StatefulWidget {
//   @override
//   _NewsPageState createState() => _NewsPageState();
// }

// class _NewsPageState extends State<NewsPage> {
//   final NewsService _newsService = NewsService();
//   late Future<List<News>> _newsFuture;

//   @override
//   void initState() {
//     super.initState();
//     _newsFuture = _newsService.fetchNews();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<List<News>>(
//       future: _newsFuture,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         } else if (snapshot.hasError) {
//           return Center(child: Text('Ошибка: ${snapshot.error}'));
//         } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return const Center(child: Text('Нет новостей'));
//         } else {
//           final newsList = snapshot.data!;
//           return ListView.builder(
//             itemCount: newsList.length,
//             itemBuilder: (context, index) {
//               final news = newsList[index];
//               return Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Stack(
//                   children: [
//                     Container(
//                       width: double.infinity,
//                       height: 200,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(12),
//                         image: DecorationImage(
//                           image: NetworkImage(
//                             'https://sabahome.kz${news.coverImage}',
//                           ),
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                     ),
//                     Container(
//                       width: double.infinity,
//                       height: 200,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(12),
//                         color: Colors.black.withOpacity(0.5), // Тёмный слой
//                       ),
//                     ),
//                     Positioned(
//                       left: 16,
//                       bottom: 60,
//                       child: Text(
//                         news.title,
//                         style: const TextStyle(
//                           fontSize: 20,
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     Positioned(
//                       left: 16,
//                       bottom: 16,
//                       child: TextButton(
//                         onPressed: () {
//                           // Реализация перехода на детальную страницу
//                         },
//                         child: const Text(
//                           'Подробнее',
//                           style: TextStyle(
//                             color: Colors.white,
//                             decoration: TextDecoration.underline,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           );
//         }
//       },
//     );
//   }
// }

// // Основной экран с переключением вкладок
// class NewsListPage extends StatefulWidget {
//   @override
//   _NewsListPageState createState() => _NewsListPageState();
// }

// class _NewsListPageState extends State<NewsListPage> {
//   int _currentIndex = 0; // Индекс текущей вкладки

//   // Экраны для переключения
//   final List<Widget> _screens = [
//     NewsPage(), // Главная страница
//     MessagesPage(), // Сообщения
//     MyHomePage(), // Мой дом
//     MenuPage(), // Меню
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Новости'),
//       ),
//       body: IndexedStack(
//         index: _currentIndex,
//         children: _screens, // Используем статичные экраны
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentIndex,
//         onTap: (index) {
//           setState(() {
//             _currentIndex = index; // Обновляем текущий индекс
//           });
//         },
//         type: BottomNavigationBarType.fixed,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Главная',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.message),
//             label: 'Сообщения',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home_work),
//             label: 'Мой дом',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.menu),
//             label: 'Меню',
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Заглушки для других экранов
// class MessagesPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Text('Сообщения'),
//     );
//   }
// }

// class MyHomePage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Text('Мой дом'),
//     );
//   }
// }

// class MenuPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Text('Меню'),
//     );
//   }
// }
