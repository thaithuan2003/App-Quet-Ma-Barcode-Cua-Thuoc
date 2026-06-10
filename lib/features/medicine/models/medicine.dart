class Medicine {
  const Medicine({
    required this.id,
    required this.name,
    required this.barcode,
    required this.activeIngredient,
    required this.manufacturer,
    required this.dosageForm,
    required this.strength,
    required this.usageInstruction,
    required this.warningNote,
    required this.salePrice,
    required this.requiresPrescription,
    required this.totalQuantity,
    required this.nearestExpiryDate,
  });

  final int id;
  final String name;
  final String barcode;
  final String activeIngredient;
  final String manufacturer;
  final String dosageForm;
  final String strength;
  final String usageInstruction;
  final String warningNote;
  final num salePrice;
  final bool requiresPrescription;
  final int totalQuantity;
  final String? nearestExpiryDate;

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] as int,
      name: json['name'] as String,
      barcode: json['barcode'] as String,
      activeIngredient: json['activeIngredient'] as String,
      manufacturer: json['manufacturer'] as String,
      dosageForm: json['dosageForm'] as String,
      strength: json['strength'] as String,
      usageInstruction: json['usageInstruction'] as String,
      warningNote: json['warningNote'] as String,
      salePrice: json['salePrice'] as num,
      requiresPrescription: json['requiresPrescription'] as bool,
      totalQuantity: json['totalQuantity'] as int,
      nearestExpiryDate: json['nearestExpiryDate'] as String?,
    );
  }
}
