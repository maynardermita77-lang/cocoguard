import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'results_screen.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/connectivity_service.dart';
import '../services/offline_prediction_service_web.dart'
    if (dart.library.io) '../services/offline_prediction_service.dart';
import '../services/offline_sync_service.dart';

class ProcessingScreen extends StatefulWidget {
  final String imagePath;
  final Uint8List imageBytes; // Required for upload

  const ProcessingScreen({
    super.key,
    required this.imagePath,
    required this.imageBytes,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _statusText = 'Sinusuring CocoGuard at ang larawan mo...';
  bool _isOfflineMode = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Actually call the pest detection API
    _detectPest();
  }

  Future<void> _detectPest() async {
    try {
      // Get current location address first
      setState(() {
        _statusText = 'Kinukuha ang lokasyon...';
      });

      String locationText = 'Unknown Location';
      try {
        locationText = await LocationService.getLocationAddress();
        debugPrint('📍 Location obtained: $locationText');
      } catch (e) {
        debugPrint('📍 Failed to get location: $e');
      }

      setState(() {
        _statusText = 'Sinusuri ang koneksyon...';
      });

      // Check if we can use server prediction
      final canUseServer = await ConnectivityService.instance
          .checkApiAvailability();

      if (canUseServer) {
        // Online mode - use server API
        await _detectPestOnline(locationText);
      } else {
        // Offline mode - use local TFLite model
        setState(() {
          _isOfflineMode = true;
          _statusText = 'Offline mode - Gumagamit ng lokal na modelo...';
        });
        await _detectPestOffline(locationText);
      }
    } catch (e) {
      // Network or other error - try offline mode
      if (mounted) {
        setState(() {
          _isOfflineMode = true;
          _statusText = 'Offline mode - Gumagamit ng lokal na modelo...';
        });
        try {
          await _detectPestOffline('Unknown Location');
        } catch (offlineError) {
          _showErrorAndNavigate('Error: $e');
        }
      }
    }
  }

  /// Online prediction using server API
  Future<void> _detectPestOnline(String locationText) async {
    setState(() {
      _statusText = 'Nag-aanalisa ng larawan...';
    });

    // Get the base URL
    final baseUrl = ApiService.baseUrl;
    final uri = Uri.parse('$baseUrl/predict');

    // Create multipart request
    var request = http.MultipartRequest('POST', uri);

    // Always use bytes for cross-platform support
    // Add content type for proper server-side validation
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        widget.imageBytes,
        filename: 'image.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    // Add optional parameters - use 0.55 (55%) threshold for YOLOv11-Seg model
    // Real coconut pests: 55%+ confidence (above 50% sigmoid baseline) → DETECTED
    // Images with no clear pest signal: <55% → OUT_OF_SCOPE
    request.fields['confidence_threshold'] = '0.55';
    request.fields['save_image'] = 'true';

    // Add location data (address only, no coordinates)
    request.fields['location_text'] = locationText;

    // Add auth token if available
    final token = ApiService.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    setState(() {
      _statusText = 'Tinutukoy ang uri ng peste...';
    });

    // Send request
    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
    );
    final response = await http.Response.fromStream(streamedResponse);

    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _handlePredictionResult(data, locationText, isOffline: false);
    } else {
      // API error - try offline mode as fallback
      setState(() {
        _isOfflineMode = true;
        _statusText = 'Server error - Gumagamit ng lokal na modelo...';
      });
      await _detectPestOffline(locationText);
    }
  }

  /// Offline prediction using local TFLite model
  Future<void> _detectPestOffline(String locationText) async {
    setState(() {
      _statusText = 'Nilo-load ang lokal na modelo...';
    });

    // Load the model if not already loaded
    final modelLoaded = await OfflinePredictionService.instance.loadModel();
    if (!modelLoaded) {
      _showErrorAndNavigate(
        'Hindi ma-load ang modelo para sa offline detection.',
      );
      return;
    }

    setState(() {
      _statusText = 'Nag-aanalisa ng larawan (offline)...';
    });

    // Run local prediction — the service handles thresholding internally:
    // 1. Low initial threshold (45%) catches real detections
    // 2. Post-filter minimum confidence (55%) rejects noise/false positives
    final result = await OfflinePredictionService.instance.predict(
      widget.imageBytes,
    );

    if (!mounted) return;

    // Handle the result
    _handlePredictionResult(result, locationText, isOffline: true);

    // Only queue DETECTED offline scans for sync to server.
    // UNCERTAIN and Out-of-Scope scans are saved to local history only.
    final status = (result['status'] ?? '').toString().toUpperCase();

    if (status == 'DETECTED' && result['best_match'] != null) {
      final bestMatch = result['best_match'];
      final pestType = bestMatch['pest_type'] ?? '';
      final confidence = (bestMatch['confidence'] ?? 0).toDouble();

      if (confidence >= 60.0) {
        await OfflineSyncService.instance.queueScanForSync(
          imageBytes: widget.imageBytes,
          pestType: pestType,
          confidence: confidence,
          riskLevel: result['risk_level'] ?? 'Medium',
          location: locationText,
          scannedAt: DateTime.now(),
        );
        debugPrint('📴 Offline DETECTED scan queued for sync: $pestType');
      }
    } else {
      debugPrint(
        '📴 $status offline scan — saved to local history only, no sync needed',
      );
    }
  }

  /// Handle prediction result from either online or offline source.
  ///
  /// 3-State flow:
  ///   ✅ DETECTED    → show pest details + advisory
  ///   ⚠️ UNCERTAIN   → show amber retake guidance
  ///   ❓ OUT_OF_SCOPE → show blue out-of-scope message
  void _handlePredictionResult(
    Map<String, dynamic> data,
    String locationText, {
    required bool isOffline,
  }) {
    // Defaults — safe OUT_OF_SCOPE fallback
    String detectedPest = 'Out-of-Scope Pest Instance';
    String scientificName = '';
    String riskLevel = 'out-of-scope';
    double confidence = 0.0;
    List<String> retakeGuidance = [];
    String advisory =
        'Ang larawang ito ay hindi kabilang sa mga coconut pest na sinanay sa modelo.\n\n'
        'Ang CocoGuard ay nakatuon lamang sa pagtukoy ng mga sumusunod na peste ng niyog:\n'
        '• APW (Asiatic Palm Weevil)\n'
        '• Brontispa\n'
        '• Rhinoceros Beetle\n'
        '• Slug Caterpillar\n'
        '• White Grub\n\n'
        'Kung sa tingin mo ay coconut pest ito, mangyaring makipag-ugnayan sa PCA para sa ekspertong pagsusuri.';

    final status = (data['status'] ?? '').toString().toUpperCase();
    final bestMatch = data['best_match'] as Map<String, dynamic>?;

    // Known pest list for validation
    const knownPests = [
      'APW Adult',
      'APW Larvae',
      'Brontispa',
      'Brontispa Pupa',
      'Rhinoceros Beetle',
      'Slug Caterpillar',
      'White Grub',
    ];

    if ((status == 'DETECTED' || status == 'UNCERTAIN') &&
        data['success'] == true &&
        bestMatch != null) {
      detectedPest = bestMatch['pest_type'] ?? 'Out-of-Scope Pest Instance';
      confidence = (bestMatch['confidence'] ?? 0).toDouble();

      if (!knownPests.contains(detectedPest)) {
        debugPrint(
          '⚠️ Unknown pest type "$detectedPest" - treating as out-of-scope',
        );
        detectedPest = 'Out-of-Scope Pest Instance';
        riskLevel = 'out-of-scope';
      } else if (status == 'UNCERTAIN') {
        // ⚠️ UNCERTAIN — possible pest, retake recommended
        riskLevel = 'uncertain';
        retakeGuidance = _parseRetakeGuidance(data['retake_guidance']);
        advisory =
            'Posibleng nakita ang: $detectedPest\n\n'
            'Hindi sapat ang confidence para sa maaasahang resulta. '
            'Subukang kumuha muli ng larawan ayon sa mga mungkahi sa ibaba.';
        scientificName = _getScientificName(detectedPest);
      } else if (confidence < 60.0) {
        // DETECTED but below 60% — treat as uncertain
        debugPrint(
          '⚠️ DETECTED at ${confidence.toStringAsFixed(1)}% < 60% '
          '— downgrading to uncertain',
        );
        riskLevel = 'uncertain';
        retakeGuidance = _parseRetakeGuidance(data['retake_guidance']);
        advisory =
            'Posibleng nakita ang: $detectedPest\n\n'
            'Mababa ang confidence. Subukang kumuha muli ng larawan.';
        scientificName = _getScientificName(detectedPest);
      } else {
        // ✅ DETECTED — reliable identification
        riskLevel = bestMatch['risk_level'] ?? data['risk_level'] ?? 'Medium';
        advisory = _getAdvisoryForPest(detectedPest, riskLevel);
        scientificName = _getScientificName(detectedPest);
      }
    }

    // Save to local history
    OfflineSyncService.instance.saveToLocalHistory(
      pestType: detectedPest,
      confidence: confidence,
      riskLevel: riskLevel,
      location: locationText,
      scannedAt: DateTime.now(),
      isOffline: isOffline,
    );

    // Navigate to results
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
            imagePath: widget.imagePath,
            imageBytes: widget.imageBytes,
            detectedPest: detectedPest,
            scientificName: scientificName,
            riskLevel: riskLevel,
            confidence: confidence,
            retakeGuidance: retakeGuidance,
            advisory: isOffline
                ? '$advisory\n\n📴 Nag-scan sa offline mode. Ang resulta ay i-sync kapag online na.'
                : advisory,
          ),
        ),
      );
    }
  }

  /// Parse retake guidance from raw response (may be List or null).
  List<String> _parseRetakeGuidance(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return [
      'Lumapit sa peste para sa mas malinaw na larawan.',
      'I-center ang peste sa gitna ng frame.',
      'Tiyaking sapat ang liwanag.',
    ];
  }

  void _showErrorAndNavigate(String error) {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          imagePath: widget.imagePath,
          imageBytes: widget.imageBytes,
          detectedPest: 'Out-of-Scope Pest Instance',
          scientificName: '',
          riskLevel: 'out-of-scope',
          advisory:
              'Hindi makapag-analyze ng larawan. $error\n\nSiguraduhing nakakonekta sa server at subukan ulit.',
        ),
      ),
    );
  }

  String _getScientificName(String pestType) {
    final scientificNames = {
      'APW Adult': 'Rhynchophorus ferrugineus',
      'APW Larvae': 'Rhynchophorus ferrugineus',
      'Brontispa': 'Brontispa longissima',
      'Brontispa Pupa': 'Brontispa longissima',
      'Rhinoceros Beetle': 'Oryctes rhinoceros',
      'Slug Caterpillar': 'Parasa lepida',
      'White Grub': 'Leucopholis irrorata',
    };
    return scientificNames[pestType] ?? '';
  }

  String _getAdvisoryForPest(String pestType, String riskLevel) {
    final advisories = {
      'APW Adult':
          'KRITIKAL: Ang Asiatic Palm Weevil ay mapanganib na peste! Agad na tanggalin ang mga apektadong bahagi ng puno. Gumamit ng pheromone traps at i-report sa PCA.',
      'APW Larvae':
          'KRITIKAL: Ang uod ng APW ay kumakain sa loob ng puno! Kailangan ng agarang aksyon. Kumunsulta sa PCA para sa chemical treatment.',
      'Brontispa':
          'MATAAS NA PANGANIB: Ang Brontispa ay sumisira sa mga dahon. Putulin at sunugin ang mga apektadong dahon. Gumamit ng biological control agents.',
      'Brontispa Pupa':
          'KATAMTAMAN: Nakita ang pupa ng Brontispa. Tanggalin ang mga apektadong dahon at sunugin. Regular na i-monitor ang puno.',
      'Rhinoceros Beetle':
          'KRITIKAL: Ang Rhinoceros Beetle ay nakakasira ng puno! Lagyan ng wire mesh ang tuktok ng puno. Gumamit ng pheromone traps at linisin ang paligid.',
      'Slug Caterpillar':
          'KATAMTAMAN: Ang Slug Caterpillar ay kumakain ng dahon. Manu-manong tanggalin o gumamit ng insecticide kung marami.',
      'White Grub':
          'MATAAS NA PANGANIB: Ang White Grub ay sumisira sa ugat. Gumamit ng soil treatment at tanggalin ang mga nabubulok na organic materials sa paligid.',
    };
    return advisories[pestType] ??
        'I-monitor ang puno at kumunsulta sa PCA kung may nakitang mga sintomas ng peste.';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background image with overlay
          Positioned.fill(
            child: Image.memory(
              widget.imageBytes,
              fit: BoxFit.cover,
              errorBuilder: (c, o, s) => Container(color: Colors.black87),
            ),
          ),
          Positioned.fill(
            child: Container(color: Color.fromRGBO(0, 0, 0, 0.5)),
          ),
          // Top spacing
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Offline mode indicator
                if (_isOfflineMode)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Offline Mode - Using Local Model',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 40),
                const Spacer(),
                // Processing card
                Container(
                  width: 320,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2d7a3e),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF7cb342),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated coconut tree icon
                      RotationTransition(
                        turns: _controller,
                        child: Container(
                          width: 100,
                          height: 100,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(255, 255, 255, 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.eco,
                            size: 70,
                            color: Color(0xFFe6b800),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _statusText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFe6b800),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tinutukoy kung anong peste ang sanhi ng pinsala.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFe6b800),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
