import '../../../core/api/api_client.dart';
import '../models/supplier.dart';

class SupplierService {
  SupplierService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Supplier>> suppliers() async {
    final response = await _apiClient.get('/suppliers') as List<dynamic>;
    return response.map((item) => Supplier.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> createSupplier({
    required String name,
    required String phone,
    required String address,
  }) async {
    await _apiClient.post('/suppliers', {
      'name': name,
      'phone': phone,
      'address': address,
    });
  }

  Future<void> updateSupplier({
    required int id,
    required String name,
    required String phone,
    required String address,
  }) async {
    await _apiClient.put('/suppliers/$id', {
      'name': name,
      'phone': phone,
      'address': address,
    });
  }

  Future<void> deleteSupplier(int id) async {
    await _apiClient.delete('/suppliers/$id');
  }
}
