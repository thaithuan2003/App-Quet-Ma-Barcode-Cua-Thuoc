class AlertItem {
  const AlertItem({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  final int id;
  final String type;
  final String severity;
  final String title;
  final String message;
  final String createdAt;

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    return AlertItem(
      id: json['id'] as int,
      type: json['type'].toString(),
      severity: json['severity'].toString(),
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt: json['createdAt'] as String,
    );
  }
}
