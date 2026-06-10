import '../../../core/api/api_client.dart';
import '../../inventory/models/batch.dart';
import '../../medicine/models/medicine.dart';
import '../models/report_scan.dart';
import '../models/report_summary.dart';

class ReportService {
  ReportService(this._apiClient);

  final ApiClient _apiClient;

  Future<ReportSummary> summary() async {
    final response = await _apiClient.get('/reports/summary') as Map<String, dynamic>;
    return ReportSummary.fromJson(response);
  }

  Future<List<Medicine>> medicines() async {
    final response = await _apiClient.get('/reports/medicines') as List<dynamic>;
    return response.map((item) => Medicine.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<Batch>> batches() async {
    final response = await _apiClient.get('/reports/batches') as List<dynamic>;
    return response.map((item) => Batch.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<Batch>> nearExpiryBatches() async {
    final response = await _apiClient.get('/reports/near-expiry-batches') as List<dynamic>;
    return response.map((item) => Batch.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<Batch>> expiredBatches() async {
    final response = await _apiClient.get('/reports/expired-batches') as List<dynamic>;
    return response.map((item) => Batch.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<ReportScan>> todayScans() async {
    final response = await _apiClient.get('/reports/today-scans') as List<dynamic>;
    return response.map((item) => ReportScan.fromJson(item as Map<String, dynamic>)).toList();
  }
}
