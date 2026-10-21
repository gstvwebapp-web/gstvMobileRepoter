import '../models/news_model.dart';
import '../services/api_service.dart';

class NewsRepository {
  final ApiService _apiService = ApiService();

  Future<NewsListResponse> getNewsList({
    String? status,
    String? userID,
    String? startDate,
    String? endDate,
    String? catID,
    String? title,
    String? newssource,
    int page = 1,
  }) async {
    try {
      return await _apiService.getNewsList(
        status: status ?? '',
        userID: userID ?? '',
        startDate: startDate ?? '',
        endDate: endDate ?? '',
        catID: catID ?? '',
        title: title ?? '',
        newssource: newssource ?? '',
        page: page,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> translateTitle(String title) async {
    try {
      return await _apiService.translateTitle(title);
    } catch (e) {
      rethrow;
    }
  }
}
