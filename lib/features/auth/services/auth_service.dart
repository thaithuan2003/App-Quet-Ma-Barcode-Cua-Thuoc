import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/auth_session.dart';

class AuthService {
  AuthService(this._apiClient, this._tokenStorage);

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<AuthSession> login(String username, String password) async {
    final response = await _apiClient.post('/auth/login', {
      'username': username,
      'password': password,
    }) as Map<String, dynamic>;
    final session = AuthSession.fromJson(response);
    await _tokenStorage.saveToken(session.token);
    await _tokenStorage.saveRoles(session.roles);
    return session;
  }

  Future<void> logout() => _tokenStorage.clear();
}
