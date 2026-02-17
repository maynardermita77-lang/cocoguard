import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../services/api_endpoints.dart';
import '../../services/api_service.dart';
import '../../services/translation_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;
  String? _error;

  // Filtering state
  late List<Map<String, dynamic>> _filteredRecords;
  final Set<String> _selectedPests = {};

  Map<String, List<Map<String, dynamic>>> _groupRecordsByDate() {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (var r in _filteredRecords) {
      final key = DateFormat('dd MMMM').format(r['date'] as DateTime);
      groups.putIfAbsent(key, () => []).add(r);
    }
    return groups;
  }

  @override
  void initState() {
    super.initState();
    _filteredRecords = [];
    _searchController.addListener(_applyFilters);
    _loadScans();
  }

  Future<void> _loadScans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final scans = await ScansApi.getScans();

      if (mounted) {
        setState(() {
          _records = scans.map((scan) {
            // Backend returns: id, tree_code, date_time, location_text, pest_type, risk_level, confidence, status, image_url
            // Parse the date - backend stores in UTC
            DateTime scanDate;
            try {
              final dateStr =
                  scan['date_time'] ??
                  scan['scan_date'] ??
                  DateTime.now().toIso8601String();
              // Parse as UTC then convert to local time
              // DateTime.parse returns local time, but backend sends UTC
              // So we create a UTC datetime and convert to local
              final parsed = DateTime.parse(dateStr);
              // Treat parsed as UTC (since MySQL stores UTC) and convert to local
              final asUtc = DateTime.utc(
                parsed.year,
                parsed.month,
                parsed.day,
                parsed.hour,
                parsed.minute,
                parsed.second,
              );
              scanDate = asUtc.toLocal();
            } catch (e) {
              scanDate = DateTime.now();
            }

            return {
              'id': scan['id'].toString(),
              'treeId': scan['tree_code'] ?? scan['tree_id'] ?? '----',
              'date': scanDate,
              'location':
                  scan['location_text'] ??
                  scan['location'] ??
                  'Unknown Location',
              'pest':
                  scan['pest_type'] ??
                  scan['pest_type_name'] ??
                  'Out-of-Scope Pest Instance',
              'image': scan['image_url'] ?? 'assets/images/thumb.png',
              'risk_level': scan['risk_level'] ?? 'out-of-scope',
            };
          }).toList();
          _filteredRecords = List<Map<String, dynamic>>.from(_records);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _confirmDeleteScan(Map<String, dynamic> r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('history.delete_scan')),
        content: Text(
          '${tr('history.delete_scan')} #${r['id']}? ${tr('history.delete_confirm_msg')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              tr('common.delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ScansApi.deleteScan(int.parse(r['id'].toString()));
        if (mounted) {
          setState(() {
            _records.removeWhere((rec) => rec['id'] == r['id']);
            _applyFilters();
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(tr('history.scan_deleted'))));
        }
        return true;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete scan: $e')));
        }
        return false;
      }
    }
    return false;
  }

  void _applyFilters() {
    final q = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredRecords = _records.where((r) {
        final location = (r['location'] ?? '').toString().toLowerCase();
        final pest = (r['pest'] ?? '').toString().toLowerCase();

        if (q.isNotEmpty) {
          if (!(location.contains(q) || pest.contains(q))) {
            return false;
          }
        }

        if (_selectedPests.isNotEmpty) {
          if (!_selectedPests.contains(r['pest'])) return false;
        }

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupRecordsByDate();

    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'assets/images/splash_bg.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Positioned.fill(
            child: Container(color: Color.fromRGBO(0, 0, 0, 0.35)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr('history.title'),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _loadScans,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => _applyFilters(),
                    decoration: InputDecoration(
                      hintText: tr('history.search_hint'),
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Loading or Error State
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    )
                  else if (_error != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              tr('history.error_loading'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadScans,
                              child: Text(tr('common.retry')),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_records.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.inbox_outlined,
                              color: Colors.white,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              tr('history.no_history'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tr('history.start_scanning'),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFe6f3d9),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_filteredRecords.length}',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2d7a3e),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    tr('history.total_scans'),
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2d7a3e),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color.fromRGBO(0, 0, 0, 0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '176',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    tr('history.total_trees'),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Filters (pest chips + severity chips)
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        // Pest chips
                        for (var pest in AppConstants.pestTypes)
                          ChoiceChip(
                            label: Text(
                              pest,
                              style: const TextStyle(fontSize: 10),
                            ),
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            selected: _selectedPests.contains(pest),
                            onSelected: (v) {
                              setState(() {
                                if (v) {
                                  _selectedPests.add(pest);
                                } else {
                                  _selectedPests.remove(pest);
                                }
                                _applyFilters();
                              });
                            },
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // List grouped by date
                    for (var entry in groups.entries) ...[
                      const SizedBox(height: 8),
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (var r in entry.value)
                        Dismissible(
                          key: Key(r['id'].toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          confirmDismiss: (_) => _confirmDeleteScan(r),
                          onDismissed: (_) {},
                          child: _buildRecordCard(r),
                        ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> r) {
    final date = r['date'] as DateTime;
    final scanId = r['id'] ?? '---';
    final location = r['location'] ?? tr('history.unknown_location');
    final pest = r['pest'] ?? tr('history.unknown_pest');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _showFullScreenImage(
                  r['image'] as String,
                  r['pest'] ?? 'Scan',
                  r['id']?.toString() ?? '',
                ),
                child: Hero(
                  tag: 'scan_image_${r['id']}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildImageWidget(r['image'] as String),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scan ID - prominently displayed at top
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2d7a3e).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${tr('history.scan_id')}: $scanId',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2d7a3e),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Date and Time
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM yyyy | hh:mm a').format(date),
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Location (address)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(
                              color: location != 'Unknown Location'
                                  ? Colors.black87
                                  : Colors.black54,
                              fontSize: 12,
                              fontWeight: location != 'Unknown Location'
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Pest Type
                    Row(
                      children: [
                        const Icon(
                          Icons.bug_report,
                          size: 14,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "${Helpers.getPestEmoji(pest)} $pest",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens a fullscreen zoomable image viewer with pinch-to-zoom,
  /// double-tap to zoom, and swipe down to dismiss.
  void _showFullScreenImage(String imagePath, String pestName, String scanId) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenImageViewer(
            imagePath: imagePath,
            pestName: pestName,
            scanId: scanId,
            heroTag: 'scan_image_$scanId',
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  Widget _buildImageWidget(String imagePath) {
    String? urlToUse;
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      urlToUse = imagePath;
    } else if (imagePath.isNotEmpty && imagePath != 'assets/images/thumb.png') {
      // Prepend API base URL for backend-served images
      urlToUse =
          '${ApiService.baseUrl}/${imagePath.replaceFirst(RegExp(r'^/'), '')}';
    }

    if (urlToUse != null) {
      return Image.network(
        urlToUse,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (c, o, s) => Container(
          width: 72,
          height: 72,
          color: Colors.grey[200],
          child: const Icon(Icons.image),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 72,
            height: 72,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    } else {
      // Use asset image as fallback
      return Image.asset(
        imagePath,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (c, o, s) => Container(
          width: 72,
          height: 72,
          color: Colors.grey[200],
          child: const Icon(Icons.image),
        ),
      );
    }
  }
}

/// Fullscreen zoomable image viewer for scanned pest photos.
/// Supports pinch-to-zoom, double-tap to zoom in/out, and drag to pan.
class _FullScreenImageViewer extends StatefulWidget {
  final String imagePath;
  final String pestName;
  final String scanId;
  final String heroTag;

  const _FullScreenImageViewer({
    required this.imagePath,
    required this.pestName,
    required this.scanId,
    required this.heroTag,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformController =
      TransformationController();
  late AnimationController _animController;
  Animation<Matrix4>? _animation;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 250),
        )..addListener(() {
          if (_animation != null) {
            _transformController.value = _animation!.value;
          }
        });
  }

  @override
  void dispose() {
    _transformController.dispose();
    _animController.dispose();
    super.dispose();
  }

  /// Double-tap toggles between 1× and 2.5× zoom
  void _handleDoubleTap() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();

    Matrix4 endMatrix;
    if (currentScale > 1.2) {
      // Zoom out to normal
      endMatrix = Matrix4.identity();
    } else {
      // Zoom in 2.5× centered on tap position
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      endMatrix = Matrix4.identity()
        ..setEntry(0, 3, -position.dx * 1.5)
        ..setEntry(1, 3, -position.dy * 1.5);
      endMatrix.multiply(Matrix4.diagonal3Values(2.5, 2.5, 1.0));
    }

    _animation = Matrix4Tween(begin: _transformController.value, end: endMatrix)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
        );

    _animController.forward(from: 0);
  }

  void _resetZoom() {
    _animation = Matrix4Tween(
      begin: _transformController.value,
      end: Matrix4.identity(),
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Zoomable image
          GestureDetector(
            onDoubleTapDown: (details) => _doubleTapDetails = details,
            onDoubleTap: _handleDoubleTap,
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.5,
              maxScale: 5.0,
              clipBehavior: Clip.none,
              child: Center(
                child: Hero(tag: widget.heroTag, child: _buildFullImage()),
              ),
            ),
          ),

          // Top bar with close button and info
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.pestName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.scanId.isNotEmpty)
                              Text(
                                'Scan #${widget.scanId}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom zoom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Zoom out button
                      _buildZoomButton(
                        icon: Icons.zoom_out,
                        tooltip: 'Zoom Out',
                        onPressed: () {
                          final scale = _transformController.value
                              .getMaxScaleOnAxis();
                          if (scale > 0.6) {
                            final newScale = (scale / 1.5).clamp(0.5, 5.0);
                            _animation =
                                Matrix4Tween(
                                  begin: _transformController.value,
                                  end: Matrix4.diagonal3Values(
                                    newScale,
                                    newScale,
                                    1.0,
                                  ),
                                ).animate(
                                  CurvedAnimation(
                                    parent: _animController,
                                    curve: Curves.easeOut,
                                  ),
                                );
                            _animController.forward(from: 0);
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                      // Reset / fit button
                      _buildZoomButton(
                        icon: Icons.fit_screen,
                        tooltip: 'Reset Zoom',
                        onPressed: _resetZoom,
                      ),
                      const SizedBox(width: 16),
                      // Zoom in button
                      _buildZoomButton(
                        icon: Icons.zoom_in,
                        tooltip: 'Zoom In',
                        onPressed: () {
                          final scale = _transformController.value
                              .getMaxScaleOnAxis();
                          if (scale < 4.8) {
                            final newScale = (scale * 1.5).clamp(0.5, 5.0);
                            _animation =
                                Matrix4Tween(
                                  begin: _transformController.value,
                                  end: Matrix4.diagonal3Values(
                                    newScale,
                                    newScale,
                                    1.0,
                                  ),
                                ).animate(
                                  CurvedAnimation(
                                    parent: _animController,
                                    curve: Curves.easeOut,
                                  ),
                                );
                            _animController.forward(from: 0);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Pinch hint (shown briefly)
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Pinch to zoom • Double-tap to zoom in/out',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24),
        onPressed: onPressed,
        tooltip: tooltip,
        splashRadius: 24,
      ),
    );
  }

  Widget _buildFullImage() {
    String? urlToUse;
    final imagePath = widget.imagePath;

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      urlToUse = imagePath;
    } else if (imagePath.isNotEmpty && imagePath != 'assets/images/thumb.png') {
      urlToUse =
          '${ApiService.baseUrl}/${imagePath.replaceFirst(RegExp(r'^/'), '')}';
    }

    if (urlToUse != null) {
      return Image.network(
        urlToUse,
        fit: BoxFit.contain,
        errorBuilder: (c, o, s) => Container(
          width: 200,
          height: 200,
          color: Colors.grey[800],
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: Colors.white54, size: 64),
              SizedBox(height: 12),
              Text(
                'Failed to load image',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          final total = loadingProgress.expectedTotalBytes;
          final loaded = loadingProgress.cumulativeBytesLoaded;
          return SizedBox(
            width: 200,
            height: 200,
            child: Center(
              child: CircularProgressIndicator(
                value: total != null ? loaded / total : null,
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          );
        },
      );
    } else {
      return Image.asset(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (c, o, s) => Container(
          width: 200,
          height: 200,
          color: Colors.grey[800],
          child: const Icon(Icons.image, color: Colors.white54, size: 64),
        ),
      );
    }
  }
}
