import 'package:flutter/material.dart';
import '../../services/app_repository.dart';
import '../../services/water_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';

/// Student: report a water issue. Works fully offline; photo analysis only pre-fills the form.
class ReportWaterScreen extends StatefulWidget {
  const ReportWaterScreen({super.key});
  @override
  State<ReportWaterScreen> createState() => _ReportWaterScreenState();
}

class _ReportWaterScreenState extends State<ReportWaterScreen> {
  final _form = GlobalKey<FormState>();
  final _location = TextEditingController();
  final _rate = TextEditingController();
  final _hours = TextEditingController();
  final _desc = TextEditingController();
  final _server = TextEditingController(text: 'http://10.0.2.2:8000');
  String _type = 'leaking_tap';
  String _severity = 'low';
  String? _sourceLabel;
  String? _notice;
  bool _busy = false, _showImage = false;
  String? _submittedLocation;

  @override
  void dispose() {
    for (final c in [_location, _rate, _hours, _desc, _server]) {
      c.dispose();
    }
    super.dispose();
  }

  double? get _lph => double.tryParse(_rate.text.trim());
  double? get _hrs => double.tryParse(_hours.text.trim());

  void _apply(AnalysisOutcome o) {
    final r = o.result;
    setState(() {
      _type = r.issueType;
      _severity = r.severity;
      _rate.text = r.estimatedLitresPerHour.toStringAsFixed(r.estimatedLitresPerHour % 1 == 0 ? 0 : 1);
      if (r.description.isNotEmpty) {
        _desc.text = r.description.length > 200 ? r.description.substring(0, 200) : r.description;
      }
      _sourceLabel = r.label;
      _notice = o.notice;
      _showImage = true;
    });
  }

  Future<void> _useSample() async {
    setState(() => _busy = true);
    _apply(AnalysisOutcome(await const FixtureLeakAnalyzer().analyze()));
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _analyzeOnline() async {
    setState(() => _busy = true);
    final o = await WaterService.analyze(HttpLeakAnalyzer(_server.text.trim()));
    if (!mounted) return;
    _apply(o);
    setState(() => _busy = false);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final repo = RepositoryScope.of(context);
    try {
      final inc = await WaterService(repo).submitReport(
        location: _location.text, issueType: _type, severity: _severity,
        litresPerHour: _lph!, durationHours: _hrs!, description: _desc.text,
      );
      if (!mounted) return;
      setState(() => _submittedLocation = inc.locationName);
    } on ArgumentError catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${e.message}')));
    }
  }

  void _reset() {
    _form.currentState?.reset();
    for (final c in [_location, _rate, _hours, _desc]) {
      c.clear();
    }
    setState(() {
      _type = 'leaking_tap';
      _severity = 'low';
      _sourceLabel = null;
      _notice = null;
      _showImage = false;
      _submittedLocation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final est = (_lph != null && _hrs != null && _lph! >= 0 && _hrs! >= 0) ? _lph! * _hrs! : null;
    return ModuleScaffold(
      title: 'Report a water issue',
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _submittedLocation != null ? _success() : _formView(est),
      ),
    );
  }

  Widget _success() => Center(
        key: const ValueKey('done'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 220),
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: const Icon(Icons.check_circle, size: 64, color: AppColors.leaf),
            ),
            const SizedBox(height: 12),
            Text('Report submitted', style: Theme.of(context).textTheme.titleLarge),
            Text('"$_submittedLocation" is now open. See it under My activity; admins can see it in the priority queue.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _reset, child: const Text('Report another')),
          ]),
        ),
      );

  Widget _formView(double? est) => Form(
        key: _form,
        child: ListView(key: const ValueKey('form'), padding: const EdgeInsets.all(20), children: [
          const Text('Fill this in yourself, or start from a photo estimate and edit it.', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Photo estimate (optional)', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (_showImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(FixtureLeakAnalyzer.assetPath, height: 140, width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                  ),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  OutlinedButton.icon(onPressed: _busy ? null : _useSample, icon: const Icon(Icons.photo_outlined), label: const Text('Use sample photo')),
                  OutlinedButton.icon(onPressed: _busy ? null : _analyzeOnline, icon: const Icon(Icons.auto_awesome), label: const Text('Analyze with AI')),
                ]),
                if (_busy) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('AI server address', style: TextStyle(fontSize: 13)),
                  children: [TextField(controller: _server, decoration: const InputDecoration(hintText: 'http://10.0.2.2:8000'))],
                ),
                if (_sourceLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.amber),
                      const SizedBox(width: 6),
                      Expanded(child: Text(_sourceLabel!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                    ]),
                  ),
                if (_notice != null) Text(_notice!, style: const TextStyle(fontSize: 12, color: AppColors.coral)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _location, textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Location *', hintText: 'e.g. Hostel B washroom', border: OutlineInputBorder()),
            validator: (v) => WaterService.validateRequired(v, 'Location'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('type_$_type'), initialValue: _type,
            decoration: const InputDecoration(labelText: 'Issue type', border: OutlineInputBorder()),
            items: [for (final t in waterIssueTypes) DropdownMenuItem(value: t, child: Text(labelOf(t)))],
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('sev_$_severity'), initialValue: _severity,
            decoration: const InputDecoration(labelText: 'Severity', border: OutlineInputBorder()),
            items: [for (final t in waterSeverities) DropdownMenuItem(value: t, child: Text(t))],
            onChanged: (v) => setState(() => _severity = v!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _rate, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Estimated litres lost per hour *', border: const OutlineInputBorder(),
              helperText: 'Typical for ${labelOf(_type)}: ~${WaterService.defaultRateFor(_type).toStringAsFixed(0)} L/h',
              suffixIcon: TextButton(
                onPressed: () => setState(() {
                  _rate.text = WaterService.defaultRateFor(_type).toStringAsFixed(0);
                  _severity = WaterService.suggestSeverity(WaterService.defaultRateFor(_type));
                }),
                child: const Text('Use typical'),
              ),
            ),
            validator: WaterService.validateRate,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _hours, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Estimated duration so far (hours) *', border: OutlineInputBorder()),
            validator: WaterService.validateDuration,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _desc, maxLines: 3, maxLength: 200,
            decoration: const InputDecoration(labelText: 'Description *', border: OutlineInputBorder()),
            validator: WaterService.validateDescription,
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.water_drop, color: AppColors.forest),
              title: Text(est == null ? 'Estimated loss: —' : 'Estimated loss: ~${est.toStringAsFixed(0)} L'),
              subtitle: const Text('Estimate = litres per hour × hours, based on the values you entered.'),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.send), label: const Text('Submit report')),
        ]),
      );
}
