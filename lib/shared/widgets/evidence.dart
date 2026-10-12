import 'package:flutter/material.dart' show Icons;
import '../../models/models.dart';
import '../../services/water_service.dart' show labelOf;
import '../theme/app_colors.dart';
import 'explain_steps.dart';
import 'format.dart';

/// Evidence trail for a water incident: reported -> rate x time -> counted or not.
/// Description without the machine-added "[Assumed: ...]" note.
String plainDescription(String d) {
  final k = d.indexOf('[Assumed:');
  return k < 0 ? d : d.substring(0, k).trim();
}

/// Evidence trail for a digital submission: file -> fingerprint -> duplicate check -> grade -> pages.
List<ExplainStep> submissionEvidence(DigitalSubmission s) => [
      ExplainStep(icon: Icons.description_outlined, title: 'File received', detail: s.fileName),
      ExplainStep(
          icon: Icons.fingerprint,
          title: 'SHA-256 fingerprint',
          detail: 'Same content always gives the same fingerprint',
          value: s.sha256.length > 12 ? s.sha256.substring(0, 12) : s.sha256,
          tone: Tone.info),
      ExplainStep(
          icon: s.duplicateDetected ? Icons.copy_outlined : Icons.verified_outlined,
          title: s.duplicateDetected ? 'Duplicate found' : 'Unique file',
          detail: s.source == 'api'
              ? (s.duplicateDetected ? 'Server similarity check flagged this file for review' : 'Server similarity check found no strong match')
              : (s.duplicateDetected ? 'Fingerprint matches an earlier submission' : 'No earlier submission matches'),
          tone: s.duplicateDetected ? Tone.warning : Tone.success),
      ExplainStep(
          icon: Icons.rule,
          title: s.source == 'api' ? 'AI evaluation (server)' : 'Prototype grading rules',
          detail: s.gradingFeedback,
          value: '${s.score.toStringAsFixed(s.score % 1 == 0 ? 0 : 1)}/${s.maxScore.toStringAsFixed(0)}',
          tone: Tone.neutral),
      ExplainStep(
          icon: Icons.eco_outlined,
          title: 'Paper avoided, estimate',
          detail: s.duplicateDetected ? 'Duplicates are not counted' : 'Declared pages, not verified',
          value: '~${s.pagesAvoidedEstimate} pages',
          tone: Tone.success),
    ];

List<ExplainStep> waterEvidence(WaterIncident i) {
  final k = i.description.indexOf('[Assumed:');
  final assumed = k < 0 ? null : i.description.substring(k + 9).replaceAll(']', '').trim();
  final counts = i.status == 'open' || i.status == 'in_progress';
  final lph = i.estimatedLitresPerHour;
  return [
    ExplainStep(icon: Icons.report_outlined, title: 'Reported at ${i.locationName}',
        detail: '${prettyStatus(labelOf(i.issueType))}, ${timeAgo(i.reportedAt)}', value: prettyStatus(i.severity), tone: Tone.warning),
    if (assumed != null)
      ExplainStep(icon: Icons.help_outline, title: 'Reporter was not sure',
          detail: 'Assumed: $assumed. Worth checking on site.', tone: Tone.warning),
    ExplainStep(icon: Icons.calculate_outlined, title: 'Estimated loss',
        detail: '${fmtNum(lph, lph % 1 == 0 ? 0 : 1)} L/h for ${fmtNum(i.estimatedDurationHours, 1)} h',
        value: '~${fmtNum(i.estimatedLitresLost)} L'),
    ExplainStep(
        icon: counts ? Icons.add_circle_outline : Icons.remove_circle_outline,
        title: counts ? 'Counted as current loss' : 'Not counted as current loss',
        detail: counts ? 'Open and in-progress incidents count until resolved.' : 'Resolved and dismissed incidents are left out.',
        tone: counts ? Tone.danger : Tone.neutral),
  ];
}

/// Evidence trail for an energy alert: timetable baseline -> sub-meter -> excess -> impact.
List<ExplainStep> energyEvidence(EnergyAlert a) => [
      ExplainStep(icon: Icons.calendar_month_outlined, title: 'Expected from the timetable',
          detail: 'What this room should draw right now', value: '${a.expectedKwh.toStringAsFixed(2)} kWh', tone: Tone.info),
      ExplainStep(icon: Icons.speed_outlined, title: 'Measured on the sub-meter',
          detail: 'Simulated reading in this demo', value: '${a.actualKwh.toStringAsFixed(2)} kWh'),
      ExplainStep(icon: Icons.flag_outlined, title: 'Flagged: above baseline',
          detail: 'Excess = actual minus expected', value: '+${a.excessKwh.toStringAsFixed(2)} kWh', tone: Tone.warning),
      ExplainStep(icon: Icons.currency_rupee, title: 'Estimated impact',
          detail: '₹${a.tariffPerKwh.toStringAsFixed(0)}/kWh and ${a.co2KgPerKwh} kg CO₂e/kWh',
          value: '₹${a.estimatedCost.toStringAsFixed(0)}, ${a.estimatedCo2Kg.toStringAsFixed(1)} kg', tone: Tone.danger),
    ];
