class SustainabilityRecommendation {
  final String id;
  final String title;
  final String explanation;
  final String sourceType; // "energy", "water", "paperless"
  final String sourceId;
  final String priority; // "low", "medium", "high", "critical"
  final String suggestedAction;
  final String evidenceSummary;
  final bool isAiGenerated;

  const SustainabilityRecommendation({
    required this.id,
    required this.title,
    required this.explanation,
    required this.sourceType,
    required this.sourceId,
    required this.priority,
    required this.suggestedAction,
    required this.evidenceSummary,
    this.isAiGenerated = false,
  });
}
