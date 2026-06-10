import '../../../core/api/api_client.dart';
import '../models/report_summary.dart';

class ReportService {
  ReportService(this._apiClient);

  final ApiClient _apiClient;

  Future<ReportSummary> summary() async {
    final response = await _apiClient.get('/reports/summary') as Map<String, dynamic>;
    return ReportSummary.fromJson(response);
  }
}
