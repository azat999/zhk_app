class News {
  final int id;
  final String title;
  final String coverImage;

  News({required this.id, required this.title, required this.coverImage});

  // Метод для преобразования JSON в объект News
  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'],
      title: json['title'],
      coverImage: json['cover_image'],
    );
  }
}
