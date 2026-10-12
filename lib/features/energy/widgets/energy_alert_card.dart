import 'package:flutter/material.dart';
import '../../../models/energy_alert.dart';

/// Card displaying an individual EnergyAlert with mathematical derivation
/// and status action buttons (Active, Resolved, Dismissed).
class EnergyAlertCard extends StatelessWidget {
  final EnergyAlert alert;
  final ValueChanged<String>? onStatusChange;

  const EnergyAlertCard({
    super.key,
    required this.alert,
    this.onStatusChange,
  });

  Color _getStatusColor() {
    switch (alert.status.toLowerCase()) {
      case 'active':
        return const Color(0xFFE53935); // Vivid Crimson Alert
      case 'resolved':
        return const Color(0xFF2E7D32); // Eco Forest Green
      case 'dismissed':
        return const Color(0xFF757575); // Neutral Slate
      default:
        return const Color(0xFFF57C00);
    }
  }

  IconData _getStatusIcon() {
    switch (alert.status.toLowerCase()) {
      case 'active':
        return Icons.warning_amber_rounded;
      case 'resolved':
        return Icons.check_circle_outline_rounded;
      case 'dismissed':
        return Icons.do_not_disturb_on_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();

    return Card(
      elevation: alert.isActive ? 2 : 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: alert.isActive
              ? statusColor.withAlpha(120)
              : theme.colorScheme.outlineVariant.withAlpha(60),
          width: alert.isActive ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Room name & status chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.roomName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ID: ${alert.id} • ${_formatTime(alert.timestamp)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withAlpha(90)),
                  ),
                  child: Text(
                    alert.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Plain Language Reason Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alert.reason,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Quantitative Metrics Triplets
            Row(
              children: [
                Expanded(
                  child: _MetricPill(
                    label: 'Excess kWh',
                    value: '+${alert.excessKwh.toStringAsFixed(2)}',
                    subtext: '${alert.actualKwh.toStringAsFixed(1)} vs ${alert.expectedKwh.toStringAsFixed(1)}',
                    color: Colors.amber.shade800,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricPill(
                    label: 'Cost Leak',
                    value: '₹${alert.estimatedCost.toStringAsFixed(2)}',
                    subtext: '@ ₹${alert.tariffPerKwh.toStringAsFixed(0)}/kWh',
                    color: Colors.deepOrange.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricPill(
                    label: 'Emissions',
                    value: '${alert.estimatedCo2Kg.toStringAsFixed(2)} kg',
                    subtext: 'CO₂ Equivalent',
                    color: Colors.teal.shade800,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (alert.isActive) ...[
                  OutlinedButton.icon(
                    onPressed: onStatusChange != null
                        ? () => onStatusChange!('dismissed')
                        : null,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Dismiss'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: onStatusChange != null
                        ? () => onStatusChange!('resolved')
                        : null,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Mark Resolved'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                ] else ...[
                  TextButton.icon(
                    onPressed: onStatusChange != null
                        ? () => onStatusChange!('active')
                        : null,
                    icon: const Icon(Icons.restart_alt_rounded, size: 16),
                    label: const Text('Re-open Alert'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final String subtext;
  final Color color;

  const _MetricPill({
    required this.label,
    required this.value,
    required this.subtext,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 9,
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
