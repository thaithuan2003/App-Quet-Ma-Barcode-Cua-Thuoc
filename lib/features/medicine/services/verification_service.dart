import '../../../core/api/api_client.dart';

class VerificationResult {
  const VerificationResult({
    required this.isVerified,
    required this.severity,
    required this.message,
  });

  final bool isVerified;
  final String severity;
  final String message;

  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    return VerificationResult(
      isVerified: json['isVerified'] as bool,
      severity: json['severity'].toString(),
      message: json['message'] as String,
    );
  }
}

class VerificationService {
  VerificationService(this._apiClient);

  final ApiClient _apiClient;

  Future<VerificationResult> verify(String barcode, String batchNumber) async {
    final response = await _apiClient.post('/verification', {
      'barcode': barcode,
      'batchNumber': batchNumber,
    }) as Map<String, dynamic>;
    return VerificationResult.fromJson(response);
  }
}
