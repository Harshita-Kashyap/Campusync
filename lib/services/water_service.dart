import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import '../models/models.dart';
import 'app_repository.dart';

const waterIssueTypes = ['leaking_tap', 'overflow', 'pipe_leak', 'other'];
const waterSeverities = ['low', 'medium', 'high', 'critical'];

String labelOf(String v) => v.replaceAll('_', ' ');

/// Normalised result of a photo analysis. [source]: ai | fallback | sample | unknown.
/// Only source == 'ai' may ever be presented as AI.
class LeakAnalysisResult {
  final String issueType, severity, description, source;
  final double estimatedLitresPerHour;
  const LeakAnalysisResult({
    required this.issueType, required this.severity, required this.estimatedLitresPerHour,
    required this.description, required this.source,
  });

  bool get isAi => source == 'ai';

  String get label => isAi
      ? 'AI-generated estimate, please confirm'
      : (source == 'unknown'
          ? 'Estimate from an unverified source, please confirm'
          : 'Sample estimate (not live AI), please confirm');

  /// Tolerant parser: also copes with the un-fixed script output
  /// ("Critical", free-text issue type).
  factory LeakAnalysisResult.fromJson(Map<String, dynamic> j) {
    var lph = (j['estimatedLitresPerHour'] as num?)?.toDouble() ?? 0.0;
    if (!lph.isFinite || lph < 0) lph = 0;
    var sev = (j['severity'] ?? '').toString().toLowerCase().trim();
    if (!waterSeverities.contains(sev)) sev = WaterService.suggestSeverity(lph);
    final rawType = (j['issueType'] ?? '').toString().toLowerCase().trim();
    final desc = (j['description'] ?? '').toString().trim();
    var type = 'other';
    if (waterIssueTypes.contains(rawType)) {
      type = rawType;
    } else if (rawType.contains('tap') || rawType.contains('drip')) {
      type = 'leaking_tap';
    } else if (rawType.contains('overflow')) {
      type = 'overflow';
    } else if (rawType.contains('pipe') || rawType.contains('coupling') || rawType.contains('joint')) {
      type = 'pipe_leak';
    }
    final src = (j['source'] ?? '').toString().toLowerCase().trim();
    return LeakAnalysisResult(
      issueType: type, severity: sev, estimatedLitresPerHour: lph,
      description: desc.isEmpty && rawType.isNotEmpty ? j['issueType'].toString() : desc,
      source: const {'ai', 'fallback', 'sample'}.contains(src) ? src : 'unknown',
    );
  }
}

abstract class LeakAnalyzer {
  Future<LeakAnalysisResult> analyze();
}

/// Offline demo path: saved result for the bundled sample photo. Needs no network or packages.
class FixtureLeakAnalyzer implements LeakAnalyzer {
  static const assetPath = 'assets/images/sample_leak.png';
  const FixtureLeakAnalyzer();
  @override
  Future<LeakAnalysisResult> analyze() async => const LeakAnalysisResult(
        issueType: 'pipe_leak', severity: 'critical', estimatedLitresPerHour: 1500,
        description: 'High-pressure water spraying in several jets from a damaged pipe coupling.',
        source: 'sample',
      );
}

/// Online path: posts the bundled sample photo to Person 3's server (POST {baseUrl}/analyze,
/// multipart field "image"). Uses dart:io only — no extra packages (not available on Flutter web).
class HttpLeakAnalyzer implements LeakAnalyzer {
  final String baseUrl;
  final Duration timeout;
  const HttpLeakAnalyzer(this.baseUrl, {this.timeout = const Duration(seconds: 8)});

  @override
  Future<LeakAnalysisResult> analyze() async {
    final bytes = (await rootBundle.load(FixtureLeakAnalyzer.assetPath)).buffer.asUint8List();
    final boundary = '----campusync${DateTime.now().microsecondsSinceEpoch}';
    final head = utf8.encode('--$boundary\r\nContent-Disposition: form-data; name="image"; '
        'filename="sample_leak.png"\r\nContent-Type: image/png\r\n\r\n');
    final tail = utf8.encode('\r\n--$boundary--\r\n');
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final req = await client.postUrl(Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}/analyze')).timeout(timeout);
      req.headers.set(HttpHeaders.contentTypeHeader, 'multipart/form-data; boundary=$boundary');
      req.contentLength = head.length + bytes.length + tail.length;
      req.add(head);
      req.add(bytes);
      req.add(tail);
      final res = await req.close().timeout(timeout);
      final body = await res.transform(utf8.decoder).join().timeout(timeout);
      if (res.statusCode != 200) throw HttpException('Server returned ${res.statusCode}');
      dynamic decoded = jsonDecode(body);
      if (decoded is String) decoded = jsonDecode(decoded);
      return LeakAnalysisResult.fromJson(Map<String, dynamic>.from(decoded as Map));
    } finally {
      client.close(force: true);
    }
  }
}

class AnalysisOutcome {
  final LeakAnalysisResult result;
  final String? notice; // set when we fell back
  const AnalysisOutcome(this.result, [this.notice]);
}

/// Water logic + contract methods. UI never computes; it calls this.
class WaterService {
  final AppRepository repo;
  const WaterService(this.repo);

  /// Typical rates used only to SUGGEST a value (assumption, always editable).
  static const defaultRates = {'leaking_tap': 5.0, 'overflow': 120.0, 'pipe_leak': 300.0, 'other': 10.0};
  static double defaultRateFor(String type) => defaultRates[type] ?? 10.0;

  static String suggestSeverity(double lph) =>
      lph < 10 ? 'low' : (lph < 100 ? 'medium' : (lph < 500 ? 'high' : 'critical'));

  // ---- validators (return error text or null) ----
  static String? validateRequired(String? v, String what) =>
      (v == null || v.trim().isEmpty) ? '$what is required' : null;

  static String? validateDescription(String? v) {
    final r = validateRequired(v, 'Description');
    if (r != null) return r;
    return v!.trim().length > 200 ? 'Keep it under 200 characters' : null;
  }

  static String? validateRate(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = double.tryParse(v.trim());
    if (n == null || !n.isFinite) return 'Enter a number';
    if (n < 0) return 'Cannot be negative';
    if (n == 0) return 'Enter a positive rate for a leak';
    return null;
  }

  static String? validateDuration(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = double.tryParse(v.trim());
    if (n == null || !n.isFinite) return 'Enter a number';
    if (n < 0) return 'Cannot be negative';
    if (n > 8760) return 'Max 8760 hours (1 year)';
    return null;
  }

  // ---- contract methods ----
  List<WaterIncident> getIncidents() => repo.getIncidents();
  Future<void> addIncident(WaterIncident i) => repo.addIncident(i);
  Future<void> updateIncidentStatus(String id, String status) => repo.updateIncidentStatus(id, status);

  /// CURRENT estimated loss: open + in_progress only (matches dashboard definition).
  double getEstimatedWaterLossLitres() => repo
      .getIncidents()
      .where((i) => i.status == 'open' || i.status == 'in_progress')
      .fold(0.0, (s, i) => s + i.estimatedLitresLost);

  /// Validates again (defence in depth), builds a stable-ID incident and stores it.
  Future<WaterIncident> submitReport({
    required String location, required String issueType, required String severity,
    required double litresPerHour, required double durationHours, required String description,
  }) async {
    if (location.trim().isEmpty || description.trim().isEmpty) throw ArgumentError('Location and description are required');
    if (!waterIssueTypes.contains(issueType)) throw ArgumentError('Invalid issue type: $issueType');
    if (!waterSeverities.contains(severity)) throw ArgumentError('Invalid severity: $severity');
    if (!litresPerHour.isFinite || litresPerHour <= 0) throw ArgumentError('Litres per hour must be positive');
    if (!durationHours.isFinite || durationHours < 0) throw ArgumentError('Duration cannot be negative');
    final now = DateTime.now();
    final incident = WaterIncident(
      id: 'WA-${now.microsecondsSinceEpoch}', locationName: location.trim(), issueType: issueType,
      estimatedLitresPerHour: litresPerHour, reportedAt: now, estimatedDurationHours: durationHours,
      severity: severity, description: description.trim(), status: 'open',
    );
    await repo.addIncident(incident);
    return incident;
  }

  /// Try [online]; on ANY error/timeout fall back to the offline fixture with a clear notice.
  static Future<AnalysisOutcome> analyze(LeakAnalyzer online) async {
    try {
      return AnalysisOutcome(await online.analyze());
    } catch (e) {
      final r = await const FixtureLeakAnalyzer().analyze();
      return AnalysisOutcome(r, 'Could not reach the AI server, so a saved sample estimate was used instead.');
    }
  }
}
