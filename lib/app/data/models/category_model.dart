class CategoryModel {
  final int id;
  final String title;
  final int parentID;
  final int? childId;
  final String? childName;

  CategoryModel({
    required this.id,
    required this.title,
    required this.parentID,
    this.childId,
    this.childName,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      parentID: json['parentID'] ?? 0,
      childId: json['child_id'],
      childName: json['child_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'parentID': parentID,
      'child_id': childId,
      'child_name': childName,
    };
  }
}
