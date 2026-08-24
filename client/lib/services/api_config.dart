import 'package:flutter/foundation.dart';

class ApiConfig {
  static final ApiConfig instance = ApiConfig._();
  ApiConfig._();

  /// Resolves the active backend base URL dynamically based on browser location
  String get baseUrl {
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : '127.0.0.1';
      // In web, if browsing on localhost or custom domain, route to backend port 8000
      final protocol = Uri.base.scheme.isNotEmpty ? Uri.base.scheme : 'http';
      return '$protocol://$host:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  /// AI Agent endpoints
  String get ocrUploadEndpoint => '$baseUrl/api/v1/prescription/upload-ocr';
  String get orchestratorEvaluateEndpoint => '$baseUrl/api/v1/orchestrate/evaluate-prescription';
  String get chatMessageEndpoint => '$baseUrl/api/v1/chat/message';
  String get healthEndpoint => '$baseUrl/health';
  String get formularyEndpoint => '$baseUrl/api/v1/formulary';
  String get paEndpoint => '$baseUrl/api/v1/pa';
  String get alternativesEndpoint => '$baseUrl/api/v1/alternatives';
  String get clinicalTelemetryEndpoint => '$baseUrl/api/v1/clinical';
}
