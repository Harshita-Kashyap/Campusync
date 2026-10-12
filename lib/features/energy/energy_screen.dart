import 'package:flutter/material.dart';
import '../../services/energy_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';
import '../dashboard/role_switch_button.dart';
import 'widgets/energy_alert_card.dart';
import 'widgets/energy_quick_chart.dart';
import 'widgets/room_energy_tile.dart';
import 'widgets/timetable_schedule_view.dart';

/// Energy: timetable-aware anomaly detection. Rule-based and explainable.
class EnergyScreen extends StatefulWidget {
  final EnergyService? service;
  const EnergyScreen({super.key, this.service});
  @override
  State<EnergyScreen> createState() => _EnergyScreenState();
}

class _EnergyScreenState extends State<EnergyScreen> with SingleTickerProviderStateMixin {
  late final EnergyService _service;
  late final TabController _tabs;
  String _filter = 'active'; // active | resolved | all

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? EnergyService();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _say(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final t = Theme.of(context).textTheme;
    return AnimatedBuilder(
      animation: _service,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Energy'),
            Text('Timetable-aware anomaly detection', style: t.bodySmall),
          ]),
          actions: [
            IconButton(
              icon: const Icon(Icons.sync_rounded),
              tooltip: 'Refresh simulated telemetry',
              onPressed: () {
                _service.refreshTelemetry();
                _say('Telemetry refreshed (simulated)');
              },
            ),
            const ThemeToggleButton(),
            const RoleSwitchButton(),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (v) {
                if (v == 'reset') {
                  _service.resetToDefaults();
                  _say('Sample data reset');
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'reset',
                  child: Row(children: [Icon(Icons.restart_alt_rounded, size: 18), SizedBox(width: 8), Text('Reset sample data')]),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            controller: _tabs,
            tabAlignment: TabAlignment.fill,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: pal.ink,
            unselectedLabelColor: pal.muted,
            indicatorColor: pal.brand,
            dividerColor: pal.line,
            labelStyle: t.labelLarge,
            tabs: [
              Tab(text: 'Alerts (${_service.getActiveAlerts().length})'),
              const Tab(text: 'Rooms'),
              const Tab(text: 'Timetable'),
              const Tab(text: 'Chart'),
            ],
          ),
        ),
        body: TabBarView(controller: _tabs, children: [_alertsTab(context), _roomsTab(context), _timetableTab(context), _chartTab(context)]),
      ),
    );
  }

  Widget _alertsTab(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final all = _service.getAlerts();
    final list = _filter == 'all' ? all : all.where((a) => a.status.toLowerCase() == _filter).toList();
    final style = t.titleLarge?.copyWith(fontWeight: FontWeight.w800);

    return PageBody(children: [
      Reveal(
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: IntrinsicHeight(
            child: Row(children: [
              _Summary(label: 'Above baseline',
                  child: AnimatedNumber(value: _service.getEstimatedExcessKwh(), format: (v) => '${fmtNum(v, 1)} kWh', style: style)),
              VerticalDivider(color: context.pal.line, width: 1),
              _Summary(label: 'Cost, estimate',
                  child: AnimatedNumber(value: _service.getEstimatedCost(), format: (v) => '₹${fmtNum(v)}', style: style)),
              VerticalDivider(color: context.pal.line, width: 1),
              _Summary(label: 'CO₂e, estimate',
                  child: AnimatedNumber(value: _service.getEstimatedCo2Kg(), format: (v) => '${fmtNum(v, 1)} kg', style: style)),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text('Active alerts only. ₹${_service.tariffPerKwh.toStringAsFixed(0)}/kWh, ${_service.co2KgPerKwh} kg CO₂e/kWh.', style: t.bodySmall),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'active', label: Text('Active')),
            ButtonSegment(value: 'resolved', label: Text('Resolved')),
            ButtonSegment(value: 'all', label: Text('All')),
          ],
          selected: {_filter},
          onSelectionChanged: (s) => setState(() => _filter = s.first),
        ),
      ),
      const SizedBox(height: 16),
      if (list.isEmpty)
        const AppCard(child: EmptyState(title: 'No alerts here', message: 'Every room is within its timetable baseline.', icon: Icons.eco_outlined))
      else
        for (var i = 0; i < list.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Reveal(
              key: ValueKey('${list[i].id}-$_filter'),
              delay: stagger(i),
              child: EnergyAlertCard(alert: list[i], onStatusChange: (s) => _service.updateAlertStatus(list[i].id, s)),
            ),
          ),
    ]);
  }

  Widget _roomsTab(BuildContext context) {
    final readings = _service.getRoomReadings();
    return PageBody(children: [
      Text('Actual draw against what the timetable expects. Tap a flagged room to raise an alert.', style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 14),
      for (var i = 0; i < readings.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Reveal(
            delay: stagger(i, 40),
            child: RoomEnergyTile(
              reading: readings[i],
              onTap: () {
                if (readings[i].hasWastageAnomaly) {
                  _service.evaluateReading(readings[i]);
                  _say('Alert evaluated for ${readings[i].roomName}');
                }
              },
            ),
          ),
        ),
    ]);
  }

  Widget _timetableTab(BuildContext context) => PageBody(children: [
        Text('When a class is away in a shared lab, its home room is expected to be empty, so the baseline drops.',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 14),
        TimetableScheduleView(classes: _service.getAllClasses()),
      ]);

  Widget _chartTab(BuildContext context) => PageBody(children: [
        EnergyQuickChart(readings: _service.getRoomReadings()),
        SectionHeading('How alerts are decided', trailing: StatusBadge.rules()),
        AppCard(
          child: ExplainSteps(steps: [
            const ExplainStep(icon: Icons.calendar_month_outlined, title: 'The timetable sets the expectation',
                detail: 'A vacant room is expected to draw about 0.20 kWh, a lecture 1.9 to 2.0 kWh, a computer lab 4.8 kWh.', tone: Tone.info),
            const ExplainStep(icon: Icons.speed_outlined, title: 'The sub-meter gives the actual', detail: 'Simulated readings in this demo.'),
            const ExplainStep(icon: Icons.flag_outlined, title: 'A simple rule flags it',
                detail: 'Actual is more than 0.35 kWh above expected, and the excess is over 0.40 kWh.', tone: Tone.warning),
            ExplainStep(icon: Icons.currency_rupee, title: 'Impact follows from the excess',
                detail: 'Cost = excess × ₹${_service.tariffPerKwh.toStringAsFixed(0)}/kWh. Emissions = excess × ${_service.co2KgPerKwh} kg CO₂e/kWh.',
                tone: Tone.danger),
          ]),
        ),
        const SizedBox(height: 10),
        Text('No black box: every alert can be traced back to these four steps.', style: Theme.of(context).textTheme.bodySmall),
      ]);
}

class _Summary extends StatelessWidget {
  final String label;
  final Widget child;
  const _Summary({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            FittedBox(fit: BoxFit.scaleDown, child: child),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ]),
        ),
      );
}
