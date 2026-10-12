import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../services/water_api_client.dart';
import '../../services/water_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';
import '../dashboard/role_switch_button.dart';

/// Admin: loads incidents from Flask/MySQL, filters the priority list and updates repair status.
class WaterScreen extends StatefulWidget {
  final bool isActive;
  const WaterScreen({super.key, this.isActive = true});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  final _server = TextEditingController(text: WaterApiClient.defaultBaseUrl);
  String _status = 'all';
  String _severity = 'all';
  bool _refreshQueued = false;
  bool _serverInitialized = false;
  bool _loadingRemote = false;
  bool _serverSynced = false;
  String? _syncError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_serverInitialized) {
      _server.text = RepositoryScope.of(context).waterApiBaseUrl;
      _serverInitialized = true;
    }
    if (widget.isActive) _queueInitialRefresh();
  }

  @override
  void didUpdateWidget(covariant WaterScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) _queueInitialRefresh();
  }

  void _queueInitialRefresh() {
    if (_refreshQueued) return;
    _refreshQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refreshFromServer());
    });
  }

  @override
  void dispose() {
    _server.dispose();
    super.dispose();
  }

  Future<void> _refreshFromServer() async {
    if (_loadingRemote) return;
    RepositoryScope.of(context).setWaterApiBaseUrl(_server.text);
    setState(() {
      _loadingRemote = true;
      _syncError = null;
    });
    try {
      final incidents = await WaterApiClient(baseUrl: _server.text.trim()).getIncidents();
      if (!mounted) return;
      RepositoryScope.of(context).replaceWaterIncidents(incidents);
      setState(() {
        _serverSynced = true;
        _syncError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _syncError = error.toString());
    } finally {
      if (mounted) setState(() => _loadingRemote = false);
    }
  }

  Future<void> _updateStatus(AppRepository repo, WaterIncident incident, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    final serverBacked = _serverSynced;
    try {
      if (serverBacked) {
        await WaterApiClient(baseUrl: _server.text.trim()).updateStatus(incident.id, status);
      }
      await WaterService(repo).updateIncidentStatus(incident.id, status);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(serverBacked
            ? '${incident.locationName} updated in MySQL: ${prettyStatus(status).toLowerCase()}'
            : '${incident.locationName} updated locally (demo only; MySQL is not connected).'),
      ));
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Status was not updated: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final palette = context.pal;
    final theme = Theme.of(context).textTheme;
    final all = repo.getIncidents();
    final items = all.where((incident) =>
        (_status == 'all' || incident.status == _status) && (_severity == 'all' || incident.severity == _severity)).toList()
      ..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
    final currentLoss = WaterService(repo).getEstimatedWaterLossLitres();
    int count(String value) => value == 'all' ? all.length : all.where((incident) => incident.status == value).length;

    return ModuleScaffold(
      title: 'Water',
      actions: [
        IconButton(
          tooltip: 'Refresh from Flask/MySQL',
          onPressed: _loadingRemote ? null : _refreshFromServer,
          icon: _loadingRemote
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.sync_rounded),
        ),
        PopupMenuButton<String>(
          tooltip: 'Filter by severity',
          icon: Badge(isLabelVisible: _severity != 'all', smallSize: 8, child: const Icon(Icons.filter_list)),
          onSelected: (value) => setState(() => _severity = value),
          itemBuilder: (_) => [
            for (final value in const ['all', ...waterSeverities])
              CheckedPopupMenuItem<String>(
                value: value,
                checked: _severity == value,
                child: Text(value == 'all' ? 'Any severity' : prettyStatus(value)),
              ),
          ],
        ),
        const ThemeToggleButton(),
        const RoleSwitchButton(),
        const SizedBox(width: 4),
      ],
      body: PageBody(children: [
        _connectionCard(context),
        const SizedBox(height: 12),
        Reveal(
          child: AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Estimated loss right now', style: theme.bodySmall),
              const SizedBox(height: 4),
              AnimatedNumber(
                value: currentLoss,
                format: (value) => '~${fmtNum(value)} L',
                style: theme.headlineMedium?.copyWith(color: palette.info),
              ),
              const SizedBox(height: 6),
              Text('Open and in-progress incidents only. Rate × hours; estimates, not live sensor readings.', style: theme.bodySmall),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final value in const ['all', 'open', 'in_progress', 'resolved', 'dismissed'])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('${value == 'all' ? 'All' : prettyStatus(value)} ${count(value)}'),
                  selected: _status == value,
                  onSelected: (_) => setState(() => _status = value),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          AppCard(
            child: EmptyState(
              title: _serverSynced ? 'No incidents are stored in MySQL yet' : 'No incidents reported',
              icon: Icons.water_drop_outlined,
            ),
          )
        else
          for (var index = 0; index < items.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Reveal(
                key: ValueKey('${items[index].id}-$_status-$_severity'),
                delay: stagger(index),
                child: AppCard(
                  onTap: () => _detail(context, repo, items[index]),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(items[index].locationName, style: theme.titleSmall),
                        const SizedBox(height: 2),
                        Text('${prettyStatus(labelOf(items[index].issueType))}, ${timeAgo(items[index].reportedAt)}', style: theme.bodySmall),
                        const SizedBox(height: 2),
                        Text('~${fmtNum(items[index].estimatedLitresLost)} L estimated loss', style: theme.bodyMedium),
                        const SizedBox(height: 10),
                        Wrap(spacing: 6, runSpacing: 6, children: [
                          StatusBadge.priority(items[index].severity),
                          StatusBadge.status(items[index].status),
                        ]),
                      ]),
                    ),
                    Icon(Icons.chevron_right, color: palette.muted),
                  ]),
                ),
              ),
            ),
      ]),
    );
  }

  Widget _connectionCard(BuildContext context) {
    final palette = context.pal;
    final theme = Theme.of(context).textTheme;
    final Color statusColor;
    final IconData statusIcon;
    final String statusText;
    if (_loadingRemote) {
      statusColor = palette.info;
      statusIcon = Icons.sync_rounded;
      statusText = 'Connecting to Flask and MySQL…';
    } else if (_serverSynced && _syncError != null) {
      statusColor = palette.warning;
      statusIcon = Icons.cloud_off_outlined;
      statusText = 'Showing last synced MySQL records · latest refresh failed';
    } else if (_serverSynced) {
      statusColor = palette.success;
      statusIcon = Icons.cloud_done_outlined;
      statusText = 'Connected · showing persisted MySQL incidents';
    } else {
      statusColor = palette.warning;
      statusIcon = Icons.cloud_off_outlined;
      statusText = 'Offline · showing local/demo incidents; status edits will not reach MySQL';
    }

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(statusIcon, color: statusColor),
          const SizedBox(width: 10),
          Expanded(child: Text(statusText, style: theme.bodySmall?.copyWith(color: statusColor, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _server,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'Flask API base URL', hintText: 'http://10.0.2.2:5000'),
              onSubmitted: (_) => _refreshFromServer(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Load stored incidents',
            onPressed: _loadingRemote ? null : _refreshFromServer,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ]),
        if (_syncError != null) ...[
          const SizedBox(height: 8),
          Text('API error: $_syncError', style: theme.bodySmall?.copyWith(color: palette.danger)),
          Text('For a physical phone, use the computer’s LAN IP. The API uses port 5000 by default.', style: theme.bodySmall),
        ],
      ]),
    );
  }

  void _detail(BuildContext context, AppRepository repo, WaterIncident incident) {
    final options = ['open', 'in_progress', 'resolved', 'dismissed'].where((status) => status != incident.status).toList();
    showAppSheet<void>(
      context,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext).textTheme;
        final imageUrl = incident.imageUrl;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(incident.locationName, style: theme.titleLarge),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            StatusBadge.priority(incident.severity),
            StatusBadge.status(incident.status),
            StatusBadge.source(incident.source),
          ]),
          if (imageUrl != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                WaterApiClient(baseUrl: _server.text.trim()).absoluteUrl(imageUrl),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(incident.description, style: theme.bodyLarge),
          const SizedBox(height: 8),
          Text('${fmtNum(incident.estimatedLitresPerHour)} L/h × ${fmtNum(incident.estimatedDurationHours)} h = ~${fmtNum(incident.estimatedLitresLost)} L estimated',
              style: theme.bodyMedium),
          const SizedBox(height: 20),
          Text('How the loss was estimated', style: theme.titleMedium),
          const SizedBox(height: 12),
          ExplainSteps(steps: waterEvidence(incident)),
          const SizedBox(height: 24),
          Text('Repair progress', style: theme.titleMedium),
          const SizedBox(height: 8),
          StatusActions(
            options: options,
            onPick: (status) {
              Navigator.pop(sheetContext);
              _updateStatus(repo, incident, status);
            },
          ),
        ]);
      },
    );
  }
}
