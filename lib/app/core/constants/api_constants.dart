class ApiConstants {
  // Base URL
  // static const String baseUrl =
  //     'https://staging.gstv.in/backend2/api/v6/mobile/admin';
  static const String mainUrl = 'https://www.gstv.in';
  static const String staging = 'https://staging.gstv.in';
  static const String baseUrl = mainUrl;
  static const String apiSuffix = '/backend2/api/v19/mobile/admin';

  // Authentication Endpoints
  static const String login = '$apiSuffix/login';

  // News Endpoints
  static const String newsList = '$apiSuffix/newslist';
  static const String deleteNews = '$apiSuffix/destroy';
  static const String updateStatus = '$apiSuffix/updateStatus';
  static const String storeNews = '$apiSuffix/storenews';
  static const String updateNews = '$apiSuffix/updatenews';
  static const String editNews = '$apiSuffix/editnews';
  static const String searchRelatedNews = '$apiSuffix/searchRelatedNews';

  // Filter Endpoints
  static const String filterData = '$apiSuffix/addnews';
  static const String addmedia = '$apiSuffix/addmedia';
  static const String medialist = '$apiSuffix/medialist';
  static const String deletemedia = '$apiSuffix/deletemedia';
  static const String newsorder = '$apiSuffix/newsorder';
  static const String usersList = '$apiSuffix/userslist';
  static const String userProfileNewsList = '$apiSuffix/userProfileNewsList';
  static const String forceUpdate = '$apiSuffix/reporterforceupdate';
  static const String getEnglishNews = '$apiSuffix/getenglishnews';

  // Full URLs (for cases where full URL is needed)
  static const String loginUrl = '$baseUrl$login';
  static const String newsListUrl = '$baseUrl$newsList';
  static const String deleteNewsUrl = '$baseUrl$deleteNews';
  static const String updateStatusUrl = '$baseUrl$updateStatus';
  static const String filterDataUrl = '$baseUrl$filterData';
  static const String storeNewsUrl = '$baseUrl$storeNews';
  static const String updateNewsUrl = '$baseUrl$updateNews';
  static const String editNewsUrl = '$baseUrl$editNews';
  static const String searchRelatedNewsUrl = '$baseUrl$searchRelatedNews';
  static const String addmediaUrl = '$baseUrl$addmedia';
  static const String medialistUrl = '$baseUrl$medialist';
  static const String deletemediaUrl = '$baseUrl$deletemedia';
  static const String newsorderUrl = '$baseUrl$newsorder';
  static const String usersListUrl = '$baseUrl$usersList';
  static const String userProfileNewsListUrl = '$baseUrl$userProfileNewsList';
  static const String forceUpdateUrl = '$baseUrl$forceUpdate';
  static const String getEnglishNewsUrl = '$baseUrl$getEnglishNews';

  // Network Configuration
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
