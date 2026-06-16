class Supplier {
  const Supplier({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
  });

  final int id;
  final String name;
  final String phone;
  final String address;

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
    );
  }
}
