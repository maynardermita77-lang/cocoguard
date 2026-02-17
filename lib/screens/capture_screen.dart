import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'processing_screen.dart';

class CaptureScreen extends StatefulWidget {
  final String imagePath;
  final Uint8List imageBytes; // Required for image display

  const CaptureScreen({
    super.key,
    required this.imagePath,
    required this.imageBytes,
  });

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  @override
  void initState() {
    super.initState();
    // Automatically navigate to processing screen after a brief preview
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ProcessingScreen(
              imagePath: widget.imagePath,
              imageBytes: widget.imageBytes,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image preview
          Positioned.fill(child: _buildImagePreview()),
          // Detection box overlay with corner style
          Positioned.fill(child: CustomPaint(painter: DetectionBoxPainter())),
          // Loading indicator overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF4CAF50),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Analyzing image...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    Widget errorWidget = Container(
      color: Colors.black,
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.white, size: 80),
      ),
    );

    // Always use Image.memory with bytes for cross-platform support
    return Image.memory(
      widget.imageBytes,
      fit: BoxFit.cover,
      errorBuilder: (c, o, s) => errorWidget,
    );
  }
}

class DetectionBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          const Color(0xFF4CAF50) // Green color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // Detection box centered in the middle
    final boxWidth = size.width * 0.6;
    final boxHeight = size.height * 0.35;
    final left = (size.width - boxWidth) / 2;
    final top = (size.height - boxHeight) / 2;

    final cornerLength = 30.0;

    // Draw corners only (not full rectangle)
    // Top-left corner
    canvas.drawLine(Offset(left, top + cornerLength), Offset(left, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), paint);

    // Top-right corner
    canvas.drawLine(
      Offset(left + boxWidth - cornerLength, top),
      Offset(left + boxWidth, top),
      paint,
    );
    canvas.drawLine(
      Offset(left + boxWidth, top),
      Offset(left + boxWidth, top + cornerLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(left, top + boxHeight - cornerLength),
      Offset(left, top + boxHeight),
      paint,
    );
    canvas.drawLine(
      Offset(left, top + boxHeight),
      Offset(left + cornerLength, top + boxHeight),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(left + boxWidth - cornerLength, top + boxHeight),
      Offset(left + boxWidth, top + boxHeight),
      paint,
    );
    canvas.drawLine(
      Offset(left + boxWidth, top + boxHeight - cornerLength),
      Offset(left + boxWidth, top + boxHeight),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
