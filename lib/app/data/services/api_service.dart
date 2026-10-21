import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../models/news_model.dart';
import '../../core/constants/constants.dart';
import 'network_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;

  void initialize() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: ApiConstants.defaultHeaders,
      ),
    );

    // Add interceptors for logging and error handling
    // Only enable logging in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
        ),
      );
    }
  }

  Future<bool> hasInternetConnection() async {
    try {
      if (Get.isRegistered<NetworkService>()) {
        return NetworkService.instance.isConnected.value;
      }
      // Fallback to direct connectivity check
      final connectivityResult = await Connectivity().checkConnectivity();
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      print('Error checking internet connection: $e');
      return false;
    }
  }

  Future<UserModel> loginUser({
    required String email,
    required String password,
  }) async {
    if (Get.isRegistered<NetworkService>()) {
      return await NetworkService.instance
          .executeWithConnectivityCheck<UserModel>(
            () => _performLogin(email, password),
          );
    } else {
      return await _performLogin(email, password);
    }
  }

  Future<UserModel> _performLogin(String email, String password) async {
    try {
      if (!await hasInternetConnection()) {
        throw Exception('No internet connection');
      }

      final response = await _dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw Exception('Login failed: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<NewsListResponse> getNewsList({
    String? status,
    String? userID,
    String? startDate,
    String? endDate,
    String catID = '',
    String title = '',
    String? newssource,
    int page = 1,
  }) async {
    try {
      if (!await hasInternetConnection()) {
        throw Exception('No internet connection');
      }

      final response = await _dio.post(
        ApiConstants.newsList,
        data: {
          'status': status,
          'userID': userID,
          'start_date': startDate,
          'end_date': endDate,
          'catID': catID,
          'title': title,
          'newssource': newssource,
          'page': page.toString(),
        },
      );

      if (response.statusCode == 200) {
        return NewsListResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch news: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<String?> translateTitle(String title) async {
    try {
      if (!await hasInternetConnection()) {
        throw Exception('No internet connection');
      }

      final response = await _dio.post(
        ApiConstants.getEnglishNews,
        data: {'title': title},
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        // In case Dio already decodes the JSON body
        final decodedBody = data is String ? jsonDecode(data) : data;
        if (decodedBody['success'] == true &&
            decodedBody['translated'] != null) {
          return decodedBody['translated'];
        } else {
          throw Exception(decodedBody['message'] ?? 'Translation failed');
        }
      } else {
        throw Exception('Failed to translate title: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return Exception('Connection timeout');
      case DioExceptionType.sendTimeout:
        return Exception('Send timeout');
      case DioExceptionType.receiveTimeout:
        return Exception('Receive timeout');
      case DioExceptionType.badResponse:
        final message = error.response?.data?['message'] ?? 'Unknown error';
        return Exception('$message');
      case DioExceptionType.cancel:
        return Exception('Request cancelled');
      case DioExceptionType.connectionError:
        return Exception('No internet connection');
      default:
        return Exception('Network error: ${error.message}');
    }
  }
}
