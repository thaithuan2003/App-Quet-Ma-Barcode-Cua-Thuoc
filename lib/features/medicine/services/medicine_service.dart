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

  Future<void> createMedicine({
    required String name,
    required String barcode,
    required String activeIngredient,
    required String manufacturer,
    required String dosageForm,
    required String strength,
    required String usageInstruction,
    required String warningNote,
    required num salePrice,
    required bool requiresPrescription,
  }) async {
    await _apiClient.post('/medicines', {
      'name': name,
      'barcode': barcode,
      'activeIngredient': activeIngredient,
      'manufacturer': manufacturer,
      'dosageForm': dosageForm,
      'strength': strength,
      'usageInstruction': usageInstruction,
      'warningNote': warningNote,
      'salePrice': salePrice,
      'requiresPrescription': requiresPrescription,
    });
  }

  Future<void> updateMedicine({
    required int id,
    required String name,
    required String barcode,
    required String activeIngredient,
    required String manufacturer,
    required String dosageForm,
    required String strength,
    required String usageInstruction,
    required String warningNote,
    required num salePrice,
    required bool requiresPrescription,
  }) async {
    await _apiClient.put('/medicines/$id', {
      'name': name,
      'barcode': barcode,
      'activeIngredient': activeIngredient,
      'manufacturer': manufacturer,
      'dosageForm': dosageForm,
      'strength': strength,
      'usageInstruction': usageInstruction,
      'warningNote': warningNote,
      'salePrice': salePrice,
      'requiresPrescription': requiresPrescription,
    });
  }

  Future<void> deleteMedicine(int id) async {
    await _apiClient.delete('/medicines/$id');
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
