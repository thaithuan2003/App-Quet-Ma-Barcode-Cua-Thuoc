class MedicineConsultation {
  const MedicineConsultation({
    required this.medicineName,
    required this.summary,
    required this.sourceTitle,
    required this.sourceUrl,
    required this.sourceSnippet,
  });

  final String medicineName;
  final String summary;
  final String sourceTitle;
  final String sourceUrl;
  final String sourceSnippet;

  factory MedicineConsultation.fromJson(Map<String, dynamic> json) {
    return MedicineConsultation(
      medicineName: json['medicineName'] as String,
      summary: json['summary'] as String,
      sourceTitle: json['sourceTitle'] as String,
      sourceUrl: json['sourceUrl'] as String,
      sourceSnippet: json['sourceSnippet'] as String,
    );
  }
}
