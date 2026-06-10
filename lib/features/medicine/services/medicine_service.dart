import '../../../core/api/api_client.dart';
import '../models/interaction_result.dart';
import '../models/medicine.dart';

class MedicineService {
  MedicineService(this._apiClient);

  final ApiClient _apiClient;

  Future<Medicine> getByBarcode(String barcode) async {
    final response = await _apiClient.get('/medicines/barcode/$barcode') as Map<String, dynamic>;
    return Medicine.fromJson(response);
  }

  Future<List<Medicine>> search(String query) async {
    final response = await _apiClient.get('/medicines/search', query: {'q': query}) as List<dynamic>;
    return response.map((item) => Medicine.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<Medicine>> similar(int medicineId) async {
    final response = await _apiClient.get('/medicines/$medicineId/similar') as List<dynamic>;
    return response.map((item) => Medicine.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<InteractionResult> checkInteractions(List<String> barcodes) async {
    final response = await _apiClient.post('/medicines/interactions', {'barcodes': barcodes}) as Map<String, dynamic>;
    return InteractionResult.fromJson(response);
  }
}
