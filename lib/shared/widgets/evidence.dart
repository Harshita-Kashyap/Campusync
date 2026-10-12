import 'package:flutter/material.dart' show Icons;
import '../../models/models.dart';
import '../../services/water_service.dart' show labelOf;
import '../theme/app_colors.dart';
import 'explain_steps.dart';
import 'format.dart';

/// Evidence trail for a water incident: reported -> rate x time -> counted or not.
List<ExplainStep> waterEvidence(WaterIncident i) {
  final counts = i.status == 'open' || i.status == 'in_progress';
  final lph = i.estimatedLitresPerHour;
  return [
    ExplainStep(icon: Icons.report_outlined, title: 'Reported at ${i.locationName}',
        detail: '${prettyStatus(labelOf(i.issueType))}, ${timeAgo(i.reportedAt)}', value: prettyStatus(i.severity), tone: Tone.warning),
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
