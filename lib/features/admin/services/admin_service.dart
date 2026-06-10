import '../../../core/api/api_client.dart';
import '../models/admin_user.dart';

class AdminService {
  AdminService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<AdminUser>> users() async {
    final response = await _apiClient.get('/admin/users') as List<dynamic>;
    return response.map((item) => AdminUser.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> createStaff({
    required String fullName,
    required String username,
    required String password,
  }) async {
    await _apiClient.post('/admin/staff', {
      'fullName': fullName,
      'username': username,
      'password': password,
    });
  }

  Future<void> updateStaff({
    required int userId,
    required String fullName,
    required String username,
    String? password,
  }) async {
    await _apiClient.put('/admin/staff/$userId', {
      'fullName': fullName,
      'username': username,
      'password': password,
    });
  }

  Future<void> deleteStaff(int userId) async {
    await _apiClient.delete('/admin/staff/$userId');
  }

  Future<void> updateUserStatus(int userId, bool isActive) async {
    await _apiClient.patch('/admin/users/$userId/status', {'isActive': isActive});
  }

}
