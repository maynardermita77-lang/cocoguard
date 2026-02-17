import 'dart:async';
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../services/offline_sync_service.dart';

/// Widget that displays offline status and pending sync count
class OfflineIndicator extends StatefulWidget {
  const OfflineIndicator({super.key});

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  bool _isOnline = true;
  int _pendingScans = 0;
  StreamSubscription<bool>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _isOnline = ConnectivityService.instance.isOnline;
    _loadPendingCount();

    // Listen for connectivity changes
    _connectivitySubscription = ConnectivityService.instance.onlineStream
        .listen((isOnline) {
          if (mounted) {
            setState(() {
              _isOnline = isOnline;
            });
            if (isOnline) {
              _loadPendingCount();
            }
          }
        });

    // Listen for sync updates
    OfflineSyncService.instance.onPendingScanCountChanged = (count) {
      if (mounted) {
        setState(() {
          _pendingScans = count;
        });
      }
    };
  }

  Future<void> _loadPendingCount() async {
    final count = await OfflineSyncService.instance.getPendingScanCount();
    if (mounted) {
      setState(() {
        _pendingScans = count;
      });
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _syncNow() async {
    await OfflineSyncService.instance.triggerSync();
  }

  @override
  Widget build(BuildContext context) {
    // Only show when offline or has pending scans
    if (_isOnline && _pendingScans == 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _isOnline && _pendingScans > 0 ? _syncNow : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _isOnline
              ? const Color(0xFF2d7a3e).withValues(alpha: 0.9)
              : Colors.orange.shade700.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isOnline ? Icons.cloud_sync : Icons.cloud_off,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              _isOnline
                  ? '$_pendingScans pending • Tap to sync'
                  : 'Offline Mode${_pendingScans > 0 ? ' • $_pendingScans pending' : ''}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_isOnline && _pendingScans > 0) ...[
              const SizedBox(width: 8),
              const Icon(Icons.sync, color: Colors.white, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact offline badge for app bars
class OfflineBadge extends StatefulWidget {
  const OfflineBadge({super.key});

  @override
  State<OfflineBadge> createState() => _OfflineBadgeState();
}

class _OfflineBadgeState extends State<OfflineBadge> {
  bool _isOnline = true;
  StreamSubscription<bool>? _subscription;

  @override
  void initState() {
    super.initState();
    _isOnline = ConnectivityService.instance.isOnline;
    _subscription = ConnectivityService.instance.onlineStream.listen((
      isOnline,
    ) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.shade700,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text(
            'Offline',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
