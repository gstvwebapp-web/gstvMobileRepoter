import 'package:dio/dio.dart';
import '../models/filter_data_model.dart';
import '../../core/constants/constants.dart';

class FilterService {
  final Dio _dio = Dio()
    ..interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ),
    );

  Future<FilterDataModel> getFilterData() async {
    try {
      final response = await _dio.get(
        ApiConstants.filterDataUrl,
        options: Options(headers: ApiConstants.defaultHeaders),
      );

      if (response.statusCode == 200) {
        return FilterDataModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load filter data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching filter data: $e');
    }
  }
}
