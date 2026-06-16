import '../../../core/api/api_client.dart';
import '../models/medicine_consultation.dart';

class ConsultationService {
  ConsultationService(this._apiClient);

  final ApiClient _apiClient;

  Future<MedicineConsultation> searchMedicine(String medicineName) async {
    final response = await _apiClient.post('/consultation/medicine', {
      'medicineName': medicineName,
    }) as Map<String, dynamic>;
    return MedicineConsultation.fromJson(response);
  }
}
