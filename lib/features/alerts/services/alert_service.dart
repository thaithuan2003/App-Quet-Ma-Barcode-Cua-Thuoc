import '../../../core/api/api_client.dart';
import '../models/alert_item.dart';

class AlertService {
  AlertService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<AlertItem>> alerts() async {
    final response = await _apiClient.get('/alerts') as List<dynamic>;
    return response.map((item) => AlertItem.fromJson(item as Map<String, dynamic>)).toList();
  }
}
