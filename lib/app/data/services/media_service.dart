import 'dart:convert';
import 'package:gstv_admin/app/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import '../models/media_model.dart';

class MediaService {
  // static const String baseUrl =
  //     'https://staging.gstv.in/backend2/api/v6/mobile/admin';

  Future<MediaListResponse> getMediaList({
    int page = 1,
    String mediaType = '1',
    String? searchQuery,
  }) async {
    try {
      final Map<String, String> requestBody = {
        'page': page.toString(),
        'mediaType': mediaType,
      };
      if (searchQuery != null && searchQuery.isNotEmpty) {
        requestBody['search'] = searchQuery;
      }
      print('HTTP POST request: ${ApiConstants.medialistUrl}');
      print('Request Body: $requestBody');
      final response = await http.post(
        Uri.parse(ApiConstants.medialistUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      print('HTTP POST response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        return MediaListResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load media list: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load media list: $e');
    }
  }



  Future<MediaListResponse> searchMedia({
    int page = 1,
    String mediaType = '1',
    String? searchQuery,
  }) async {
    try {
      final Map<String, String> requestBody = {
        'page': page.toString(),
        'mediaType': mediaType,
      };
      if (searchQuery != null && searchQuery.isNotEmpty) {
        requestBody['search'] = searchQuery;
      }
      print('HTTP POST request: ${ApiConstants.medialistUrl}');
      print('Request Body: $requestBody');
      final response = await http.post(
        Uri.parse(ApiConstants.medialistUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      print('HTTP POST response (${response.statusCode}): ${response.body}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        return MediaListResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to search media: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to search media: $e');
    }
  }

  Future<bool> deleteMedia({required int id}) async {
    try {
      final http.MultipartRequest request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.deletemediaUrl),
      );
      request.fields.addAll({'id': id.toString()});
      print('HTTP POST multipart request: ${ApiConstants.deletemediaUrl}');
      print('Request Fields: ${request.fields}');
      final http.StreamedResponse response = await request.send();
      final responseStr = await response.stream.bytesToString();
      print('HTTP POST response (${response.statusCode}): $responseStr');
      if (response.statusCode == 200) {
        // Optionally parse body to check success key
        return true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('Failed to delete media: $e');
    }
  }
}
