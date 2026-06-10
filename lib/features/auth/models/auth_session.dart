class AuthSession {
  const AuthSession({
    required this.token,
    required this.fullName,
    required this.username,
    required this.roles,
  });

  final String token;
  final String fullName;
  final String username;
  final List<String> roles;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'] as String,
      fullName: json['fullName'] as String,
      username: json['username'] as String,
      roles: (json['roles'] as List<dynamic>).map((item) => item.toString()).toList(),
    );
  }
}
