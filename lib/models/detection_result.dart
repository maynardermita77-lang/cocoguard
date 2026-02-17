/// Structured result from pest detection (online or offline).
///
/// 3-state classification:
///   ✅ DETECTED     – confidence ≥ 60 %  → reliable identification
///   ⚠️ UNCERTAIN    – confidence 45–60 % → possible pest, retake advised
///   ❓ OUT_OF_SCOPE – confidence < 45 %  → no recognizable pest
library;

/// The three possible detection states.
enum DetectionStatus {
  detected,
  uncertain,
  outOfScope;

  /// Parse from a backend / service string (case-insensitive).
  static DetectionStatus fromString(String value) {
    switch (value.toUpperCase().replaceAll('-', '_')) {
      case 'DETECTED':
        return DetectionStatus.detected;
      case 'UNCERTAIN':
        return DetectionStatus.uncertain;
      case 'OUT_OF_SCOPE':
        return DetectionStatus.outOfScope;
      default:
        return DetectionStatus.outOfScope;
    }
  }

  /// Display label shown to users.
  String get label {
    switch (this) {
      case DetectionStatus.detected:
        return 'Detected';
      case DetectionStatus.uncertain:
        return 'Uncertain';
      case DetectionStatus.outOfScope:
        return 'Out of Scope';
    }
  }
}

/// Full result payload from a single detection attempt.
class DetectionResult {
  /// One of: detected / uncertain / outOfScope.
  final DetectionStatus status;

  /// Identified pest type (null when outOfScope).
  final String? pestType;

  /// Scientific name of the identified pest (null when not identified).
  final String? scientificName;

  /// TTA-aggregated confidence percentage (0–100).
  final double confidence;

  /// Risk level string: High, Medium, Low, uncertain, out-of-scope.
  final String riskLevel;

  /// Advisory text for the farmer.
  final String? advisory;

  /// Human-readable message (e.g. "Possible pest detected…").
  final String? message;

  /// Retake guidance tips when status == uncertain.
  final List<String> retakeGuidance;

  /// Image quality metrics from preprocessing.
  final Map<String, dynamic> quality;

  /// All prediction entries from the model.
  final List<Map<String, dynamic>> predictions;

  /// Best-matching prediction (null when outOfScope).
  final Map<String, dynamic>? bestMatch;

  /// Whether this result came from offline inference.
  final bool offline;

  /// Number of TTA augmentations used.
  final int ttaAugmentations;

  const DetectionResult({
    required this.status,
    this.pestType,
    this.scientificName,
    required this.confidence,
    required this.riskLevel,
    this.advisory,
    this.message,
    this.retakeGuidance = const [],
    this.quality = const {},
    this.predictions = const [],
    this.bestMatch,
    this.offline = false,
    this.ttaAugmentations = 0,
  });

  /// Parse from the raw Map returned by OfflinePredictionService.predict()
  /// or the backend /predict response.
  factory DetectionResult.fromMap(Map<String, dynamic> map) {
    final status = DetectionStatus.fromString(
      map['status'] as String? ?? 'OUT_OF_SCOPE',
    );
    final bestMatch = map['best_match'] as Map<String, dynamic>?;

    return DetectionResult(
      status: status,
      pestType: bestMatch?['pest_type'] as String?,
      scientificName: bestMatch?['scientific_name'] as String?,
      confidence: _parseConfidence(bestMatch, map),
      riskLevel: map['risk_level'] as String? ?? 'out-of-scope',
      advisory: map['advisory'] as String?,
      message: map['message'] as String?,
      retakeGuidance: _parseStringList(map['retake_guidance']),
      quality: map['quality'] as Map<String, dynamic>? ?? {},
      predictions: _parsePredictions(map['predictions']),
      bestMatch: bestMatch,
      offline: map['offline'] as bool? ?? false,
      ttaAugmentations: map['tta_augmentations'] as int? ?? 0,
    );
  }

  /// Convert to a serializable Map.
  Map<String, dynamic> toMap() => {
    'status': status.name.toUpperCase(),
    'pest_type': pestType,
    'scientific_name': scientificName,
    'confidence': confidence,
    'risk_level': riskLevel,
    'advisory': advisory,
    'message': message,
    'retake_guidance': retakeGuidance,
    'quality': quality,
    'predictions': predictions,
    'best_match': bestMatch,
    'offline': offline,
    'tta_augmentations': ttaAugmentations,
  };

  /// Whether the detection is actionable (show pest details).
  bool get isDetected => status == DetectionStatus.detected;

  /// Whether the user should retake the photo.
  bool get shouldRetake => status == DetectionStatus.uncertain;

  /// Whether no pest was recognized at all.
  bool get isOutOfScope => status == DetectionStatus.outOfScope;

  // ────────────── Private helpers ──────────────

  static double _parseConfidence(
    Map<String, dynamic>? bestMatch,
    Map<String, dynamic> map,
  ) {
    if (bestMatch != null && bestMatch.containsKey('confidence')) {
      return (bestMatch['confidence'] as num).toDouble();
    }
    if (map.containsKey('confidence')) {
      return (map['confidence'] as num).toDouble();
    }
    return 0.0;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  static List<Map<String, dynamic>> _parsePredictions(dynamic value) {
    if (value is List) {
      return value.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }
}
