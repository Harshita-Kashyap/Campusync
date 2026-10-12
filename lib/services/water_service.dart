import '../models/models.dart';
import 'app_repository.dart';

const waterIssueTypes = ['leaking_tap', 'overflow', 'pipe_leak', 'other'];
const waterSeverities = ['low', 'medium', 'high', 'critical'];

String labelOf(String v) => v.replaceAll('_', ' ');

/// Normalized result of a photo analysis. Only source == 'ai' may be presented as AI.
class LeakAnalysisResult {
  final String issueType, severity, description, source;
  final double estimatedLitresPerHour;

  const LeakAnalysisResult({
    required this.issueType,
    required this.severity,
    required this.estimatedLitresPerHour,
    required this.description,
    required this.source,
  });

  bool get isAi => source == 'ai';

  String get label => switch (source) {
        'ai' => 'AI-generated estimate, please confirm',
        'fallback' => 'Fallback estimate, please confirm',
        'sample' => 'Saved sample estimate (not live AI), please confirm',
        'manual' => 'Manually entered estimate',
        _ => 'Estimate from an unverified source, please confirm',
      };

  /// Tolerant parser for Gemini output and the API's normalized response.
  factory LeakAnalysisResult.fromJson(Map<String, dynamic> json) {
    var litresPerHour = (json['estimatedLitresPerHour'] as num?)?.toDouble() ?? 0;
    if (!litresPerHour.isFinite || litresPerHour < 0) litresPerHour = 0;

    var severity = (json['severity'] ?? '').toString().toLowerCase().trim();
    if (!waterSeverities.contains(severity)) severity = WaterService.suggestSeverity(litresPerHour);

    final rawType = (json['issueType'] ?? '').toString().toLowerCase().trim();
    var issueType = 'other';
    if (waterIssueTypes.contains(rawType)) {
      issueType = rawType;
    } else if (rawType.contains('tap') || rawType.contains('drip') || rawType.contains('faucet')) {
      issueType = 'leaking_tap';
    } else if (rawType.contains('overflow')) {
      issueType = 'overflow';
    } else if (rawType.contains('pipe') || rawType.contains('coupling') || rawType.contains('joint') || rawType.contains('spray')) {
      issueType = 'pipe_leak';
    }

    final rawDescription = (json['description'] ?? '').toString().trim();
    final rawSource = (json['source'] ?? '').toString().toLowerCase().trim();
    final source = const {'ai', 'fallback', 'sample', 'manual'}.contains(rawSource) ? rawSource : 'unknown';
    return LeakAnalysisResult(
      issueType: issueType,
      severity: severity,
      estimatedLitresPerHour: litresPerHour,
      description: rawDescription.isEmpty && rawType.isNotEmpty ? json['issueType'].toString() : rawDescription,
      source: source,
    );
  }
}

abstract class LeakAnalyzer {
  Future<LeakAnalysisResult> analyze();
}

/// Offline demo path: saved result for the bundled sample photo. No network needed.
class FixtureLeakAnalyzer implements LeakAnalyzer {
  static const assetPath = 'assets/images/sample_leak.png';
  const FixtureLeakAnalyzer();

  @override
  Future<LeakAnalysisResult> analyze() async => const LeakAnalysisResult(
        issueType: 'pipe_leak',
        severity: 'critical',
        estimatedLitresPerHour: 1500,
        description: 'High-pressure water spraying in several jets from a damaged pipe coupling.',
        source: 'sample',
      );
}

class AnalysisOutcome {
  final LeakAnalysisResult result;
  final String? notice;
  const AnalysisOutcome(this.result, [this.notice]);
}

/// Water logic and validation. Remote operations are handled by WaterApiClient.
class WaterService {
  final AppRepository repo;
  const WaterService(this.repo);

  /// Typical rates used only to suggest a value; they are assumptions, not measurements.
  static const defaultRates = {
    'leaking_tap': 5.0,
    'overflow': 120.0,
    'pipe_leak': 300.0,
    'other': 10.0,
  };
  static double defaultRateFor(String type) => defaultRates[type] ?? 10.0;

  static String suggestSeverity(double litresPerHour) =>
      litresPerHour < 10 ? 'low' : (litresPerHour < 100 ? 'medium' : (litresPerHour < 500 ? 'high' : 'critical'));

  static String? validateRequired(String? value, String what) =>
      (value == null || value.trim().isEmpty) ? '$what is required' : null;

  static String? validateDescription(String? value) {
    final requiredError = validateRequired(value, 'Description');
    if (requiredError != null) return requiredError;
    return value!.trim().length > 200 ? 'Keep it under 200 characters' : null;
  }

  static String? validateRate(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final number = double.tryParse(value.trim());
    if (number == null || !number.isFinite) return 'Enter a number';
    if (number < 0) return 'Cannot be negative';
    if (number == 0) return 'Enter a positive rate for a leak';
    return null;
  }

  static String? validateDuration(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final number = double.tryParse(value.trim());
    if (number == null || !number.isFinite) return 'Enter a number';
    if (number < 0) return 'Cannot be negative';
    if (number > 8760) return 'Max 8760 hours (1 year)';
    return null;
  }

  List<WaterIncident> getIncidents() => repo.getIncidents();
  Future<void> addIncident(WaterIncident incident) => repo.addIncident(incident);
  Future<void> updateIncidentStatus(String id, String status) => repo.updateIncidentStatus(id, status);

  /// Current estimated loss: open + in-progress incidents only.
  double getEstimatedWaterLossLitres() => repo
      .getIncidents()
      .where((incident) => incident.status == 'open' || incident.status == 'in_progress')
      .fold(0.0, (sum, incident) => sum + incident.estimatedLitresLost);

  /// Create a local/demo incident. The caller should use WaterApiClient for MySQL persistence.
  Future<WaterIncident> submitReport({
    required String location,
    required String issueType,
    required String severity,
    required double litresPerHour,
    required double durationHours,
    required String description,
    String source = 'manual',
    String? imageUrl,
  }) async {
    if (location.trim().isEmpty || description.trim().isEmpty) {
      throw ArgumentError('Location and description are required');
    }
    if (!waterIssueTypes.contains(issueType)) throw ArgumentError('Invalid issue type: $issueType');
    if (!waterSeverities.contains(severity)) throw ArgumentError('Invalid severity: $severity');
    if (!litresPerHour.isFinite || litresPerHour <= 0) throw ArgumentError('Litres per hour must be positive');
    if (!durationHours.isFinite || durationHours < 0) throw ArgumentError('Duration cannot be negative');
    final now = DateTime.now();
    final incident = WaterIncident(
      id: 'WA-${now.microsecondsSinceEpoch}',
      locationName: location.trim(),
      issueType: issueType,
      estimatedLitresPerHour: litresPerHour,
      reportedAt: now,
      estimatedDurationHours: durationHours,
      severity: severity,
      description: description.trim(),
      status: 'open',
      source: source,
      imageUrl: imageUrl,
    );
    await repo.addIncident(incident);
    return incident;
  }

  /// Utility for any optional analyzer used by offline/demo flows.
  static Future<AnalysisOutcome> analyze(LeakAnalyzer analyzer) async {
    try {
      return AnalysisOutcome(await analyzer.analyze());
    } catch (_) {
      final result = await const FixtureLeakAnalyzer().analyze();
      return AnalysisOutcome(result, 'Could not reach the analysis service; a saved sample result was used instead.');
    }
  }
}
