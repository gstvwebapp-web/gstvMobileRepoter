class UserProfileNewsModel {
  final int id;
  final String title;
  final String url;
  final String categories;
  final int viewer;
  final String createdAt;
  final String date;

  const UserProfileNewsModel({
    required this.id,
    required this.title,
    required this.url,
    required this.categories,
    required this.viewer,
    required this.createdAt,
    required this.date,
  });

  factory UserProfileNewsModel.fromJson(Map<String, dynamic> json) {
    return UserProfileNewsModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      categories: json['categories'] ?? '',
      viewer: json['viewer'] ?? 0,
      createdAt: json['created_at'] ?? '',
      date: json['date'] ?? '',
    );
  }
}
