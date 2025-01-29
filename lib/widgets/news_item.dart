import 'package:flutter/material.dart';
import '../models/news_model.dart';
import '../pages/news_detail_page.dart';

class NewsItem extends StatelessWidget {
  final News news;

  const NewsItem({Key? key, required this.news}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewsDetailPage(newsId: news.id),
          ),
        );
      },
      
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30, top: 20, right: 20, left: 20),
        child: Stack(
          children: [
            Container(
              child: Text("Новости"),
            ),
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(
                    'https://sabahome.kz${news.coverImage}',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withOpacity(0.5), // Тёмный слой
              ),
            ),
            
            Positioned(
              left: 16,
              bottom: 70,
              child: Container(
                width: 280,
                child: Text(
                  news.title,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontFamily: 'InstrumentSans',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 30,
              child: Text(
                'Подробнее',
                style: const TextStyle(
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            
          ],
          
        ),
      ),
      
    );
    
  }
}
