import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _apiService.loginUser(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }
}
