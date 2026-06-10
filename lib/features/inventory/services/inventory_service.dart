import '../../../core/api/api_client.dart';
import '../models/batch.dart';
import '../models/inventory_transaction.dart';

class InventoryService {
  InventoryService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Batch>> batches() async {
    final response = await _apiClient.get('/inventory/batches') as List<dynamic>;
    return response.map((item) => Batch.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> createBatch({
    required int medicineId,
    int? supplierId,
    required String batchNumber,
    required String manufactureDate,
    required String expiryDate,
    required int quantity,
    required int lowStockThreshold,
  }) async {
    await _apiClient.post('/inventory/batches', {
      'medicineId': medicineId,
      'supplierId': supplierId,
      'batchNumber': batchNumber,
      'manufactureDate': manufactureDate,
      'expiryDate': expiryDate,
      'quantity': quantity,
      'lowStockThreshold': lowStockThreshold,
    });
  }

  Future<void> importStock(int batchId, int quantity, String note) async {
    await _apiClient.post('/inventory/import', {
      'medicineBatchId': batchId,
      'quantity': quantity,
      'note': note,
    });
  }

  Future<void> exportStock(int batchId, int quantity, String note) async {
    await _apiClient.post('/inventory/export', {
      'medicineBatchId': batchId,
      'quantity': quantity,
      'note': note,
    });
  }

  Future<void> adjustStock(int batchId, int newQuantity, String note) async {
    await _apiClient.post('/inventory/adjust', {
      'medicineBatchId': batchId,
      'newQuantity': newQuantity,
      'note': note,
    });
  }

  Future<List<InventoryTransaction>> transactions() async {
    final response = await _apiClient.get('/inventory/transactions') as List<dynamic>;
    return response.map((item) => InventoryTransaction.fromJson(item as Map<String, dynamic>)).toList();
  }
}
