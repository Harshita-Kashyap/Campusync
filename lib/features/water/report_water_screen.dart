import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException, rootBundle;
import 'package:image_picker/image_picker.dart';

import '../../models/water_incident.dart';
import '../../services/app_repository.dart';
import '../../services/water_api_client.dart';
import '../../services/water_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';

/// Student report flow. A photo is analyzed and persisted by Flask/MySQL;
/// manual reports are also sent to Flask, with a clearly labelled local demo fallback.
class ReportWaterScreen extends StatefulWidget {
  final VoidCallback? onDone;
  const ReportWaterScreen({super.key, this.onDone});

  @override
  State<ReportWaterScreen> createState() => _ReportWaterScreenState();
}

class _ReportWaterScreenState extends State<ReportWaterScreen> {
  static const _maxImageBytes = 10 * 1024 * 1024;

  final _form = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _location = TextEditingController();
  final _rate = TextEditingController();
  final _hours = TextEditingController(text: '1');
  final _desc = TextEditingController();
  final _server = TextEditingController(text: WaterApiClient.defaultBaseUrl);

  String _type = 'leaking_tap';
  String _severity = 'low';
  Uint8List? _photoBytes;
  String? _photoName;
  bool _samplePhoto = false;
  bool _serverInitialized = false;
  bool _busy = false;
  bool _savedLocally = false;
  String? _submitError;
  String? _submitNotice;
  WaterIncident? _submittedIncident;

  double? get _litresPerHour => double.tryParse(_rate.text.trim());
  double? get _durationHours => double.tryParse(_hours.text.trim());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_serverInitialized) {
      _server.text = RepositoryScope.of(context).waterApiBaseUrl;
      _serverInitialized = true;
    }
  }

  @override
  void dispose() {
    for (final controller in [_location, _rate, _hours, _desc, _server]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 2000, maxHeight: 2000);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > _maxImageBytes) {
        _message('Choose an image smaller than 10 MB.');
        return;
      }
      if (!mounted) return;
      setState(() {
        _photoBytes = bytes;
        _photoName = file.name;
        _samplePhoto = false;
        _submitError = null;
      });
    } on PlatformException catch (error) {
      _message('Could not open the image picker: ${error.message ?? error.code}');
    } catch (error) {
      _message('Could not load that image: $error');
    }
  }

  Future<void> _useSamplePhoto() async {
    try {
      final data = await rootBundle.load(FixtureLeakAnalyzer.assetPath);
      if (!mounted) return;
      setState(() {
        _photoBytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        _photoName = 'sample_leak.png';
        _samplePhoto = true;
        _submitError = null;
      });
    } catch (error) {
      _message('The saved demo photo could not be loaded: $error');
    }
  }

  void _removePhoto() => setState(() {
        _photoBytes = null;
        _photoName = null;
        _samplePhoto = false;
        _submitError = null;
      });

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final repo = RepositoryScope.of(context);
    repo.setWaterApiBaseUrl(_server.text);
    setState(() {
      _busy = true;
      _submitError = null;
      _submitNotice = null;
    });

    try {
      final incident = await WaterApiClient(baseUrl: _server.text.trim()).createIncident(
        location: _location.text,
        durationHours: _durationHours!,
        imageBytes: _photoBytes,
        imageName: _photoName,
        reporterNote: _photoBytes == null ? null : _desc.text,
        issueType: _photoBytes == null ? _type : null,
        severity: _photoBytes == null ? _severity : null,
        litresPerHour: _photoBytes == null ? _litresPerHour : null,
        description: _photoBytes == null ? _desc.text : null,
      );
      await repo.upsertWaterIncident(incident);
      if (!mounted) return;
      setState(() {
        _submittedIncident = incident;
        _savedLocally = false;
      });
    } catch (error) {
      // Keep the demo usable when the API is offline, but never claim these
      // records were written to MySQL. Real photos are not replaced with fake AI.
      try {
        if (_photoBytes != null && !_samplePhoto) {
          throw error;
        }
        final WaterIncident incident;
        if (_samplePhoto) {
          final sample = await const FixtureLeakAnalyzer().analyze();
          incident = await WaterService(repo).submitReport(
            location: _location.text,
            issueType: sample.issueType,
            severity: sample.severity,
            litresPerHour: sample.estimatedLitresPerHour,
            durationHours: _durationHours!,
            description: sample.description,
            source: 'sample',
          );
        } else {
          incident = await WaterService(repo).submitReport(
            location: _location.text,
            issueType: _type,
            severity: _severity,
            litresPerHour: _litresPerHour!,
            durationHours: _durationHours!,
            description: _desc.text,
            source: 'manual',
          );
        }
        if (!mounted) return;
        setState(() {
          _submittedIncident = incident;
          _savedLocally = true;
          _submitNotice = 'Flask/MySQL could not be reached. This report is only in the app\'s local demo state; it was not saved to the database.';
        });
      } catch (localError) {
        if (!mounted) return;
        setState(() => _submitError = 'Report was not saved. $localError');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reset() {
    _form.currentState?.reset();
    for (final controller in [_location, _rate, _desc]) {
      controller.clear();
    }
    _hours.text = '1';
    setState(() {
      _type = 'leaking_tap';
      _severity = 'low';
      _photoBytes = null;
      _photoName = null;
      _samplePhoto = false;
      _submitError = null;
      _submitNotice = null;
      _submittedIncident = null;
      _savedLocally = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rate = _litresPerHour;
    final hours = _durationHours;
    final estimatedLoss = rate != null && hours != null && rate >= 0 && hours >= 0 ? rate * hours : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Report a water leak'), actions: const [ThemeToggleButton(), SizedBox(width: 4)]),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: _submittedIncident != null ? _success(context) : _formView(context, estimatedLoss),
        ),
      ),
    );
  }

  Widget _success(BuildContext context) {
    final pal = context.pal;
    final theme = Theme.of(context).textTheme;
    final incident = _submittedIncident!;
    return Center(
      key: const ValueKey('done'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(color: pal.success.withValues(alpha: 0.14), shape: BoxShape.circle),
              child: Icon(_savedLocally ? Icons.cloud_off_outlined : Icons.check_rounded, size: 40, color: pal.success),
            ),
            const SizedBox(height: 18),
            Text(_savedLocally ? 'Saved in demo mode' : 'Leak report saved', style: theme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              _savedLocally
                  ? '"${incident.locationName}" is visible in this app, but is not in MySQL.'
                  : '"${incident.locationName}" is saved in the water incident database.',
              textAlign: TextAlign.center,
              style: theme.bodyLarge?.copyWith(color: pal.muted),
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 8, runSpacing: 8, children: [
                  StatusBadge.source(incident.source),
                  StatusBadge.priority(incident.severity),
                  StatusBadge.status(incident.status),
                ]),
                const SizedBox(height: 14),
                Text('${prettyStatus(labelOf(incident.issueType))} · ${fmtNum(incident.estimatedLitresPerHour)} L/h', style: theme.titleMedium),
                const SizedBox(height: 6),
                Text(incident.description, style: theme.bodyMedium),
                const SizedBox(height: 8),
                Text('Estimated loss so far: ~${fmtNum(incident.estimatedLitresLost)} L', style: theme.bodySmall),
                Text('Incident ID: ${incident.id}', style: theme.bodySmall?.copyWith(color: pal.muted)),
              ]),
            ),
            if (_submitNotice != null) ...[
              const SizedBox(height: 12),
              Text(_submitNotice!, style: theme.bodySmall?.copyWith(color: pal.danger), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 24),
            if (widget.onDone != null)
              FilledButton(
                onPressed: () {
                  widget.onDone!();
                  _reset();
                },
                child: const Text('View my activity'),
              ),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _reset, child: const Text('Report another')),
          ]),
        ),
      ),
    );
  }

  Widget _formView(BuildContext context, double? estimatedLoss) {
    final pal = context.pal;
    final theme = Theme.of(context).textTheme;
    return Form(
      key: _form,
      child: PageBody(key: const ValueKey('form'), children: [
        Text(
          'Add a photo for server-side leak analysis, or enter a manual estimate. Water loss figures are estimates, not live sensor readings.',
          style: theme.bodyMedium?.copyWith(color: pal.muted),
        ),
        const SizedBox(height: 16),
        _photoCard(context),
        const SectionHeading('Report details'),
        TextFormField(
          controller: _location,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Location', hintText: 'e.g. Hostel B washroom'),
          validator: (value) => WaterService.validateRequired(value, 'Location'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _hours,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Hours since leak was noticed', suffixText: 'h'),
          validator: WaterService.validateDuration,
        ),
        if (_photoBytes == null) ...[
          const SectionHeading('Manual estimate'),
          _manualFields(context),
        ] else ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _desc,
            maxLines: 2,
            maxLength: 200,
            decoration: const InputDecoration(labelText: 'Extra context for the AI (optional)'),
          ),
          const SizedBox(height: 4),
          AppCard(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.cloud_upload_outlined, color: pal.info),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'On submit, the image is sent to Flask. Gemini generates the type, severity, rate and description; the result and repair status are saved in MySQL.',
                  style: theme.bodySmall,
                ),
              ),
            ]),
          ),
        ],
        const SectionHeading('Estimate'),
        AppCard(
          child: Row(children: [
            Icon(Icons.water_drop_outlined, color: pal.info),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (_photoBytes != null)
                  Text('Photo estimate will appear after upload', style: theme.titleSmall)
                else if (estimatedLoss == null)
                  Text('Estimated loss: —', style: theme.titleMedium)
                else
                  AnimatedNumber(value: estimatedLoss, format: (value) => 'Estimated loss: ~${fmtNum(value)} L', style: theme.titleMedium),
                Text('Rate × hours. Confirm estimates with a person on site.', style: theme.bodySmall),
              ]),
            ),
          ]),
        ),
        if (_submitError != null) ...[
          const SizedBox(height: 12),
          AppCard(
            accent: pal.danger,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.error_outline, color: pal.danger),
              const SizedBox(width: 10),
              Expanded(child: Text(_submitError!, style: theme.bodySmall?.copyWith(color: pal.danger))),
            ]),
          ),
        ],
        if (_busy) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(
            _photoBytes == null ? 'Saving the manual report to Flask/MySQL…' : 'Uploading photo and waiting for server-side analysis…',
            style: theme.bodySmall?.copyWith(color: pal.muted),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _busy ? null : _submit,
          icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded),
          label: Text(_photoBytes == null ? 'Submit manual report' : 'Analyze photo & submit'),
        ),
        const SizedBox(height: 12),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text('Flask server address', style: theme.bodySmall),
          subtitle: Text('Default for this platform: ${WaterApiClient.defaultBaseUrl}', style: theme.bodySmall),
          children: [
            TextField(
              controller: _server,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'Base URL', hintText: 'http://10.0.2.2:5000'),
            ),
            const SizedBox(height: 8),
            Text('For a physical phone, use the computer’s LAN IP and port 5000.', style: theme.bodySmall),
          ],
        ),
      ]),
    );
  }

  Widget _manualFields(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            key: ValueKey('type_$_type'),
            initialValue: _type,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Issue type'),
            items: [for (final type in waterIssueTypes) DropdownMenuItem(value: type, child: Text(prettyStatus(labelOf(type))))],
            onChanged: (value) => setState(() => _type = value!),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            key: ValueKey('severity_$_severity'),
            initialValue: _severity,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Severity'),
            items: [for (final severity in waterSeverities) DropdownMenuItem(value: severity, child: Text(prettyStatus(severity)))],
            onChanged: (value) => setState(() => _severity = value!),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      TextFormField(
        controller: _rate,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'Estimated leak rate', suffixText: 'L/h'),
        onChanged: (_) => setState(() {}),
        validator: WaterService.validateRate,
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() {
            _rate.text = WaterService.defaultRateFor(_type).toStringAsFixed(0);
            _severity = WaterService.suggestSeverity(WaterService.defaultRateFor(_type));
          }),
          icon: const Icon(Icons.auto_fix_high, size: 18),
          label: Text('Use typical for ${labelOf(_type)} (~${WaterService.defaultRateFor(_type).toStringAsFixed(0)} L/h)'),
        ),
      ),
      TextFormField(
        controller: _desc,
        maxLines: 3,
        maxLength: 200,
        decoration: const InputDecoration(labelText: 'What is happening?'),
        validator: WaterService.validateDescription,
      ),
      const SizedBox(height: 4),
      Text('Typical rates are assumptions; adjust them to what you observe.', style: theme.bodySmall),
    ]);
  }

  Widget _photoCard(BuildContext context) {
    final palette = context.pal;
    final theme = Theme.of(context).textTheme;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Photo evidence', style: theme.titleSmall)),
          const StatusBadge(label: 'Optional', icon: Icons.photo_camera_outlined, tone: Tone.neutral),
        ]),
        const SizedBox(height: 4),
        Text('A photo lets the Flask server run the Gemini analysis and persist the generated incident.', style: theme.bodySmall),
        if (_photoBytes != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              _photoBytes!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => ColoredBox(
                color: palette.surfaceHigh,
                child: SizedBox(height: 120, child: Icon(Icons.broken_image_outlined, color: palette.muted)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text(_photoName ?? 'Selected photo', style: theme.bodySmall, overflow: TextOverflow.ellipsis)),
            TextButton.icon(onPressed: _busy ? null : _removePhoto, icon: const Icon(Icons.close, size: 16), label: const Text('Remove')),
          ]),
          if (_samplePhoto)  StatusBadge.source('sample'),
        ] else ...[
          const SizedBox(height: 12),
          Container(
            height: 86,
            width: double.infinity,
            decoration: BoxDecoration(color: palette.surfaceHigh, borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.add_a_photo_outlined, size: 30, color: palette.muted),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.tonalIcon(
            onPressed: _busy ? null : () => _pickPhoto(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: const Text('Choose photo'),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _pickPhoto(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: const Text('Take photo'),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : _useSamplePhoto,
            icon: const Icon(Icons.science_outlined, size: 18),
            label: const Text('Use saved sample'),
          ),
        ]),
      ]),
    );
  }
}
