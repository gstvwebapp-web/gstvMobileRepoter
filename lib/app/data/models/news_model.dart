class NewsModel {
  final int id;
  final String title;
  final String slug;
  final int? viewer;
  final int viewerApp;
  final String authorName;
  final String categories;
  final String categorySlugs;
  final String createdAt;
  final String status;
  final int isBreaking;
  final int isLiveNews;
  final int isHome;
  final int topnewsOrder;
  final String? newssource;

  const NewsModel({
    required this.id,
    required this.title,
    required this.slug,
    this.viewer,
    required this.viewerApp,
    required this.authorName,
    required this.categories,
    required this.categorySlugs,
    required this.createdAt,
    required this.status,
    required this.isBreaking,
    required this.isLiveNews,
    required this.isHome,
    required this.topnewsOrder,
    this.newssource,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      viewer: json['viewer'] ?? 0,
      viewerApp: json['viewer_app'] ?? 0,
      authorName: json['authorName'] ?? '',
      categories: json['categories'] ?? '',
      categorySlugs: json['categorySlugs'] ?? '',
      createdAt: json['created_at'] ?? '',
      status: json['status'] ?? '',
      isBreaking: json['is_breaking'] ?? 0,
      isLiveNews: json['is_live_news'] ?? 0,
      isHome: json['is_home'] ?? 0,
      topnewsOrder: json['topnewsOrder'] ?? 0,
      newssource: json['newssource']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'viewer': viewer,
      'viewer_app': viewerApp,
      'authorName': authorName,
      'categories': categories,
      'categorySlugs': categorySlugs,
      'created_at': createdAt,
      'status': status,
      'is_breaking': isBreaking,
      'is_live_news': isLiveNews,
      'is_home': isHome,
      'topnewsOrder': topnewsOrder,
      'newssource': newssource,
    };
  }
}

class NewsListResponse {
  final List<NewsModel> newslist;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const NewsListResponse({
    required this.newslist,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory NewsListResponse.fromJson(Map<String, dynamic> json) {
    return NewsListResponse(
      newslist: (json['newslist'] as List)
          .map((item) => NewsModel.fromJson(item))
          .toList(),
      currentPage: json['current_page'] ?? 0,
      lastPage: json['last_page'] ?? 0,
      perPage: json['per_page'] ?? 0,
      total: json['total'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'newslist': newslist.map((news) => news.toJson()).toList(),
      'current_page': currentPage,
      'last_page': lastPage,
      'per_page': perPage,
      'total': total,
    };
  }
}
