import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../models/energy_alert.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';

/// One energy alert: reason, actual vs expected, impact, and an expandable evidence trail.
class EnergyAlertCard extends StatefulWidget {
  final EnergyAlert alert;
  final ValueChanged<String>? onStatusChange;
  const EnergyAlertCard({super.key, required this.alert, this.onStatusChange});
  @override
  State<EnergyAlertCard> createState() => _EnergyAlertCardState();
}

class _EnergyAlertCardState extends State<EnergyAlertCard> {
  bool _open = false;

  String _hhmm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final t = Theme.of(context).textTheme;
    final a = widget.alert;
    final c = pal.of(a.isActive ? Tone.danger : (a.isResolved ? Tone.success : Tone.neutral));
    final top = math.max(a.actualKwh, a.expectedKwh) * 1.1;
    final cb = widget.onStatusChange;

    return AppCard(
      accent: a.isActive ? pal.danger : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: c.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(13)),
            child: Icon(Icons.bolt_outlined, color: c),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.roomName, style: t.titleSmall),
              Text('Raised at ${_hhmm(a.timestamp)}', style: t.bodySmall),
            ]),
          ),
          StatusBadge.status(a.status),
        ]),
        const SizedBox(height: 12),
        Text(a.reason, style: t.bodyMedium),
        const SizedBox(height: 16),
        LoadBar(actual: a.actualKwh, expected: a.expectedKwh, max: top, over: a.isActive),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Expected ${a.expectedKwh.toStringAsFixed(2)} kWh', style: t.bodySmall),
          Text('Actual ${a.actualKwh.toStringAsFixed(2)} kWh',
              style: t.bodySmall?.copyWith(color: a.isActive ? pal.danger : pal.muted, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _Figure(label: 'Excess', value: '+${a.excessKwh.toStringAsFixed(2)} kWh')),
          Expanded(child: _Figure(label: 'Cost', value: '₹${a.estimatedCost.toStringAsFixed(0)}')),
          Expanded(child: _Figure(label: 'CO₂e', value: '${a.estimatedCo2Kg.toStringAsFixed(1)} kg')),
        ]),
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: () => setState(() => _open = !_open),
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4), alignment: Alignment.centerLeft),
          icon: AnimatedRotation(turns: _open ? 0.5 : 0, duration: const Duration(milliseconds: 250), child: const Icon(Icons.expand_more, size: 20)),
          label: const Text('How this was worked out'),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _open
              ? Padding(padding: const EdgeInsets.only(top: 8, bottom: 4), child: ExplainSteps(steps: energyEvidence(a)))
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          if (a.isActive) ...[
            OutlinedButton.icon(
              onPressed: cb == null ? null : () => cb('dismissed'),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Dismiss'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: cb == null ? null : () => cb('resolved'),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Mark resolved'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            ),
          ] else
            TextButton.icon(
              onPressed: cb == null ? null : () => cb('active'),
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Re-open'),
            ),
        ]),
      ]),
    );
  }
}

class _Figure extends StatelessWidget {
  final String label, value;
  const _Figure({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: t.bodySmall),
      Text(value, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
    ]);
  }
}
