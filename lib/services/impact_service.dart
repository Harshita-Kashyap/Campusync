import '../models/models.dart';
import 'app_repository.dart';

/// One actionable row in the admin priority queue.
class QueueItem {
  final String id, type, title, subtitle, priority, status; // type: energy|water
  final DateTime time;
  const QueueItem({required this.id, required this.type, required this.title, required this.subtitle,
      required this.priority, required this.status, required this.time});
}

class ImpactMetrics {
  final double excessKwh, energyCost, co2Kg;
  final double waterActiveLossLitres, waterHistoricalLossLitres;
  final int openIncidents, activeAlerts, criticalHigh, resolvedItems, pagesAvoided;
  final List<QueueItem> queue;
  final List<SustainabilityRecommendation> recommendations;
  const ImpactMetrics({
    required this.excessKwh, required this.energyCost, required this.co2Kg,
    required this.waterActiveLossLitres, required this.waterHistoricalLossLitres,
    required this.openIncidents, required this.activeAlerts, required this.criticalHigh,
    required this.resolvedItems, required this.pagesAvoided, required this.queue, required this.recommendations,
  });
}

/// Metric scope (documented):
///  Energy  – active alerts only.
///  Water   – ACTIVE loss = open + in_progress incidents (resolved/dismissed excluded);
///            historical loss = all except dismissed, shown separately.
///  Pages   – sum of declared pagesAvoidedEstimate. Units are never combined.
class ImpactService {
  static int _rank(String p) => const {'critical': 4, 'high': 3, 'medium': 2, 'low': 1}[p] ?? 0;
  static String _energyPriority(EnergyAlert a) => a.excessKwh > 15 ? 'high' : (a.excessKwh > 5 ? 'medium' : 'low');

  static ImpactMetrics compute(AppRepository repo) {
    final alerts = repo.getAlerts(), incidents = repo.getIncidents(), subs = repo.getSubmissions();
    final active = alerts.where((a) => a.status == 'active').toList();
    final openInc = incidents.where((i) => i.status == 'open' || i.status == 'in_progress').toList();

    final queue = <QueueItem>[
      for (final i in openInc)
        QueueItem(id: i.id, type: 'water', title: i.locationName,
            subtitle: '${i.issueType.replaceAll('_', ' ')} · ~${i.estimatedLitresLost.toStringAsFixed(0)} L (est.)',
            priority: i.severity, status: i.status, time: i.reportedAt),
      for (final a in active)
        QueueItem(id: a.id, type: 'energy', title: a.roomName,
            subtitle: '${a.excessKwh.toStringAsFixed(1)} kWh above expected · ${a.reason}',
            priority: _energyPriority(a), status: a.status, time: a.timestamp),
    ]..sort((a, b) {
        final r = _rank(b.priority).compareTo(_rank(a.priority));
        return r != 0 ? r : b.time.compareTo(a.time);
      });

    return ImpactMetrics(
      excessKwh: active.fold(0.0, (s, a) => s + a.excessKwh),
      energyCost: active.fold(0.0, (s, a) => s + a.estimatedCost),
      co2Kg: active.fold(0.0, (s, a) => s + a.estimatedCo2Kg),
      waterActiveLossLitres: openInc.fold(0.0, (s, i) => s + i.estimatedLitresLost),
      waterHistoricalLossLitres:
          incidents.where((i) => i.status != 'dismissed').fold(0.0, (s, i) => s + i.estimatedLitresLost),
      openIncidents: openInc.length,
      activeAlerts: active.length,
      criticalHigh: queue.where((q) => _rank(q.priority) >= 3).length,
      resolvedItems: alerts.where((a) => a.status == 'resolved').length +
          incidents.where((i) => i.status == 'resolved').length,
      pagesAvoided: subs.fold(0, (s, x) => s + x.pagesAvoidedEstimate),
      queue: queue,
      recommendations: repo.getRecommendations().isNotEmpty ? repo.getRecommendations() : _fallback(active, openInc),
    );
  }

  /// Offline rule-based fallback until Person 4's SustainabilityAgent supplies recommendations.
  static List<SustainabilityRecommendation> _fallback(List<EnergyAlert> active, List<WaterIncident> open) => [
        for (final i in open.where((i) => i.severity == 'high' || i.severity == 'critical'))
          SustainabilityRecommendation(
              id: 'REC-${i.id}', title: 'Inspect ${i.locationName}', sourceType: 'water', sourceId: i.id,
              priority: i.severity, explanation: i.description, suggestedAction: 'Dispatch maintenance for prompt inspection',
              evidenceSummary: '${i.severity} ${i.issueType.replaceAll('_', ' ')}, ~${i.estimatedLitresLost.toStringAsFixed(0)} L lost (estimate)'),
        for (final a in active.where((a) => a.excessKwh > 5))
          SustainabilityRecommendation(
              id: 'REC-${a.id}', title: 'Check ${a.roomName}', sourceType: 'energy', sourceId: a.id,
              priority: _energyPriority(a), explanation: a.reason,
              suggestedAction: 'Check lights, cooling and after-hours use',
              evidenceSummary: '${a.excessKwh.toStringAsFixed(1)} kWh above expected baseline (estimate)'),
      ];
}
