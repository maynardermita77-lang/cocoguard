import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../services/api_service.dart';

/// Screen for reporting an unknown pest when detection returns OUT_OF_SCOPE.
///
/// Collects: image (auto-attached), optional notes, location on tree
/// (crown / leaves / trunk / soil / other), date-time (auto-filled).
class UnknownPestReportScreen extends StatefulWidget {
  final String imagePath;
  final Uint8List imageBytes;

  const UnknownPestReportScreen({
    super.key,
    required this.imagePath,
    required this.imageBytes,
  });

  @override
  State<UnknownPestReportScreen> createState() =>
      _UnknownPestReportScreenState();
}

class _UnknownPestReportScreenState extends State<UnknownPestReportScreen> {
  final _notesController = TextEditingController();
  String _treeLocation = 'leaves'; // default
  bool _isSubmitting = false;
  bool _submitted = false;
  String? _errorMessage;

  static const _treeLocations = <String, String>{
    'crown': 'Korona (Crown)',
    'leaves': 'Dahon (Leaves)',
    'trunk': 'Katawan (Trunk)',
    'soil': 'Lupa (Soil / Base)',
    'other': 'Iba pa (Other)',
  };

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final baseUrl = ApiService.baseUrl;
      final uri = Uri.parse('$baseUrl/predict/unknown-pest-report');

      final request = http.MultipartRequest('POST', uri);

      // Attach the image
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          widget.imageBytes,
          filename: 'unknown_pest.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      // Fields
      request.fields['notes'] = _notesController.text.trim();
      request.fields['tree_location'] = _treeLocation;
      request.fields['reported_at'] = DateTime.now().toIso8601String();

      // Auth token
      final token = ApiService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final streamed = await request.send().timeout(
        const Duration(seconds: 20),
      );
      final response = await http.Response.fromStream(streamed);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _submitted = true;
          _isSubmitting = false;
        });
      } else {
        final body = jsonDecode(response.body);
        setState(() {
          _errorMessage =
              body['detail'] ?? 'Hindi naipadala ang report. Subukan muli.';
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Network error: $e';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('I-report ang Hindi Kilalang Peste'),
        backgroundColor: const Color(0xFF2d7a3e),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _submitted ? _buildSuccessView() : _buildFormView(),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.check_circle, color: Color(0xFF2d7a3e), size: 80),
          const SizedBox(height: 20),
          const Text(
            'Naipadala na ang Report!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1b5e20),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Salamat sa pag-report. Susuriin ito ng PCA experts.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2d7a3e),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text(
              'Bumalik sa Home',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image preview
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            widget.imageBytes,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 20),

        // Explanation
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF90CAF9)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF1565C0)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hindi nakilala ang peste sa larawan. Kung sa tingin mo ay '
                  'coconut pest ito, i-fill out ang form na ito para sa '
                  'pagsusuri ng PCA experts.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1565C0),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Tree location dropdown
        const Text(
          'Saan sa puno nakita?',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1b5e20),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _treeLocation,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
          items: _treeLocations.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _treeLocation = v);
          },
        ),
        const SizedBox(height: 20),

        // Notes
        const Text(
          'Mga Karagdagang Detalye (Optional)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1b5e20),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Ilarawan ang nakita mo...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
        const SizedBox(height: 8),

        // Auto-filled timestamp
        Row(
          children: [
            const Icon(Icons.schedule, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text(
              'Petsa: ${_formatNow()}',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Error message
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),

        // Submit button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _isSubmitting ? null : _submitReport,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send, size: 20),
          label: Text(
            _isSubmitting ? 'Ipinapadala...' : 'Ipadala ang Report',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  String _formatNow() {
    final now = DateTime.now();
    return '${now.month}/${now.day}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }
}
