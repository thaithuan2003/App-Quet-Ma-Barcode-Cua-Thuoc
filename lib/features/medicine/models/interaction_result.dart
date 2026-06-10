class InteractionResult {
  const InteractionResult({
    required this.severity,
    required this.message,
    required this.details,
  });

  final String severity;
  final String message;
  final List<String> details;

  factory InteractionResult.fromJson(Map<String, dynamic> json) {
    return InteractionResult(
      severity: json['severity'].toString(),
      message: json['message'] as String,
      details: (json['details'] as List<dynamic>).map((item) => item.toString()).toList(),
    );
  }
}
