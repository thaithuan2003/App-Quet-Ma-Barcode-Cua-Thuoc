import '../../../core/api/api_client.dart';
import '../models/scan_result.dart';

class ScanService {
  ScanService(this._apiClient);

  final ApiClient _apiClient;

  Future<ScanResult> scan(String barcode) async {
    final response = await _apiClient.post('/scans', {'barcode': barcode}) as Map<String, dynamic>;
    return ScanResult.fromJson(response);
  }

  Future<List<ScanResult>> multiScan(List<String> barcodes) async {
    final response = await _apiClient.post('/scans/multi', {'barcodes': barcodes}) as List<dynamic>;
    return response.map((item) => ScanResult.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<ScanResult>> history() async {
    final response = await _apiClient.get('/scans/history') as List<dynamic>;
    return response.map((item) => ScanResult.fromJson(item as Map<String, dynamic>)).toList();
  }
}
