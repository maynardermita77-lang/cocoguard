import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import '../../services/api_service.dart';
import '../../services/user_service.dart';

class FeedbackScreen extends StatefulWidget {
  /// Optional pre-selected report type (e.g. 'Unknown Pest Report').
  final String? initialType;

  /// Optional pre-filled message body.
  final String? initialMessage;

  const FeedbackScreen({super.key, this.initialType, this.initialMessage});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  late final Connectivity _connectivity;
  late final Stream<ConnectivityResult> _connectivityStream;
  late final StreamSubscription<ConnectivityResult> _subscription;
  // initState moved above (after _selectedType declaration) to support pre-fill

  @override
  void dispose() {
    _subscription.cancel();
    _feedbackController.dispose();
    super.dispose();
  }

  // Helper to queue feedback for offline sync
  Future<void> _queueFeedback(Map<String, dynamic> feedback) async {
    final box = Hive.box('cocoguard');
    final List<dynamic> queue =
        box.get('feedback_queue', defaultValue: []) as List<dynamic>;
    queue.add(feedback);
    await box.put('feedback_queue', queue);
  }

  // Helper to sync queued feedback when online
  Future<void> _syncFeedbackQueue() async {
    final box = Hive.box('cocoguard');
    final List<dynamic> queue =
        box.get('feedback_queue', defaultValue: []) as List<dynamic>;
    if (queue.isEmpty) return;
    final token = ApiService.getToken();
    for (final feedback in List<Map<String, dynamic>>.from(queue)) {
      try {
        final response = await http.post(
          Uri.parse('${ApiService.baseUrl}/feedback'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
          body: jsonEncode(feedback),
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          queue.remove(feedback);
        }
      } catch (_) {}
    }
    await box.put('feedback_queue', queue);
    // Optionally, show a message if feedback was synced
    if (mounted && queue.isEmpty) {
      setState(() {
        _submitMessage = 'All queued feedback submitted!';
      });
    }
  }

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;
  String? _submitMessage;

  // Add report type options
  final List<String> _reportTypes = [
    'General Feedback',
    'Bug Report',
    'Feature Request',
    'Account Issue',
    'Unknown Pest Report',
    'Other',
  ];
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _connectivityStream = _connectivity.onConnectivityChanged;
    _subscription = _connectivityStream.listen((result) async {
      if (result != ConnectivityResult.none) {
        await _syncFeedbackQueue();
      }
    });

    // Pre-fill from constructor params (e.g. unknown pest report)
    if (widget.initialType != null &&
        _reportTypes.contains(widget.initialType)) {
      _selectedType = widget.initialType;
    }
    if (widget.initialMessage != null) {
      _feedbackController.text = widget.initialMessage!;
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _submitMessage = null;
    });
    final feedbackData = {
      'type': _selectedType ?? '',
      'message': _feedbackController.text,
      'user_id': UserService.user.value.id,
    };
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;
    if (isOnline) {
      bool success = false;
      try {
        final token = ApiService.getToken();
        final response = await http.post(
          Uri.parse('${ApiService.baseUrl}/feedback'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
          body: jsonEncode(feedbackData),
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          success = true;
          setState(() {
            _submitMessage = 'Feedback submitted successfully!';
            _feedbackController.clear();
            _selectedType = null;
          });
          // Try to sync any queued feedback
          await _syncFeedbackQueue();
        } else {
          setState(() {
            _submitMessage =
                'Failed to submit feedback. Server error: ${response.statusCode}';
          });
        }
      } catch (e) {
        // Only queue and show error if not already successful
        if (!success) {
          await _queueFeedback(feedbackData);
          setState(() {
            _submitMessage =
                'Feedback could not be sent (network error). Queued for sync when online.';
          });
        }
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    } else {
      // Offline: queue feedback
      await _queueFeedback(feedbackData);
      setState(() {
        _submitMessage = 'Feedback queued for sync when online.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Type of Report',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                items: _reportTypes
                    .map(
                      (type) => DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select report type',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a report type.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Your Feedback',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _feedbackController,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your feedback here...',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your feedback.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  child: _isSubmitting
                      ? const CircularProgressIndicator()
                      : const Text('Submit'),
                ),
              ),
              if (_submitMessage != null) ...[
                const SizedBox(height: 16),
                Text(_submitMessage!, style: TextStyle(color: Colors.green)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
