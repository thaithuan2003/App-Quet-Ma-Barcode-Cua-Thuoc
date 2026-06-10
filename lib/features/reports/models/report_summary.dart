class ReportSummary {
  const ReportSummary({
    required this.medicineCount,
    required this.batchCount,
    required this.totalInventoryQuantity,
    required this.lowStockCount,
    required this.expiredBatchCount,
    required this.nearExpiryBatchCount,
    required this.todayScanCount,
    required this.todaySaleQuantity,
  });

  final int medicineCount;
  final int batchCount;
  final int totalInventoryQuantity;
  final int lowStockCount;
  final int expiredBatchCount;
  final int nearExpiryBatchCount;
  final int todayScanCount;
  final int todaySaleQuantity;

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      medicineCount: json['medicineCount'] as int,
      batchCount: json['batchCount'] as int,
      totalInventoryQuantity: json['totalInventoryQuantity'] as int,
      lowStockCount: json['lowStockCount'] as int,
      expiredBatchCount: json['expiredBatchCount'] as int,
      nearExpiryBatchCount: json['nearExpiryBatchCount'] as int,
      todayScanCount: json['todayScanCount'] as int,
      todaySaleQuantity: json['todaySaleQuantity'] as int,
    );
  }
}
