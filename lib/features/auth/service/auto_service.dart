import 'package:jasa_cepat/core/api_client.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  // Fungsi mengirim data pendaftaran ke server
  Future<bool> registerUser({
    required String nama,
    required String email,
    required String nomorHp,
  }) async {
    try {
      final response = await _apiClient.postRequest('/auth/register', {
        'name': nama,
        'email': email,
        'phone_number': nomorHp,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }
}