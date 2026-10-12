import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'water_api_client.dart' show WaterApiException;

/// One evaluated PDF, as normalized by Flask `/api/evaluate`.
class EvaluationResult {
  final String fileName;
  final double score;
  final double maxScore;
  final String feedback;
  final String errors;
  final double? plagiarismScore;
  final bool plagiarismFlagged;
  final int? pages;

  const EvaluationResult({
    required this.fileName,
    required this.score,
    required this.maxScore,
    required this.feedback,
    required this.errors,
    required this.plagiarismScore,
    required this.plagiarismFlagged,
    required this.pages,
  });

  factory EvaluationResult.fromJson(Map<String, dynamic> json) {
    double? asDouble(Object? v) => v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '');
    final max = asDouble(json['maxScore']);
    return EvaluationResult(
      fileName: (json['fileName'] ?? 'submission.pdf').toString(),
      score: asDouble(json['score']) ?? 0,
      maxScore: (max == null || max <= 0) ? 10 : max,
      feedback: (json['feedback'] ?? '').toString(),
      errors: (json['errors'] ?? '').toString(),
      plagiarismScore: asDouble(json['plagiarismScore']),
      plagiarismFlagged: json['plagiarismFlagged'] == true,
      pages: (json['pages'] as num?)?.toInt(),
    );
  }
}

/// HTTP client for the Flask assignment evaluator (`/api/subjects`, `/api/evaluate`).
/// Uses the same base URL as the water API (both live in the same Flask app).
class SubmissionApiClient {
  final String baseUrl;
  final Duration timeout;

  /// Evaluation calls an LLM per PDF, so allow a long timeout.
  const SubmissionApiClient({required this.baseUrl, this.timeout = const Duration(minutes: 5)});

  Uri _uri(String path) {
    final base = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse('$base$path');
    if (base.isEmpty || uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const WaterApiException('Use a valid server URL, such as http://10.0.2.2:5000.');
    }
    return uri;
  }

  Future<Map<String, dynamic>> _send(http.BaseRequest request) async {
    final client = http.Client();
    try {
      final streamed = await client.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamed).timeout(timeout);
      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw WaterApiException('The server returned an unreadable response (HTTP ${response.statusCode}).', response.statusCode);
      }
      if (decoded is! Map) {
        throw WaterApiException('The server returned an unexpected response (HTTP ${response.statusCode}).', response.statusCode);
      }
      final data = Map<String, dynamic>.from(decoded);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw WaterApiException((data['message'] ?? data['error'] ?? 'Request failed').toString(), response.statusCode);
      }
      return data;
    } on TimeoutException {
      throw const WaterApiException('The evaluation server took too long to respond. Please retry.');
    } on WaterApiException {
      rethrow;
    } catch (error) {
      throw WaterApiException('Could not reach the Flask server: $error');
    } finally {
      client.close();
    }
  }

  Future<List<String>> getSubjects() async {
    final data = await _send(http.Request('GET', _uri('/api/subjects'))..headers['Accept'] = 'application/json');
    final subjects = data['subjects'];
    if (subjects is! List) throw const WaterApiException('The server did not return a subject list.');
    return subjects.map((e) => e.toString()).toList(growable: false);
  }

  /// Uploads a single PDF and returns the server's evaluation of it.
  Future<EvaluationResult> evaluate({
    required Uint8List bytes,
    required String fileName,
    required String subject,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/api/evaluate'))
      ..headers['Accept'] = 'application/json'
      ..fields['subject'] = subject
      ..files.add(http.MultipartFile.fromBytes('files', bytes, filename: fileName));
    final data = await _send(request);
    final results = data['results'];
    if (results is! List || results.isEmpty || results.first is! Map) {
      throw const WaterApiException('The server did not return an evaluation result.');
    }
    return EvaluationResult.fromJson(Map<String, dynamic>.from(results.first as Map));
  }
}
