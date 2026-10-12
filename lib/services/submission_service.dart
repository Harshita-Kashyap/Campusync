import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import '../models/models.dart';
import 'app_repository.dart';
import 'submission_api_client.dart';

/// A demo document the student can "submit" (no file picker needed, works offline).
class SampleDocument {
  final String fileName, text;
  final int pages;
  const SampleDocument(this.fileName, this.pages, this.text);
  int get words => text.trim().split(RegExp(r'\s+')).length;
  int get sections => text.split('\n').where((l) => l.startsWith('#')).length;
}

/// Prototype: SHA-256 duplicate check + a transparent grading rule. Person 4's final
/// rules can replace [grade] without touching the UI.
class SubmissionService {
  final AppRepository repo;
  const SubmissionService(this.repo);

  static const samples = [
    SampleDocument('lab_report_water_audit.pdf', 6, '''# Aim
To measure water wasted by dripping taps in the hostel block.
# Method
We counted drops per minute at ten taps and converted the rate to litres per hour using a measuring cylinder over five minutes at each tap.
# Results
Four taps leaked at more than two litres per hour. The worst tap lost about five litres per hour, which is over one hundred litres a day if left overnight.
# Conclusion
A weekly tap check and quick repairs would save thousands of litres each month at almost no cost.'''),
    SampleDocument('essay_draft.pdf', 3, 'Saving energy on campus matters because small habits add up. Switching off fans and lights when a room is empty is simple, and it cuts both cost and emissions.'),
    SampleDocument('os_assignment_2.pdf', 10, '''# Question 1
Explain process scheduling and compare round robin with shortest job first, using a small example with four processes.
# Question 2
Describe how paging avoids external fragmentation and what a page table stores for each page.
# Question 3
Explain deadlock and the four conditions that must hold together for it to occur, with one real example.'''),
  ];

  static String sha256Of(String text) => crypto.sha256.convert(utf8.encode(text)).toString();

  /// Prototype rule, out of 10: 4 base + up to 4 for length (60 words each) + up to 2 for structure.
  static ({double score, String feedback}) grade(SampleDocument d) {
    final len = (d.words / 60).clamp(0, 4).toDouble();
    final structure = d.sections.clamp(0, 2).toDouble();
    final score = ((4 + len + structure) * 2).round() / 2;
    final notes = <String>[
      if (d.sections == 0) 'Add headings to structure the answer' else 'Clear headings',
      if (d.words < 120) 'Needs more detail' else 'Good level of detail',
    ];
    return (score: score.clamp(0, 10).toDouble(), feedback: '${notes.join('. ')}.');
  }

  Future<DigitalSubmission> submit(SampleDocument d, {String studentId = 'S-demo', String assignmentId = 'CS-A1'}) async {
    final hash = sha256Of(d.text);
    final dup = repo.getSubmissions().any((s) => s.sha256 == hash);
    final g = grade(d);
    final n = repo.getSubmissions().length + 1;
    final sub = DigitalSubmission(
      id: 'ECO-SUB-${n.toString().padLeft(4, '0')}',
      studentId: studentId,
      assignmentId: assignmentId,
      fileName: d.fileName,
      sha256: hash,
      submittedAt: DateTime.now(),
      score: g.score,
      maxScore: 10,
      gradingFeedback: dup ? 'Identical to an earlier submission. Sent for review.' : g.feedback,
      pagesAvoidedEstimate: dup ? 0 : d.pages,
      duplicateDetected: dup,
    );
    await repo.addSubmission(sub);
    return sub;
  }

  /// Submit a real PDF: the Flask evaluator scores it; the SHA-256 of the uploaded
  /// bytes is still checked locally so exact re-uploads are flagged even offline.
  Future<DigitalSubmission> submitEvaluated({
    required Uint8List bytes,
    required String fileName,
    required String baseUrl,
    required String subject,
    String studentId = 'S-demo',
    String assignmentId = 'CS-A1',
  }) async {
    final hash = crypto.sha256.convert(bytes).toString();
    final exactDuplicate = repo.getSubmissions().any((s) => s.sha256 == hash);
    final r = await SubmissionApiClient(baseUrl: baseUrl).evaluate(bytes: bytes, fileName: fileName, subject: subject);
    final dup = exactDuplicate || r.plagiarismFlagged;
    final n = repo.getSubmissions().length + 1;
    final feedback = [
      if (exactDuplicate) 'Identical file was already submitted.',
      if (r.feedback.isNotEmpty) r.feedback,
      if (r.errors.isNotEmpty) r.errors,
    ].join(' ');
    final sub = DigitalSubmission(
      id: 'ECO-SUB-${n.toString().padLeft(4, '0')}',
      studentId: studentId,
      assignmentId: assignmentId,
      fileName: fileName,
      sha256: hash,
      submittedAt: DateTime.now(),
      score: r.score,
      maxScore: r.maxScore,
      gradingFeedback: feedback.isEmpty ? 'Evaluated by the server.' : feedback,
      // Page count is only known if the evaluator reports it; never invent one.
      pagesAvoidedEstimate: dup ? 0 : (r.pages ?? 0),
      duplicateDetected: dup,
      source: 'api',
      plagiarismScore: r.plagiarismScore,
    );
    await repo.addSubmission(sub);
    return sub;
  }
}
