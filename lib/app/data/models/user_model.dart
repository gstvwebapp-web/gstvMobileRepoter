class UserModel {
  final int userID;
  final String name;
  final String email;
  final String? profileImg;
  final String createdAt;
  final String status;
  final String? catID;
  final String? moduleID;
  final String? roleID;

  const UserModel({
    required this.userID,
    required this.name,
    required this.email,
    this.profileImg,
    required this.createdAt,
    required this.status,
    this.catID,
    this.moduleID,
    this.roleID,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userID: json['id'] ?? json['userID'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profileImg: json['profileImg'],
      createdAt: json['created_at'] ?? '',
      status: json['status'] ?? '',
      catID: json['catID'],
      moduleID: json['moduleID'],
      roleID: json['roleID'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userID': userID,
      'name': name,
      'email': email,
      'profileImg': profileImg,
      'created_at': createdAt,
      'status': status,
      'catID': catID,
      'moduleID': moduleID,
      'roleID': roleID,
    };
  }
}
