class RelatedNewsItem {
  final int id;
  final String title;

  RelatedNewsItem({required this.id, required this.title});

  factory RelatedNewsItem.fromJson(Map<String, dynamic> json) {
    return RelatedNewsItem(id: json['id'] ?? 0, title: json['title'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RelatedNewsItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'RelatedNewsItem(id: $id, title: $title)';
}
