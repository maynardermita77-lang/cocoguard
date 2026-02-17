import 'dart:async';
import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Service to monitor network connectivity and API availability
class ConnectivityService {
  static ConnectivityService? _instance;
  static ConnectivityService get instance {
    _instance ??= ConnectivityService._();
    return _instance!;
  }

  ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  StreamController<bool>? _connectionController;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  bool _isOnline = true;
  bool _isApiAvailable = false;
  DateTime? _lastApiCheck;

  /// Stream of online status changes
  Stream<bool> get onlineStream {
    _connectionController ??= StreamController<bool>.broadcast();
    return _connectionController!.stream;
  }

  /// Current online status (network available)
  bool get isOnline => _isOnline;

  /// Check if API backend is reachable
  bool get isApiAvailable => _isApiAvailable;

  /// Check if we can use server-side prediction
  bool get canUseServerPrediction => _isOnline && _isApiAvailable;

  /// Initialize connectivity monitoring
  Future<void> init() async {
    developer.log('Initializing connectivity service...', name: 'Connectivity');

    // Check initial connectivity
    await _checkConnectivity();

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      result,
    ) async {
      await _handleConnectivityChange(result);
    });

    developer.log(
      'Connectivity initialized: online=$_isOnline, apiAvailable=$_isApiAvailable',
      name: 'Connectivity',
    );
  }

  /// Handle connectivity change events
  Future<void> _handleConnectivityChange(ConnectivityResult result) async {
    final previousOnline = _isOnline;

    // Check if connection is available (not none)
    _isOnline = result != ConnectivityResult.none;

    developer.log(
      'Connectivity changed: $result -> online=$_isOnline',
      name: 'Connectivity',
    );

    // If we came online, check API availability
    if (_isOnline && !previousOnline) {
      await checkApiAvailability();
    } else if (!_isOnline) {
      _isApiAvailable = false;
    }

    // Notify listeners
    _connectionController?.add(_isOnline);
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      // Handle both single and list return types for compatibility
      if (results is List) {
        _isOnline = (results as List).any((r) => r != ConnectivityResult.none);
      } else {
        _isOnline = results != ConnectivityResult.none;
      }

      if (_isOnline) {
        await checkApiAvailability();
      }
    } catch (e) {
      developer.log('Error checking connectivity: $e', name: 'Connectivity');
      _isOnline = false;
      _isApiAvailable = false;
    }
  }

  /// Check if the API backend is reachable
  Future<bool> checkApiAvailability() async {
    // Rate limit API checks (max once per 10 seconds)
    if (_lastApiCheck != null &&
        DateTime.now().difference(_lastApiCheck!) <
            const Duration(seconds: 10)) {
      return _isApiAvailable;
    }

    _lastApiCheck = DateTime.now();

    try {
      final baseUrl = ApiService.baseUrl;
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));

      _isApiAvailable = response.statusCode == 200;
      developer.log(
        'API availability check: $_isApiAvailable (status: ${response.statusCode})',
        name: 'Connectivity',
      );
    } catch (e) {
      developer.log('API not available: $e', name: 'Connectivity');
      _isApiAvailable = false;
    }

    return _isApiAvailable;
  }

  /// Force refresh connectivity status
  Future<void> refresh() async {
    await _checkConnectivity();
    _connectionController?.add(_isOnline);
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionController?.close();
    _connectionController = null;
  }
}
