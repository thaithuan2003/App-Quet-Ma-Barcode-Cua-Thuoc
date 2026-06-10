import '../../medicine/models/medicine.dart';

class ScanResult {
  const ScanResult({
    required this.found,
    required this.message,
    required this.medicine,
  });

  final bool found;
  final String message;
  final Medicine? medicine;

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      found: json['found'] as bool,
      message: json['message'] as String,
      medicine: json['medicine'] == null ? null : Medicine.fromJson(json['medicine'] as Map<String, dynamic>),
    );
  }
}
