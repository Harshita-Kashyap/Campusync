import 'package:flutter/material.dart';
import '../../services/app_repository.dart';
import '../../services/water_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';

/// Student: report a water issue. Works offline; photo analysis only pre-fills the form
/// and every field stays editable.
class ReportWaterScreen extends StatefulWidget {
  final VoidCallback? onDone;
  const ReportWaterScreen({super.key, this.onDone});
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
  LeakAnalysisResult? _result;
  String? _notice;
  bool _busy = false, _showImage = false, _aiRun = false;
  int _stage = 0;
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
      if (r.description.isNotEmpty) _desc.text = r.description.length > 200 ? r.description.substring(0, 200) : r.description;
      _result = r;
      _notice = o.notice;
      _showImage = true;
    });
  }

  Future<void> _useSample() async {
    setState(() {
      _busy = true;
      _aiRun = false;
      _showImage = true;
    });
    final r = await const FixtureLeakAnalyzer().analyze();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    _apply(AnalysisOutcome(r));
    setState(() => _busy = false);
  }

  Future<void> _analyzeOnline() async {
    setState(() {
      _busy = true;
      _aiRun = true;
      _stage = 0;
      _showImage = true;
      _result = null;
      _notice = null;
    });
    final job = WaterService.analyze(HttpLeakAnalyzer(_server.text.trim()));
    for (var s = 1; s <= 2; s++) {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      setState(() => _stage = s);
    }
    final o = await job;
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
      _result = null;
      _notice = null;
      _showImage = false;
      _submittedLocation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final est = (_lph != null && _hrs != null && _lph! >= 0 && _hrs! >= 0) ? _lph! * _hrs! : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Report a water issue'), actions: const [ThemeToggleButton(), SizedBox(width: 4)]),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: _submittedLocation != null ? _success(context) : _formView(context, est),
        ),
      ),
    );
  }

  Widget _success(BuildContext context) {
    final pal = context.pal;
    final t = Theme.of(context).textTheme;
    return Center(
      key: const ValueKey('done'),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 84, height: 84,
              decoration: BoxDecoration(color: pal.success.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(Icons.check_rounded, size: 46, color: pal.success),
            ),
          ),
          const SizedBox(height: 20),
          Text('Report submitted', style: t.headlineSmall),
          const SizedBox(height: 8),
          Text('"$_submittedLocation" is now open and in the admin priority queue.',
              textAlign: TextAlign.center, style: t.bodyLarge?.copyWith(color: pal.muted)),
          const SizedBox(height: 28),
          if (widget.onDone != null)
            FilledButton(
              onPressed: () {
                widget.onDone!();
                _reset();
              },
              child: const Text('View my activity'),
            ),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: _reset, child: const Text('Report another')),
        ]),
      ),
    );
  }

  Widget _formView(BuildContext context, double? est) {
    final pal = context.pal;
    final t = Theme.of(context).textTheme;
    return Form(
      key: _form,
      child: PageBody(key: const ValueKey('form'), children: [
        Text('Add a photo to start from an AI estimate, or fill this in yourself. You can edit everything.',
            style: t.bodyMedium?.copyWith(color: pal.muted)),
        const SizedBox(height: 16),
        _photoCard(context),
        const SectionHeading('Details'),
        TextFormField(
          controller: _location,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Location', hintText: 'e.g. Hostel B washroom'),
          validator: (v) => WaterService.validateRequired(v, 'Location'),
        ),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              key: ValueKey('type_$_type'),
              initialValue: _type,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Issue type'),
              items: [for (final x in waterIssueTypes) DropdownMenuItem(value: x, child: Text(prettyStatus(labelOf(x))))],
              onChanged: (v) => setState(() => _type = v!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              key: ValueKey('sev_$_severity'),
              initialValue: _severity,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Severity'),
              items: [for (final x in waterSeverities) DropdownMenuItem(value: x, child: Text(prettyStatus(x)))],
              onChanged: (v) => setState(() => _severity = v!),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: TextFormField(
              controller: _rate,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Litres per hour', suffixText: 'L/h'),
              validator: WaterService.validateRate,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _hours,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Hours so far', suffixText: 'h'),
              validator: WaterService.validateDuration,
            ),
          ),
        ]),
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
        const SizedBox(height: 4),
        TextFormField(
          controller: _desc,
          maxLines: 3,
          maxLength: 200,
          decoration: const InputDecoration(labelText: 'What is happening?'),
          validator: WaterService.validateDescription,
        ),
        const SectionHeading('Estimate'),
        AppCard(
          child: Row(children: [
            Icon(Icons.water_drop_outlined, color: pal.info),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (est == null)
                  Text('Estimated loss: —', style: t.titleMedium)
                else
                  AnimatedNumber(value: est, format: (v) => 'Estimated loss: ~${fmtNum(v)} L', style: t.titleMedium),
                Text('Litres per hour × hours, from the values you entered.', style: t.bodySmall),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.send_rounded), label: const Text('Submit report')),
      ]),
    );
  }

  Widget _photoCard(BuildContext context) {
    final pal = context.pal;
    final t = Theme.of(context).textTheme;
    final r = _result;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Photo estimate', style: t.titleSmall)),
          const StatusBadge(label: 'AI-assisted', icon: Icons.auto_awesome, tone: Tone.brand),
        ]),
        Text('Optional. Suggests the leak type, severity and flow for you to confirm.', style: t.bodySmall),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _showImage
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: Stack(fit: StackFit.expand, children: [
                        Image.asset(
                          FixtureLeakAnalyzer.assetPath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              ColoredBox(color: pal.surfaceHigh, child: Icon(Icons.image_not_supported_outlined, color: pal.muted)),
                        ),
                        if (_busy && _aiRun) const _ScanLine(),
                      ]),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 12),
        if (_busy && _aiRun)
          _Pipeline(stage: _stage)
        else
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.tonalIcon(
              onPressed: _busy ? null : _analyzeOnline,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Analyze with AI'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _useSample,
              icon: const Icon(Icons.photo_outlined, size: 18),
              label: const Text('Use saved sample'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
            ),
          ]),
        if (_busy && !_aiRun) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
        if (r != null && !_busy) ...[
          const SizedBox(height: 16),
          StatusBadge.source(r.source),
          const SizedBox(height: 8),
          Text(r.label, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          if (_notice != null)
            Padding(padding: const EdgeInsets.only(top: 6), child: Text(_notice!, style: t.bodySmall?.copyWith(color: pal.danger))),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text('How this estimate was made', style: t.titleSmall),
            children: [
              ExplainSteps(steps: [
                const ExplainStep(icon: Icons.photo_camera_outlined, title: 'A photo of the leak', detail: 'Added by you'),
                ExplainStep(
                  icon: r.isAi ? Icons.auto_awesome : Icons.science_outlined,
                  title: r.isAi ? 'A vision model suggests values' : 'A saved sample result is used',
                  detail: r.isAi ? 'Leak type, severity and litres per hour' : 'No live AI call was made',
                  tone: r.isAi ? Tone.brand : Tone.warning,
                ),
                const ExplainStep(icon: Icons.edit_outlined, title: 'You confirm or correct', detail: 'Every field stays editable'),
                const ExplainStep(icon: Icons.calculate_outlined, title: 'Loss = litres per hour × hours', detail: 'Same formula for every report'),
              ]),
            ],
          ),
        ],
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text('AI server address', style: t.bodySmall),
          children: [TextField(controller: _server, decoration: const InputDecoration(hintText: 'http://10.0.2.2:8000'))],
        ),
      ]),
    );
  }
}

/// Honest progress for the live AI call: what is being waited on, in order.
class _Pipeline extends StatelessWidget {
  final int stage;
  const _Pipeline({required this.stage});

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final t = Theme.of(context).textTheme;
    const labels = ['Sending the photo to the AI server', 'Vision model estimating type and flow', 'Checking the result'];
    return Column(children: [
      for (var i = 0; i < labels.length; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            SizedBox(
              width: 20, height: 20,
              child: i < stage
                  ? Icon(Icons.check_circle, size: 20, color: pal.success)
                  : (i == stage
                      ? CircularProgressIndicator(strokeWidth: 2.4, color: pal.brand)
                      : Icon(Icons.circle_outlined, size: 20, color: pal.line)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: (t.bodyMedium ?? const TextStyle()).copyWith(
                    color: i <= stage ? pal.ink : pal.muted, fontWeight: i == stage ? FontWeight.w600 : FontWeight.w400),
                child: Text(labels[i]),
              ),
            ),
          ]),
        ),
    ]);
  }
}

/// A thin line sweeping over the photo while the AI call is in flight.
class _ScanLine extends StatefulWidget {
  const _ScanLine();
  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.pal.heroAccent;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Align(
        alignment: Alignment(0, -1 + 2 * Curves.easeInOut.transform(_c.value)),
        child: Container(
          height: 3,
          decoration: BoxDecoration(color: color, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 12, spreadRadius: 1)]),
        ),
      ),
    );
  }
}
