import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'management_strategies_screen.dart';
import 'feedback_screen.dart';

class ResultsScreen extends StatelessWidget {
  final String imagePath;
  final Uint8List imageBytes; // Required for image display
  final String detectedPest;
  final String scientificName;
  final String riskLevel;
  final String advisory;
  final double confidence;
  final List<String> retakeGuidance;

  const ResultsScreen({
    super.key,
    required this.imagePath,
    required this.imageBytes,
    this.detectedPest = 'Out-of-Scope Pest Instance',
    this.scientificName = '',
    this.riskLevel = 'out-of-scope',
    this.advisory =
        'Ang larawang ito ay hindi kabilang sa mga coconut pest na sinanay sa modelo.\n\n'
        'Ang CocoGuard ay nakatuon lamang sa pagtukoy ng mga sumusunod na peste ng niyog:\n'
        '• APW (Asiatic Palm Weevil)\n'
        '• Brontispa\n'
        '• Rhinoceros Beetle\n'
        '• Slug Caterpillar\n'
        '• White Grub\n\n'
        'Kung sa tingin mo ay coconut pest ito, mangyaring makipag-ugnayan sa PCA para sa ekspertong pagsusuri.',
    this.confidence = 0.0,
    this.retakeGuidance = const [],
  });

  /// Whether this result is in the UNCERTAIN band.
  bool get _isUncertain => riskLevel.toLowerCase() == 'uncertain';

  /// Whether this result is OUT_OF_SCOPE (no recognizable pest).
  bool get _isOutOfScope => riskLevel.toLowerCase() == 'out-of-scope';

  Color _getRiskColor() {
    switch (riskLevel.toLowerCase()) {
      case 'critical':
        return const Color(0xFFd32f2f);
      case 'high':
        return const Color(0xFFf57c00);
      case 'medium':
        return const Color(0xFFfbc02d);
      case 'low':
        return const Color(0xFF388e3c);
      case 'uncertain':
        return const Color(0xFFFFA000); // Amber for uncertain
      case 'out-of-scope':
        return const Color(0xFF1976D2); // Blue for out-of-scope
      default:
        return const Color(0xFF1976D2);
    }
  }

  String _getRiskLabel() {
    switch (riskLevel.toLowerCase()) {
      case 'critical':
        return 'KRITIKAL';
      case 'high':
        return 'MATAAS';
      case 'medium':
        return 'KATAMTAMAN';
      case 'low':
        return 'MABABA';
      case 'uncertain':
        return 'HINDI TIYAK';
      case 'out-of-scope':
        return 'OUT-OF-SCOPE';
      default:
        return 'OUT-OF-SCOPE';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Resulta ng Pagsusuri',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Image Area with overlay
            SizedBox(
              height: 340,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImageWidget(),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                  // Detection Target
                  Center(
                    child: CustomPaint(
                      size: const Size(280, 280),
                      painter: DetectionBoxPainter(color: _getRiskColor()),
                    ),
                  ),
                  // Bottom Info in Image
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRiskColor(),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getRiskLabel(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                detectedPest,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              if (scientificName.isNotEmpty)
                                Text(
                                  scientificName,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Details Section
            Container(
              transform: Matrix4.translationValues(0, -20, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),



                  // ── Retake Guidance (UNCERTAIN state) ──
                  if (_isUncertain && retakeGuidance.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1), // Light amber
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFE082)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.tips_and_updates,
                                  color: Color(0xFFF57F17),
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Mga Mungkahi para sa Mas Magandang Resulta',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF57F17),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...retakeGuidance.map(
                              (tip) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '• ',
                                      style: TextStyle(
                                        color: Color(0xFFF57F17),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        tip,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF5D4037),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_isUncertain && retakeGuidance.isNotEmpty)
                    const SizedBox(height: 16),

                  // Advisory Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PCA Advisory',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1b5e20),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F8E9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFC5E1A5)),
                          ),
                          child: Text(
                            advisory,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Color(0xFF33691E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Prominent retake button for UNCERTAIN results
                        if (_isUncertain)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFA000),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.camera_alt, size: 20),
                            label: const Text(
                              'Kumuha Muli ng Larawan',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (_isUncertain) const SizedBox(height: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2E7D32),
                            side: const BorderSide(color: Color(0xFF2E7D32)),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ManagementStrategiesScreen(
                                  pestName: detectedPest,
                                  scientificName: scientificName,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.menu_book, size: 20),
                          label: const Text(
                            'Gabay sa Pagkontrol',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (!_isUncertain)
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'I-scan Muli',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        // Report Unknown Pest — sends to existing Feedback & Reports
                        if (_isOutOfScope) ...[
                          const SizedBox(height: 4),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1565C0),
                              side: const BorderSide(color: Color(0xFF1565C0)),
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FeedbackScreen(
                                    initialType: 'Unknown Pest Report',
                                    initialMessage:
                                        'Na-scan ko ang isang peste ngunit hindi ito nakilala ng CocoGuard. '
                                        'Mangyaring suriin ang aking report.',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.report_outlined, size: 20),
                            label: const Text(
                              'I-report ang Hindi Kilalang Peste',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Add safe bottom padding for devices with notches
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    Widget errorWidget = Container(
      color: Colors.grey.shade900,
      child: const Icon(Icons.broken_image, color: Colors.white54, size: 80),
    );

    // Always use Image.memory with bytes for cross-platform support
    return Image.memory(
      imageBytes,
      fit: BoxFit.cover,
      errorBuilder: (c, o, s) => errorWidget,
    );
  }
}

class DetectionBoxPainter extends CustomPainter {
  final Color color;

  DetectionBoxPainter({this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final double length = 40;
    final double w = size.width;
    final double h = size.height;

    // Top Left
    canvas.drawLine(const Offset(0, 0), Offset(length, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, length), paint);

    // Top Right
    canvas.drawLine(Offset(w, 0), Offset(w - length, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, length), paint);

    // Bottom Left
    canvas.drawLine(Offset(0, h), Offset(length, h), paint);
    canvas.drawLine(Offset(0, h), Offset(0, h - length), paint);

    // Bottom Right
    canvas.drawLine(Offset(w, h), Offset(w - length, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - length), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
