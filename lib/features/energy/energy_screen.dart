import 'package:flutter/material.dart';
import '../../services/energy_service.dart';
import 'widgets/energy_metric_card.dart';
import 'widgets/energy_alert_card.dart';
import 'widgets/room_energy_tile.dart';
import 'widgets/energy_quick_chart.dart';
import 'widgets/timetable_schedule_view.dart';

/// Person 2 Owned Screen: EcoNudge AI — Energy Intelligence Dashboard.
///
/// Features:
/// - Real-time aggregated campus impact metrics (kWh excess, INR cost, CO2e).
/// - Anomaly detection feed with plain-language explanations.
/// - Live sub-meter telemetry comparison against timetable baseline.
/// - 10-Class Timetable Explorer demonstrating timetable-informed baselines.
/// - Custom painted comparative audit chart.
/// - Alert status actions: Active, Resolved, Dismissed.
class EnergyScreen extends StatefulWidget {
  final EnergyService? service;

  const EnergyScreen({
    super.key,
    this.service,
  });

  @override
  State<EnergyScreen> createState() => _EnergyScreenState();
}

class _EnergyScreenState extends State<EnergyScreen> with SingleTickerProviderStateMixin {
  late final EnergyService _service;
  late final TabController _tabController;

  String _alertFilter = 'active'; // 'all', 'active', 'resolved', 'dismissed'

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? EnergyService();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _service,
      builder: (context, _) {
        final totalExcess = _service.getEstimatedExcessKwh();
        final totalCost = _service.getEstimatedCost();
        final totalCo2 = _service.getEstimatedCo2Kg();
        final activeAlerts = _service.getActiveAlerts();

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 2,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt_rounded, color: Color(0xFF2E7D32), size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'EcoNudge AI',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Person 2',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Campus Energy Wastage & Timetable Intelligence',
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.sync_rounded),
                tooltip: 'Simulate Telemetry Refresh',
                onPressed: () {
                  _service.refreshTelemetry();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚡ Smart sub-meter telemetry synchronized!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
                  if (value == 'reset') {
                    _service.resetToDefaults();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reset fixtures to defaults.')),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'reset',
                    child: Row(
                      children: [
                        Icon(Icons.restart_alt_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Reset Sample Fixtures'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: [
                Tab(
                  icon: const Icon(Icons.warning_amber_rounded, size: 18),
                  text: 'Alerts (${activeAlerts.length})',
                ),
                const Tab(
                  icon: Icon(Icons.meeting_room_outlined, size: 18),
                  text: '10-Room Audit',
                ),
                const Tab(
                  icon: Icon(Icons.calendar_month_outlined, size: 18),
                  text: '10 Timetables',
                ),
                const Tab(
                  icon: Icon(Icons.bar_chart_rounded, size: 18),
                  text: 'Audit Chart',
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // TAB 1: ALERTS & OVERVIEW
              _buildAlertsTab(totalExcess, totalCost, totalCo2, activeAlerts),

              // TAB 2: ROOM AUDIT (10 Rooms)
              _buildRoomAuditTab(),

              // TAB 3: 10 TIMETABLES EXPLORER
              _buildTimetableTab(),

              // TAB 4: AUDIT CHART
              _buildChartTab(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertsTab(
    double totalExcess,
    double totalCost,
    double totalCo2,
    List<dynamic> activeAlerts,
  ) {
    final allAlerts = _service.getAlerts();
    final filteredAlerts = _alertFilter == 'all'
        ? allAlerts
        : allAlerts.where((a) => a.status.toLowerCase() == _alertFilter).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Impact Metrics Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isWide ? 1.4 : 1.15,
                children: [
                  EnergyMetricCard(
                    title: 'Active Wastage',
                    value: '${totalExcess.toStringAsFixed(2)} kWh',
                    subtitle: 'Excess above timetable baseline',
                    icon: Icons.electric_bolt_rounded,
                    accentColor: const Color(0xFFE53935),
                    badge: '${activeAlerts.length} Anomaly',
                  ),
                  EnergyMetricCard(
                    title: 'Rupee Cost Leak',
                    value: '₹${totalCost.toStringAsFixed(2)}',
                    subtitle: 'Calculated @ ₹${_service.tariffPerKwh}/kWh',
                    icon: Icons.currency_rupee_rounded,
                    accentColor: const Color(0xFFF57C00),
                  ),
                  EnergyMetricCard(
                    title: 'Excess Emissions',
                    value: '${totalCo2.toStringAsFixed(2)} kg',
                    subtitle: '@ 0.82 kg CO₂e / kWh',
                    icon: Icons.cloud_outlined,
                    accentColor: const Color(0xFF00897B),
                  ),
                  EnergyMetricCard(
                    title: 'Active Facilities',
                    value: '10 Zones',
                    subtitle: 'Real-time sensor simulated',
                    icon: Icons.domain_rounded,
                    accentColor: const Color(0xFF1E88E5),
                    badge: '100% Offline',
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // Alert Filter Chips Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Energy Anomaly Log',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  _buildFilterChip('active', 'Active'),
                  const SizedBox(width: 6),
                  _buildFilterChip('resolved', 'Resolved'),
                  const SizedBox(width: 6),
                  _buildFilterChip('all', 'All'),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Alerts List or Empty State
          if (filteredAlerts.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.eco_rounded, size: 48, color: Colors.green.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    'No alerts in this view',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'All campus spaces are currently operating within rated timetable baselines.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ...filteredAlerts.map(
              (alert) => EnergyAlertCard(
                alert: alert,
                onStatusChange: (newStatus) {
                  _service.updateAlertStatus(alert.id, newStatus);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _alertFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _alertFilter = value);
      },
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }

  Widget _buildRoomAuditTab() {
    final readings = _service.getRoomReadings();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withAlpha(15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2E7D32).withAlpha(40)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Color(0xFF2E7D32)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Live comparison of actual sub-meter telemetry against dynamic baselines dictated by the class timetables.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...readings.map(
            (reading) => RoomEnergyTile(
              reading: reading,
              onTap: () {
                if (reading.hasWastageAnomaly) {
                  _service.evaluateReading(reading);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Evaluated alert for ${reading.roomName}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableTab() {
    final classes = _service.getAllClasses();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Academic Timetable Matrix (10 Classes)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Explore scheduled courses across AI&DS and CSE departments. Notice how slots in shared labs (Lab 220 A+B, IBM 320) dynamically reduce the expected energy consumption of home classrooms.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TimetableScheduleView(classes: classes),
        ],
      ),
    );
  }

  Widget _buildChartTab() {
    final readings = _service.getRoomReadings();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EnergyQuickChart(readings: readings),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explainable Anomaly Logic',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Baseline Energy = Occupancy Status (from Timetable) × Room Power Profile.\n'
                    '2. Unscheduled Room baseline = 0.20 kWh (idle standby).\n'
                    '3. Scheduled Lecture baseline = 1.90 – 2.00 kWh (60 students + projector + fans).\n'
                    '4. Computer Lab session = 4.80 kWh (40–60 desktop workstations + ACs).\n'
                    '5. Anomaly Rule: If Actual > (Baseline + 0.35 kWh buffer) and Excess > 0.40 kWh → Flag Anomaly.\n'
                    '6. Impact Formula:\n'
                    '   • excessKwh = max(0, actualKwh - expectedKwh)\n'
                    '   • estimatedCost = excessKwh × ₹8.00\n'
                    '   • estimatedCo2Kg = excessKwh × 0.82 kg CO₂e',
                    style: TextStyle(fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
