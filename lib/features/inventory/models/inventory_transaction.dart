class InventoryTransaction {
  const InventoryTransaction({
    required this.id,
    required this.medicineName,
    required this.batchNumber,
    required this.type,
    required this.quantity,
    required this.note,
    required this.createdAt,
  });

  final int id;
  final String medicineName;
  final String batchNumber;
  final String type;
  final int quantity;
  final String note;
  final String createdAt;

  factory InventoryTransaction.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'];
    return InventoryTransaction(
      id: json['id'] as int,
      medicineName: json['medicineName'] as String,
      batchNumber: json['batchNumber'] as String,
      type: _parseType(rawType),
      quantity: json['quantity'] as int,
      note: json['note'] as String,
      createdAt: json['createdAt'] as String,
    );
  }

  static String _parseType(Object? value) {
    return switch (value) {
      0 => 'Import',
      1 => 'Export',
      2 => 'Sale',
      3 => 'Adjustment',
      _ => value?.toString() ?? '',
    };
  }
}
