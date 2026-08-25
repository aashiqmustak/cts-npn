import 'package:flutter/foundation.dart';

class ApiConfig {
  static final ApiConfig instance = ApiConfig._();
  ApiConfig._();

  /// Resolves the active backend base URL dynamically.
  /// - In production (port 80 / standard Nginx reverse proxy): uses the same origin (single URL for both frontend & backend)
  /// - In development (port 8080): routes API requests to backend port 8000
  String get baseUrl {
    if (kIsWeb) {
      final port = Uri.base.port;
      // When served on default HTTP/HTTPS ports (80 or 443), NGINX reverse-proxies /api/ directly
      if (port == 80 || port == 443 || port == 0) {
        return Uri.base.origin.isNotEmpty ? Uri.base.origin : 'http://100.56.240.156';
      }
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : '100.56.240.156';
      final protocol = Uri.base.scheme.isNotEmpty ? Uri.base.scheme : 'http';
      return '$protocol://$host:8000';
    }
    return 'http://100.56.240.156:8000';
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
