class ReportScan {
  const ReportScan({
    required this.id,
    required this.barcode,
    required this.found,
    required this.medicineName,
    required this.createdAt,
  });

  final int id;
  final String barcode;
  final bool found;
  final String? medicineName;
  final String createdAt;

  factory ReportScan.fromJson(Map<String, dynamic> json) {
    return ReportScan(
      id: json['id'] as int,
      barcode: json['barcode'] as String,
      found: json['found'] as bool,
      medicineName: json['medicineName'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }
}
