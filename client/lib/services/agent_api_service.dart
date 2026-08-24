import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ScoreBreakdown {
  final double safetyScore;
  final double classAlignmentScore;
  final double affordabilityScore;
  final double adherenceSimplicityScore;
  final double totalScore;

  ScoreBreakdown({
    required this.safetyScore,
    required this.classAlignmentScore,
    required this.affordabilityScore,
    required this.adherenceSimplicityScore,
    required this.totalScore,
  });

  factory ScoreBreakdown.fromJson(Map<String, dynamic> json) {
    return ScoreBreakdown(
      safetyScore: (json['safety_score'] as num?)?.toDouble() ?? 40.0,
      classAlignmentScore: (json['class_alignment_score'] as num?)?.toDouble() ?? 25.0,
      affordabilityScore: (json['affordability_score'] as num?)?.toDouble() ?? 20.0,
      adherenceSimplicityScore: (json['adherence_simplicity_score'] as num?)?.toDouble() ?? 15.0,
      totalScore: (json['total_score'] as num?)?.toDouble() ?? 100.0,
    );
  }
}

class TopDrugCandidate {
  final String drugId;
  final String drugName;
  final double totalScore;
  final int tier;
  final double estimatedCopay;
  final bool paRequired;
  final String recommendationReason;
  final ScoreBreakdown scoreBreakdown;

  TopDrugCandidate({
    required this.drugId,
    required this.drugName,
    required this.totalScore,
    required this.tier,
    required this.estimatedCopay,
    required this.paRequired,
    required this.recommendationReason,
    required this.scoreBreakdown,
  });

  factory TopDrugCandidate.fromJson(Map<String, dynamic> json) {
    return TopDrugCandidate(
      drugId: json['drug_id']?.toString() ?? '',
      drugName: json['drug_name']?.toString() ?? 'Alternative Candidate',
      totalScore: (json['total_score'] as num?)?.toDouble() ?? 100.0,
      tier: (json['tier'] as num?)?.toInt() ?? 1,
      estimatedCopay: (json['estimated_copay'] as num?)?.toDouble() ?? 10.0,
      paRequired: json['pa_required'] == true,
      recommendationReason: json['recommendation_reason']?.toString() ?? 'Formulary preferred alternative.',
      scoreBreakdown: json['score_breakdown'] is Map<String, dynamic>
          ? ScoreBreakdown.fromJson(json['score_breakdown'])
          : ScoreBreakdown(
              safetyScore: 40.0,
              classAlignmentScore: 25.0,
              affordabilityScore: 20.0,
              adherenceSimplicityScore: 15.0,
              totalScore: 100.0,
            ),
    );
  }
}

class TherapyEvaluationReport {
  final String patientId;
  final String actionDecision;
  final String summaryMessage;
  final TopDrugCandidate? topRecommendedDrug;

  TherapyEvaluationReport({
    required this.patientId,
    required this.actionDecision,
    required this.summaryMessage,
    this.topRecommendedDrug,
  });

  factory TherapyEvaluationReport.fromJson(Map<String, dynamic> json) {
    return TherapyEvaluationReport(
      patientId: json['patient_id']?.toString() ?? 'PAT_00402',
      actionDecision: json['action_decision']?.toString() ?? 'DISPENSE_PRIMARY',
      summaryMessage: json['summary_message']?.toString() ?? 'Evaluation completed.',
      topRecommendedDrug: json['top_recommended_drug'] is Map<String, dynamic>
          ? TopDrugCandidate.fromJson(json['top_recommended_drug'])
          : null,
    );
  }
}

class AgentApiService {
  final String baseUrl;

  AgentApiService({String? url})
      : baseUrl = url ?? 'http://localhost:8000';

  Future<Map<String, dynamic>?> sendMessage({
    required String message,
    String patientId = 'PAT_00402',
    String doctorId = 'DOC_001',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/chat/message');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'patient_id': patientId,
          'doctor_id': doctorId,
        }),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('[AgentApiService] Error sending message: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> checkHealth() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('[AgentApiService] Health check error: $e');
      return null;
    }
  }
}
