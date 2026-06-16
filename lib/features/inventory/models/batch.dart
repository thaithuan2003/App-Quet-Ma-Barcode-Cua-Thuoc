class Batch {
  const Batch({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.batchNumber,
    required this.manufactureDate,
    required this.expiryDate,
    required this.quantity,
    required this.lowStockThreshold,
    required this.supplierId,
    required this.supplierName,
  });

  final int id;
  final int medicineId;
  final String medicineName;
  final String batchNumber;
  final String manufactureDate;
  final String expiryDate;
  final int quantity;
  final int lowStockThreshold;
  final int? supplierId;
  final String? supplierName;

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: json['id'] as int,
      medicineId: json['medicineId'] as int,
      medicineName: json['medicineName'] as String,
      batchNumber: json['batchNumber'] as String,
      manufactureDate: json['manufactureDate'] as String,
      expiryDate: json['expiryDate'] as String,
      quantity: json['quantity'] as int,
      lowStockThreshold: json['lowStockThreshold'] as int,
      supplierId: json['supplierId'] as int?,
      supplierName: json['supplierName'] as String?,
    );
  }
}
