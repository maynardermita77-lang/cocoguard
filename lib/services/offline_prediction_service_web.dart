import 'package:flutter/foundation.dart';

/// Web stub for OfflinePredictionService
/// TFLite is not supported on web, so this always returns unsupported.
class OfflinePredictionService {
  static OfflinePredictionService? _instance;
  static OfflinePredictionService get instance {
    _instance ??= OfflinePredictionService._();
    return _instance!;
  }

  OfflinePredictionService._();

  bool get isModelLoaded => false;
  List<String> get labels => const [];

  Future<bool> loadModel() async {
    debugPrint('🤖 [TFLite] Not supported on web platform');
    return false;
  }

  Future<Map<String, dynamic>> predict(
    Uint8List imageBytes, {
    double confidenceThreshold = 0.55,
  }) async {
    return {
      'success': false,
      'status': 'ERROR',
      'error':
          'Offline prediction is not supported on web. Please use online mode.',
      'predictions': [],
      'best_match': null,
      'risk_level': 'out-of-scope',
      'offline': true,
    };
  }

  void dispose() {}
}
