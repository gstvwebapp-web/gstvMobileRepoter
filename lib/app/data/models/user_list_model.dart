class UserListModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String status;
  final String profileImg;
  final String createdAt;
  final int todayNewsCount;
  final int totalNewsCount;

  const UserListModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.profileImg,
    required this.createdAt,
    required this.todayNewsCount,
    required this.totalNewsCount,
  });

  factory UserListModel.fromJson(Map<String, dynamic> json) {
    return UserListModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      status: json['status'] ?? '',
      profileImg: json['profileImg'] ?? '',
      createdAt: json['created_at'] ?? '',
      todayNewsCount: json['today_news_count'] ?? 0,
      totalNewsCount: json['total_news_count'] ?? 0,
    );
  }
}
