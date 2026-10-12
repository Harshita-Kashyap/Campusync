import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:http/http.dart' as http;

import '../models/water_incident.dart';

/// HTTP client for the Flask water service.
///
/// Configure the default with `--dart-define=WATER_API_URL=http://host:5000`.
/// Android emulators use 10.0.2.2; desktop/web use loopback. Physical devices
/// should use the development computer's LAN IP instead.
class WaterApiClient {
  static const String _configuredBaseUrl = String.fromEnvironment('WATER_API_URL');
  static String get defaultBaseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:5000';
    return 'http://127.0.0.1:5000';
  }

  final String baseUrl;
  final Duration timeout;
  final http.Client? _providedClient;

  WaterApiClient({
    String? baseUrl,
    this.timeout = const Duration(seconds: 120),
    http.Client? client,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        _providedClient = client;

  Uri _uri(String path) {
    final base = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    if (base.isEmpty) throw const WaterApiException('Enter the Flask server address.');
    final uri = Uri.tryParse('$base$path');
    if (uri == null || !uri.hasScheme || uri.host.isEmpty || !{'http', 'https'}.contains(uri.scheme)) {
      throw const WaterApiException('Use a valid server URL, such as http://10.0.2.2:5000.');
    }
    return uri;
  }

  Future<http.Response> _send(http.BaseRequest request) async {
    final client = _providedClient ?? http.Client();
    try {
      final streamed = await client.send(request).timeout(timeout);
      return await http.Response.fromStream(streamed).timeout(timeout);
    } on TimeoutException {
      throw const WaterApiException('The water server took too long to respond. Please retry.');
    } on WaterApiException {
      rethrow;
    } catch (error) {
      throw WaterApiException('Could not reach the Flask server: $error');
    } finally {
      if (_providedClient == null) client.close();
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
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
      final message = (data['message'] ?? data['error'] ?? 'Request failed').toString();
      throw WaterApiException(message, response.statusCode);
    }
    return data;
  }

  Future<bool> healthCheck() async {
    final request = http.Request('GET', _uri('/health'))..headers['Accept'] = 'application/json';
    final data = _decode(await _send(request));
    return data['status'] == 'ok' && data['database'] == 'connected';
  }

  Future<List<WaterIncident>> getIncidents() async {
    final request = http.Request('GET', _uri('/api/water/incidents'))..headers['Accept'] = 'application/json';
    final data = _decode(await _send(request));
    final rows = data['incidents'];
    if (rows is! List) throw const WaterApiException('The server did not return an incidents list.');
    return rows.map((row) => WaterIncident.fromJson(Map<String, dynamic>.from(row as Map))).toList(growable: false);
  }

  /// Uploads an image and lets Flask analyze + save it, or creates a manual
  /// incident when [imageBytes] is omitted.
  Future<WaterIncident> createIncident({
    required String location,
    required double durationHours,
    Uint8List? imageBytes,
    String? imageName,
    String? reporterNote,
    String? issueType,
    String? severity,
    double? litresPerHour,
    String? description,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/api/water/incidents'));
    request.fields.addAll({
      'location': location.trim(),
      'estimatedDurationHours': durationHours.toString(),
    });

    if (imageBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: (imageName == null || imageName.isEmpty) ? 'leak-photo.jpg' : imageName,
      ));
      if (reporterNote != null && reporterNote.trim().isNotEmpty) {
        request.fields['reporterNote'] = reporterNote.trim();
      }
    } else {
      if (issueType == null || severity == null || litresPerHour == null || description == null) {
        throw const WaterApiException('A manual report needs issue type, severity, rate, and description.');
      }
      request.fields.addAll({
        'issueType': issueType,
        'severity': severity,
        'estimatedLitresPerHour': litresPerHour.toString(),
        'description': description.trim(),
      });
    }

    final data = _decode(await _send(request));
    final incident = data['incident'];
    if (incident is! Map) throw const WaterApiException('The server did not return the saved incident.');
    return WaterIncident.fromJson(Map<String, dynamic>.from(incident));
  }

  Future<WaterIncident> updateStatus(String incidentId, String status) async {
    final request = http.Request('PATCH', _uri('/api/water/incidents/$incidentId/status'))
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'application/json'
      ..body = jsonEncode({'status': status});
    final data = _decode(await _send(request));
    final incident = data['incident'];
    if (incident is! Map) throw const WaterApiException('The server did not return the updated incident.');
    return WaterIncident.fromJson(Map<String, dynamic>.from(incident));
  }

  String absoluteUrl(String relativeOrAbsoluteUrl) {
    final value = relativeOrAbsoluteUrl.trim();
    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) return value;
    return _uri(value.startsWith('/') ? value : '/$value').toString();
  }
}

class WaterApiException implements Exception {
  final String message;
  final int? statusCode;
  const WaterApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}
