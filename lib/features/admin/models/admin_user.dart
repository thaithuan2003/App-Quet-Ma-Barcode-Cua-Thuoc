class AdminUser {
  const AdminUser({
    required this.id,
    required this.fullName,
    required this.username,
    required this.isActive,
    required this.roles,
  });

  final int id;
  final String fullName;
  final String username;
  final bool isActive;
  final List<String> roles;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as int,
      fullName: json['fullName'] as String,
      username: json['username'] as String,
      isActive: json['isActive'] as bool,
      roles: (json['roles'] as List<dynamic>).map((item) => item.toString()).toList(),
    );
  }
}
