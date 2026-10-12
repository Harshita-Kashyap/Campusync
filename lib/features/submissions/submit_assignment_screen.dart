import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/app_repository.dart';
import '../../services/submission_api_client.dart';
import '../../services/submission_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/widgets.dart';

class SubmitAssignmentScreen extends StatefulWidget {
  final VoidCallback? onDone;
  const SubmitAssignmentScreen({super.key, this.onDone});
  @override
  State<SubmitAssignmentScreen> createState() =>
      _SubmitAssignmentScreenState();
}
class _SubmitAssignmentScreenState extends State<SubmitAssignmentScreen>
    with SingleTickerProviderStateMixin {
  int _pick = 0;
  int _stage = 0;
  bool _busy = false;
  DigitalSubmission? _result;
  String? _error;
  // Real-PDF flow (Flask /api/evaluate). When no file is picked, the offline samples are used.
  PlatformFile? _file;
  String _subject = 'DBMS';
  List<String> _subjects = const ['DBMS'];
  String? _subjectsNotice;
  late final AnimationController _successController;
  static const _stages = [
    'Preparing your assignment',
    'Sending submission details',
    'Recording your submission',
    'Confirming receipt',
  ];
  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }
  bool _subjectsRequested = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_subjectsRequested) {
      _subjectsRequested = true;
      _loadSubjects();
    }
  }
  Future<void> _loadSubjects() async {
    final repo = RepositoryScope.of(context);
    try {
      final subjects = await SubmissionApiClient(baseUrl: repo.waterApiBaseUrl).getSubjects();
      if (!mounted || subjects.isEmpty) return;
      setState(() {
        _subjects = subjects;
        if (!subjects.contains(_subject)) _subject = subjects.first;
        _subjectsNotice = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _subjectsNotice = 'Could not load subjects from the server ($error). Offline samples still work.');
    }
  }
  Future<void> _pickPdf() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: true, // bytes are needed on web/mobile; there is no usable path there
      );
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.first;
      if (file.bytes == null) {
        setState(() => _error = 'Could not read that file. Try another PDF.');
        return;
      }
      if (file.size > 10 * 1024 * 1024) {
        setState(() => _error = 'Choose a PDF smaller than 10 MB.');
        return;
      }
      setState(() {
        _file = file;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Could not open the file picker: $error');
    }
  }
  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }
  Future<void> _submit() async {
    final repo = RepositoryScope.of(context);
    setState(() {
      _busy = true;
      _stage = 0;
      _result = null;
      _error = null;
    });
    try {
      if (_file == null) {
        for (var i = 0; i < _stages.length; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 350));
          if (!mounted) return;
          setState(() => _stage = i + 1);
        }
      } else {
        setState(() => _stage = 1); // the server call below is the real work
      }
      final file = _file;
      final service = SubmissionService(repo);
      final result = file != null
          ? await service.submitEvaluated(
              bytes: file.bytes!,
              fileName: file.name,
              baseUrl: repo.waterApiBaseUrl,
              subject: _subject,
            )
          : await service.submit(SubmissionService.samples[_pick]);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _result = result;
      });
      _successController.forward(from: 0);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _file != null
            ? 'Submission was not evaluated: $error'
            : 'We could not complete your submission. Please try again.';
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = theme.textTheme;
    final pal = context.pal;
    final colors = theme.colorScheme;
    final result = _result;
    final sample = SubmissionService.samples[_pick];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit assignment'),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: PageBody(
          children: [
            // Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.onPrimaryContainer.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.upload_file_rounded,
                      color: colors.onPrimaryContainer,
                      size: 27,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Your work, submitted simply.',
                    style: t.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hand in your assignment digitally and help '
                    'reduce unnecessary paper on campus.',
                    style: t.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 17),
                  Row(
                    children: [
                      Icon(
                        Icons.eco_outlined,
                        size: 18,
                        color: colors.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Every digital submission is a step forward.',
                          style: t.labelMedium?.copyWith(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const SectionHeading('Upload your PDF'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.picture_as_pdf_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _file?.name ?? 'No PDF selected',
                        style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_file != null)
                      IconButton(
                        tooltip: 'Remove file',
                        onPressed: _busy || result != null ? null : () => setState(() => _file = null),
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ]),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('subject_$_subject${_subjects.length}'),
                    initialValue: _subject,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Subject'),
                    items: [for (final s in _subjects) DropdownMenuItem(value: s, child: Text(s))],
                    onChanged: _busy || result != null ? null : (v) => setState(() => _subject = v ?? _subject),
                  ),
                  if (_subjectsNotice != null) ...[
                    const SizedBox(height: 8),
                    Text(_subjectsNotice!, style: t.bodySmall?.copyWith(color: colors.error)),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy || result != null ? null : _pickPdf,
                    icon: const Icon(Icons.folder_open_rounded),
                    label: Text(_file == null ? 'Choose PDF' : 'Choose a different PDF'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The PDF is sent to the Flask server for AI scoring and a similarity check.',
                    style: t.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeading('Or try an offline sample'),
            Text(
              _file == null
                  ? 'Select the sample file you want to submit (works without the server).'
                  : 'A PDF is selected, so the samples below are ignored. Remove the PDF to use them.',
              style: t.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            for (var i = 0;
                i < SubmissionService.samples.length;
                i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AssignmentCard(
                  fileName: SubmissionService.samples[i].fileName,
                  pages: SubmissionService.samples[i].pages,
                  words: SubmissionService.samples[i].words,
                  selected: _file == null && _pick == i,
                  enabled: !_busy && result == null,
                  onTap: () {
                    setState(() {
                      _pick = i;
                      _file = null;
                      _error = null;
                    });
                  },
                ),
              ),
            if (!_busy && result == null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text('Submit assignment'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
            // Submission progress
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _busy
                  ? Padding(
                      key: const ValueKey('progress'),
                      padding: const EdgeInsets.only(top: 18),
                      child: _ProgressCard(
                        stage: _stage,
                        stages: _stages,
                      ),
                    )
                  : const SizedBox.shrink(
                      key: ValueKey('no-progress'),
                    ),
            ),
            // Error
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: colors.onErrorContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: t.bodyMedium?.copyWith(
                          color: colors.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Student sees a receipt, not an admin review.
            if (result != null) ...[
              const SizedBox(height: 24),
              const SectionHeading('Submission receipt'),
              _ReceiptCard(
                fileName: result.fileName,
                submissionId: result.id,
                pages: result.pagesAvoidedEstimate > 0 ? result.pagesAvoidedEstimate : (_file == null ? sample.pages : 0),
                controller: _successController,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: widget.onDone,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    widget.onDone == null
                        ? 'Submission complete'
                        : 'Go to My Activity',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    _successController.reset();
                    setState(() {
                      _result = null;
                      _error = null;
                    });
                  },
                  child: const Text('Submit another assignment'),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const DemoNote(),
          ],
        ),
      ),
    );
  }
}
class _AssignmentCard extends StatelessWidget {
  final String fileName;
  final int pages;
  final int words;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  const _AssignmentCard({
    required this.fileName,
    required this.pages,
    required this.words,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pal = context.pal;
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: selected
            ? colors.secondaryContainer
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? colors.primary : colors.outlineVariant,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 54,
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.surface
                        : colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.description_rounded,
                    size: 27,
                    color: selected ? colors.primary : colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: t.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$pages pages  ·  $words words',
                        style: t.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Selected for submission',
                          style: t.labelSmall?.copyWith(
                            color: colors.onSecondaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    key: ValueKey(selected),
                    color: selected ? colors.primary : colors.outline,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _ProgressCard extends StatelessWidget {
  final int stage;
  final List<String> stages;
  const _ProgressCard({
    required this.stage,
    required this.stages,
  });
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pal = context.pal;
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Submitting your assignment',
                  style: t.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: stage / stages.length,
              minHeight: 6,
              backgroundColor: colors.surfaceContainerHighest,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < stages.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Icon(
                    i < stage
                        ? Icons.check_circle_rounded
                        : i == stage
                            ? Icons.radio_button_checked_rounded
                            : Icons.circle_outlined,
                    size: 20,
                    color: i < stage
                        ? colors.tertiary
                        : i == stage
                            ? colors.primary
                            : colors.outline,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      stages[i],
                      style: t.bodyMedium?.copyWith(
                        color: i <= stage ? colors.onSurface : colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
class _ReceiptCard extends StatelessWidget {
  final String fileName;
  final String submissionId;
  final int pages;
  final AnimationController controller;
  final bool evaluated;
  const _ReceiptCard({
    required this.fileName,
    required this.submissionId,
    required this.pages,
    required this.controller,
    this.evaluated = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pal = context.pal;
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          ScaleTransition(
            scale: CurvedAnimation(
              parent: controller,
              curve: Curves.elasticOut,
            ),
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: colors.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: colors.primary,
                size: 38,
              ),
            ),
          ),
          const SizedBox(height: 17),
          Text(
            'Assignment received!',
            textAlign: TextAlign.center,
            style: t.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            evaluated ? 'Your PDF was evaluated by the server.' : 'Your submission has been recorded in the demo.',            textAlign: TextAlign.center,
            style: t.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          const Divider(),
          const SizedBox(height: 12),
          _ReceiptRow(
            label: 'Assignment',
            value: fileName,
          ),
          const SizedBox(height: 12),
          _ReceiptRow(
            label: 'Reference',
            value: submissionId,
          ),
          const SizedBox(height: 12),
          if (pages > 0) ...[
            _ReceiptRow(
              label: 'Length',
              value: '$pages pages',
            ),
            const SizedBox(height: 16),
          ] else
            const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.secondaryContainer,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              'Your submission can now be reviewed by the administrator.',
              style: t.bodySmall?.copyWith(
                color: colors.onSecondaryContainer,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReceiptRow({
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pal = context.pal;
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: t.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: t.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
