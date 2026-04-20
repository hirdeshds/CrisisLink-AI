import 'dart:convert';

import 'package:http/http.dart' as http;

class SosApiService {
  const SosApiService({
    this.baseUrl = 'https://mahek2bhatia-crisislink.hf.space',
  });

  final String baseUrl;

  Future<SosSubmissionResponse> createSosReport(
    SosCreateRequest request,
  ) async {
    final payload = await _post('/api/sos/create', body: request.toJson());

    return SosSubmissionResponse.fromJson(payload);
  }

  Future<AdminStats> fetchAdminStats() async {
    final payload = await _get('/api/admin/stats');
    return AdminStats.fromJson(payload);
  }

  Future<List<IncidentSummary>> fetchLiveIncidents() async {
    final payload = await _getList('/api/admin/live-incidents');
    return payload.map(IncidentSummary.fromJson).toList();
  }

  Future<List<IncidentSummary>> fetchActiveIncidents() async {
    final payload = await _getList('/api/incidents/active');
    return payload.map(IncidentSummary.fromJson).toList();
  }

  Future<IncidentDetailsResponse> fetchIncidentDetails(
    String incidentId,
  ) async {
    final payload = await _get('/api/incidents/$incidentId');
    return IncidentDetailsResponse.fromJson(payload);
  }

  Future<IncidentAnalysis> analyzeIncident(String incidentId) async {
    final payload = await _get('/api/ai/analyze/$incidentId');
    return IncidentAnalysis.fromJson(payload);
  }

  Future<ResolveIncidentResponse> resolveIncident(String incidentId) async {
    final payload = await _post('/api/admin/resolve/$incidentId');
    return ResolveIncidentResponse.fromJson(payload);
  }

  Future<AssignmentResponse> assignResponder({
    required String responderId,
    required String incidentId,
  }) async {
    final payload = await _post(
      '/api/assign/to-incident',
      body: {'responder_id': responderId, 'incident_id': incidentId},
    );

    return AssignmentResponse.fromJson(payload);
  }

  Future<AssignmentResponse> releaseResponder(String responderId) async {
    final payload = await _post('/api/assign/release/$responderId');
    return AssignmentResponse.fromJson(payload);
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final response = await http.get(_buildUri(path));
    return _handleMapResponse(response);
  }

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    final response = await http.get(_buildUri(path));
    return _handleListResponse(response);
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await http.post(
      _buildUri(path),
      headers: const {'Content-Type': 'application/json'},
      body: body == null ? null : jsonEncode(body),
    );

    return _handleMapResponse(response);
  }

  Map<String, dynamic> _handleMapResponse(http.Response response) {
    final payload = _decodePayload(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return payload;
    }

    throw SosApiException(
      message:
          _extractErrorMessage(payload) ??
          'Unable to complete the request right now.',
      statusCode: response.statusCode,
    );
  }

  List<Map<String, dynamic>> _handleListResponse(http.Response response) {
    final payload = _decodeBody(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (payload is List) {
        return payload
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      return const <Map<String, dynamic>>[];
    }

    final errorPayload = payload is Map<String, dynamic>
        ? payload
        : <String, dynamic>{};

    throw SosApiException(
      message:
          _extractErrorMessage(errorPayload) ??
          'Unable to complete the request right now.',
      statusCode: response.statusCode,
    );
  }

  dynamic _decodeBody(String body) {
    if (body.isEmpty) {
      return null;
    }

    return jsonDecode(body);
  }

  Map<String, dynamic> _decodePayload(String body) {
    final decoded = _decodeBody(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return <String, dynamic>{};
  }

  String? _extractErrorMessage(Map<String, dynamic> payload) {
    final detail = payload['detail'];
    if (detail is String && detail.isNotEmpty) {
      return detail;
    }

    final message = payload['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }

    final details = payload['details'];
    if (details is String && details.isNotEmpty) {
      return details;
    }

    return null;
  }

  Uri _buildUri(String path) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }
}

class SosCreateRequest {
  const SosCreateRequest({
    required this.latitude,
    required this.longitude,
    required this.phoneNumber,
    required this.type,
  });

  final double latitude;
  final double longitude;
  final String phoneNumber;
  final String type;

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'phone_number': phoneNumber,
      'type': type,
    };
  }
}

class SosSubmissionResponse {
  const SosSubmissionResponse({
    required this.status,
    required this.incidentId,
    required this.uniqueReporters,
    required this.priority,
  });

  factory SosSubmissionResponse.fromJson(Map<String, dynamic> json) {
    return SosSubmissionResponse(
      status: (json['status'] ?? '').toString(),
      incidentId: (json['incident_id'] ?? '').toString(),
      uniqueReporters: _toInt(json['unique_reporters']),
      priority: (json['priority'] ?? '').toString(),
    );
  }

  final String status;
  final String incidentId;
  final int uniqueReporters;
  final String priority;
}

class AdminStats {
  const AdminStats({
    required this.active,
    required this.working,
    required this.resolved,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      active: _toInt(json['active']),
      working: _toInt(json['working']),
      resolved: _toInt(json['resolved']),
    );
  }

  final int active;
  final int working;
  final int resolved;
}

class IncidentSummary {
  const IncidentSummary({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.priority,
    required this.status,
    required this.reporterCount,
    required this.createdAt,
  });

  factory IncidentSummary.fromJson(Map<String, dynamic> json) {
    return IncidentSummary(
      id: (json['id'] ?? '').toString(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      type: (json['type'] ?? '').toString(),
      priority: (json['priority'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      reporterCount: _toInt(json['reporters'] ?? json['unique_reporters']),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }

  final String id;
  final double latitude;
  final double longitude;
  final String type;
  final String priority;
  final String status;
  final int reporterCount;
  final DateTime? createdAt;
}

class IncidentDetailsResponse {
  const IncidentDetailsResponse({required this.details, required this.reports});

  factory IncidentDetailsResponse.fromJson(Map<String, dynamic> json) {
    final detailMap = json['details'] is Map<String, dynamic>
        ? json['details'] as Map<String, dynamic>
        : <String, dynamic>{};
    final reportsList = json['reports'] is List
        ? json['reports'] as List<dynamic>
        : const <dynamic>[];

    return IncidentDetailsResponse(
      details: IncidentSummary.fromJson(detailMap),
      reports: reportsList
          .whereType<Map>()
          .map(
            (item) => IncidentReport.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }

  final IncidentSummary details;
  final List<IncidentReport> reports;
}

class IncidentReport {
  const IncidentReport({
    required this.phoneNumber,
    required this.reportType,
    required this.createdAt,
  });

  factory IncidentReport.fromJson(Map<String, dynamic> json) {
    return IncidentReport(
      phoneNumber: (json['phone_number'] ?? '').toString(),
      reportType: (json['report_type'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }

  final String phoneNumber;
  final String reportType;
  final DateTime? createdAt;
}

class IncidentAnalysis {
  const IncidentAnalysis({
    required this.predictedPriority,
    required this.uniqueReporters,
    required this.isSuspicious,
    required this.fraudReason,
    required this.requiredUnits,
    required this.teamType,
    required this.actionPlan,
    required this.equipment,
  });

  factory IncidentAnalysis.fromJson(Map<String, dynamic> json) {
    final analysis = json['analysis'] is Map<String, dynamic>
        ? json['analysis'] as Map<String, dynamic>
        : <String, dynamic>{};
    final fraud = analysis['fraud_check'] is Map<String, dynamic>
        ? analysis['fraud_check'] as Map<String, dynamic>
        : <String, dynamic>{};
    final recommendations = analysis['recommendations'] is Map<String, dynamic>
        ? analysis['recommendations'] as Map<String, dynamic>
        : <String, dynamic>{};
    final equipmentList = recommendations['equipment'] is List
        ? recommendations['equipment'] as List<dynamic>
        : const <dynamic>[];

    return IncidentAnalysis(
      predictedPriority: (analysis['predicted_priority'] ?? '').toString(),
      uniqueReporters: _toInt(analysis['unique_reporters']),
      isSuspicious: fraud['is_suspicious'] == true,
      fraudReason: (fraud['reason'] ?? '').toString(),
      requiredUnits: _toInt(recommendations['required_units']),
      teamType: (recommendations['team_type'] ?? '').toString(),
      actionPlan: (recommendations['action_plan'] ?? '').toString(),
      equipment: equipmentList.map((item) => item.toString()).toList(),
    );
  }

  final String predictedPriority;
  final int uniqueReporters;
  final bool isSuspicious;
  final String fraudReason;
  final int requiredUnits;
  final String teamType;
  final String actionPlan;
  final List<String> equipment;
}

class ResolveIncidentResponse {
  const ResolveIncidentResponse({required this.status, required this.message});

  factory ResolveIncidentResponse.fromJson(Map<String, dynamic> json) {
    return ResolveIncidentResponse(
      status: (json['status'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
    );
  }

  final String status;
  final String message;
}

class AssignmentResponse {
  const AssignmentResponse({
    required this.status,
    required this.responderId,
    this.incidentId,
  });

  factory AssignmentResponse.fromJson(Map<String, dynamic> json) {
    return AssignmentResponse(
      status: (json['status'] ?? '').toString(),
      responderId: (json['responder_id'] ?? '').toString(),
      incidentId: json['incident_id']?.toString(),
    );
  }

  final String status;
  final String responderId;
  final String? incidentId;
}

class SosApiException implements Exception {
  const SosApiException({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

int _toInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(Object? value) {
  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}
