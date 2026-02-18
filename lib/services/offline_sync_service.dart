import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'api_service.dart';
import 'connectivity_service.dart';

/// Service to queue offline scans and sync them when back online
class OfflineSyncService {
  static OfflineSyncService? _instance;
  static OfflineSyncService get instance {
    _instance ??= OfflineSyncService._();
    return _instance!;
  }

  OfflineSyncService._();

  static const String _pendingScansKey = 'pending_offline_scans';
  static const String _scanHistoryKey = 'offline_scan_history';

  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _periodicSyncTimer;
  bool _isSyncing = false;

  // Callbacks for sync status
  void Function(int pending)? onPendingScanCountChanged;
  void Function(bool success, String message)? onSyncComplete;

  /// Initialize the sync service
  Future<void> init() async {
    developer.log('Initializing offline sync service...', name: 'OfflineSync');

    // Listen for connectivity changes to trigger sync
    _connectivitySubscription = ConnectivityService.instance.onlineStream
        .listen((isOnline) {
          developer.log(
            'Connectivity changed: online=$isOnline',
            name: 'OfflineSync',
          );
          if (isOnline) {
            developer.log('Back online - triggering sync', name: 'OfflineSync');
            // Delay sync slightly to ensure connection is stable
            Future.delayed(const Duration(seconds: 2), () {
              syncPendingScans();
            });
          }
        });

    // Start periodic sync check (every 30 seconds when online)
    _periodicSyncTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final pendingCount = await getPendingScanCount();
      if (pendingCount > 0 && ConnectivityService.instance.isOnline) {
        developer.log(
          'Periodic sync check: $pendingCount pending scans',
          name: 'OfflineSync',
        );
        syncPendingScans();
      }
    });

    final pendingCount = await getPendingScanCount();
    developer.log('Pending scans to sync: $pendingCount', name: 'OfflineSync');

    // Try to sync immediately if online and has pending scans
    if (pendingCount > 0 && ConnectivityService.instance.isOnline) {
      developer.log(
        'Already online with pending scans - syncing now',
        name: 'OfflineSync',
      );
      Future.delayed(const Duration(seconds: 3), () {
        syncPendingScans();
      });
    }
  }

  /// Save scan result for later sync to server
  Future<void> queueScanForSync({
    required Uint8List imageBytes,
    required String pestType,
    required double confidence,
    required String riskLevel,
    required String location,
    required DateTime scannedAt,
  }) async {
    developer.log('Queueing scan for sync: $pestType', name: 'OfflineSync');

    final box = Hive.box('cocoguard');

    // Get existing pending scans
    final pendingRaw = box.get(_pendingScansKey, defaultValue: []);
    final List<Map<String, dynamic>> pending = List<Map<String, dynamic>>.from(
      (pendingRaw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );

    // Add new scan (store image as base64 for persistence)
    pending.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'image_base64': base64Encode(imageBytes),
      'pest_type': pestType,
      'confidence': confidence,
      'risk_level': riskLevel,
      'location': location,
      'scanned_at': scannedAt.toIso8601String(),
      'synced': false,
    });

    await box.put(_pendingScansKey, pending);

    developer.log(
      'Scan queued. Total pending: ${pending.length}',
      name: 'OfflineSync',
    );
    onPendingScanCountChanged?.call(pending.length);
  }

  /// Get count of pending scans
  Future<int> getPendingScanCount() async {
    final box = Hive.box('cocoguard');
    final pendingRaw = box.get(_pendingScansKey, defaultValue: []);
    final pending = pendingRaw as List;
    return pending.where((scan) => !(scan['synced'] ?? false)).length;
  }

  /// Sync all pending scans to server
  Future<void> syncPendingScans() async {
    // CRITICAL: Set _isSyncing IMMEDIATELY before any async work
    // to prevent race conditions from multiple triggers
    // (connectivity listener, periodic timer, init check)
    if (_isSyncing) {
      developer.log('Sync already in progress', name: 'OfflineSync');
      return;
    }
    _isSyncing = true;

    try {
      // Check if API is available
      final canSync = await ConnectivityService.instance.checkApiAvailability();
      if (!canSync) {
        developer.log('API not available, skipping sync', name: 'OfflineSync');
        return;
      }

      developer.log('Starting sync of pending scans...', name: 'OfflineSync');

      final box = Hive.box('cocoguard');
      final pendingRaw = box.get(_pendingScansKey, defaultValue: []);
      final List<Map<String, dynamic>> pending =
          List<Map<String, dynamic>>.from(
            (pendingRaw as List).map(
              (e) => Map<String, dynamic>.from(e as Map),
            ),
          );

      if (pending.isEmpty) {
        developer.log('No pending scans to sync', name: 'OfflineSync');
        return;
      }

      int successCount = 0;
      int failCount = 0;

      for (final scan in pending) {
        if (scan['synced'] == true) continue;

        // Mark as syncing BEFORE sending to prevent double-sync
        // if another trigger fires during the network call
        scan['syncing'] = true;
        await box.put(_pendingScansKey, pending);

        try {
          final success = await _syncSingleScan(scan);
          if (success) {
            scan['synced'] = true;
            scan['syncing'] = false;
            // Persist immediately after each successful sync
            await box.put(_pendingScansKey, pending);
            successCount++;
          } else {
            scan['syncing'] = false;
            failCount++;
          }
        } catch (e) {
          scan['syncing'] = false;
          developer.log('Error syncing scan: $e', name: 'OfflineSync');
          failCount++;
        }
      }

      // Clean up: remove synced scans from storage
      final unsynced = pending.where((s) => s['synced'] != true).toList();
      await box.put(_pendingScansKey, unsynced);

      developer.log(
        'Sync complete: $successCount synced, $failCount failed, ${unsynced.length} remaining',
        name: 'OfflineSync',
      );

      onPendingScanCountChanged?.call(unsynced.length);
      onSyncComplete?.call(
        failCount == 0,
        '$successCount scans synced${failCount > 0 ? ', $failCount failed' : ''}',
      );
    } catch (e) {
      developer.log('Sync error: $e', name: 'OfflineSync');
      onSyncComplete?.call(false, 'Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync a single scan to the server
  Future<bool> _syncSingleScan(Map<String, dynamic> scan) async {
    try {
      final imageBytes = base64Decode(scan['image_base64'] as String);
      final baseUrl = ApiService.baseUrl;
      final uri = Uri.parse('$baseUrl/predict');

      var request = http.MultipartRequest('POST', uri);

      // Add image
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'offline_scan.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      // Add metadata
      request.fields['confidence_threshold'] = '0.30';
      request.fields['save_image'] = 'true';
      request.fields['location_text'] = scan['location'] ?? 'Unknown Location';
      request.fields['offline_scan'] = 'true';
      request.fields['original_scan_time'] =
          scan['scanned_at'] ?? DateTime.now().toIso8601String();

      // Add auth token
      final token = ApiService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        developer.log('Scan synced successfully', name: 'OfflineSync');
        return true;
      } else {
        developer.log(
          'Sync failed with status: ${response.statusCode}',
          name: 'OfflineSync',
        );
        return false;
      }
    } catch (e) {
      developer.log('Error syncing scan: $e', name: 'OfflineSync');
      return false;
    }
  }

  /// Save scan to local history (for offline viewing)
  Future<void> saveToLocalHistory({
    required String pestType,
    required double confidence,
    required String riskLevel,
    required String location,
    required DateTime scannedAt,
    required bool isOffline,
    String? imagePath,
  }) async {
    final box = Hive.box('cocoguard');

    final historyRaw = box.get(_scanHistoryKey, defaultValue: []);
    final List<Map<String, dynamic>> history = List<Map<String, dynamic>>.from(
      (historyRaw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );

    // Add new scan to beginning
    history.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'pest_type': pestType,
      'confidence': confidence,
      'risk_level': riskLevel,
      'location': location,
      'scanned_at': scannedAt.toIso8601String(),
      'is_offline': isOffline,
      'image_path': imagePath,
    });

    // Keep only last 100 scans locally
    if (history.length > 100) {
      history.removeRange(100, history.length);
    }

    await box.put(_scanHistoryKey, history);
    developer.log('Scan saved to local history', name: 'OfflineSync');
  }

  /// Get local scan history
  Future<List<Map<String, dynamic>>> getLocalHistory() async {
    final box = Hive.box('cocoguard');
    final historyRaw = box.get(_scanHistoryKey, defaultValue: []);
    return List<Map<String, dynamic>>.from(
      (historyRaw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  /// Clear all pending scans (for testing/reset)
  Future<void> clearPendingScans() async {
    final box = Hive.box('cocoguard');
    await box.delete(_pendingScansKey);
    onPendingScanCountChanged?.call(0);
  }

  /// Manually trigger sync (can be called from UI)
  Future<void> triggerSync() async {
    developer.log('Manual sync triggered', name: 'OfflineSync');
    await ConnectivityService.instance.refresh();
    if (ConnectivityService.instance.isOnline) {
      await syncPendingScans();
    } else {
      developer.log('Cannot sync - still offline', name: 'OfflineSync');
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
  }
}
