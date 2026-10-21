class NewsSourceModel {
  final int id;
  final int userID;
  final String title;
  final String status;
  final String createdAt;
  final String updatedAt;

  NewsSourceModel({
    required this.id,
    required this.userID,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NewsSourceModel.fromJson(Map<String, dynamic> json) {
    return NewsSourceModel(
      id: json['id'] ?? 0,
      userID: json['userID'] ?? 0,
      title: json['title'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userID': userID,
      'title': title,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
