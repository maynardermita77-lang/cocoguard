import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'utils/constants.dart';
import 'utils/helpers.dart';
import 'services/theme_service.dart';
import 'services/user_service.dart';
import 'services/api_service.dart';
import 'services/local_data_service.dart';
import 'services/push_notification_service.dart';
import 'services/connectivity_service.dart';
import 'services/offline_sync_service.dart';
import 'services/translation_service.dart';
import 'services/offline_prediction_service_web.dart'
    if (dart.library.io) 'services/offline_prediction_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeService.init();
  await ApiService.init();
  // Initialize Hive/local storage before app starts
  await LocalDataService.init();
  // Initialize translation service
  await TranslationService.instance.init();
  // Initialize connectivity monitoring for offline mode
  await ConnectivityService.instance.init();
  // Initialize offline sync service
  await OfflineSyncService.instance.init();
  // Pre-load TFLite model for faster offline predictions (not on web)
  if (!kIsWeb) {
    OfflinePredictionService.instance.loadModel();
  }
  // Initialize push notifications for pest alerts
  await PushNotificationService.initialize();
  // Subscribe to pest_alerts topic for broadcast notifications
  await PushNotificationService.subscribeToTopic('pest_alerts');
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const CocoGuardApp());
}

class CocoGuardApp extends StatelessWidget {
  const CocoGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeMode,
      builder: (context, mode, _) {
        return ListenableBuilder(
          listenable: TranslationService.instance,
          builder: (context, _) {
            return MaterialApp(
              title: 'CocoGuard',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                primaryColor: const Color(0xFF2d7a3e),
                scaffoldBackgroundColor: Colors.white,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF2d7a3e),
                  primary: const Color(0xFF2d7a3e),
                  secondary: const Color(0xFFc6a030),
                ),
                fontFamily: 'Roboto',
                useMaterial3: true,
              ),
              darkTheme: ThemeData.dark().copyWith(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF2d7a3e),
                  primary: const Color(0xFF2d7a3e),
                  secondary: const Color(0xFFc6a030),
                ),
                scaffoldBackgroundColor: Colors.black,
              ),
              themeMode: mode,
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DASHBOARD HOME
// ══════════════════════════════════════════════════════════════════════════════
// CAMERA SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
        backgroundColor: const Color(0xFF2d7a3e),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('📷', style: TextStyle(fontSize: 80)),
                    SizedBox(height: 20),
                    Text(
                      'Camera View',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Capture or upload coconut images',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            color: const Color(0xFF2d7a3e),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCameraOption(context, '📸', 'Capture', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SurveyScreen(),
                        ),
                      );
                    }),
                    _buildCameraOption(context, '🖼️', 'Gallery', () {}),
                    _buildCameraOption(context, '📋', 'Survey', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SurveyScreen(),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFc6a030),
                      width: 5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraOption(
    BuildContext context,
    String icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PLACEHOLDER SCREENS (History, Knowledge, Contact, Settings, Survey)
// ══════════════════════════════════════════════════════════════════════════════

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _records = [
    {
      'id': '1',
      'treeId': '----',
      'date': DateTime(2025, 10, 9, 16, 11, 57),
      'location': 'Farm A, Cabuyao, Laguna',
      'pest': 'Spike Moth',
      'confidence': 0.94,
      'image': 'assets/images/thumb.png',
    },
    {
      'id': '2',
      'treeId': 'Tree#098',
      'date': DateTime(2025, 10, 9, 16, 11, 57),
      'location': 'Farm A, Cabuyao, Laguna',
      'pest': 'Coconut Scale',
      'confidence': 0.94,
      'image': 'assets/images/thumb.png',
    },
    {
      'id': '3',
      'treeId': 'Tree#126',
      'date': DateTime(2025, 10, 7, 16, 11, 57),
      'location': 'Farm A, Cabuyao, Laguna',
      'pest': 'Rhinoceros Beetle',
      'confidence': 0.94,
      'image': 'assets/images/thumb.png',
    },
  ];

  // Filtering state
  late List<Map<String, dynamic>> _filteredRecords;
  final Set<String> _selectedPests = {};
  final Set<String> _selectedSeverities = {}; // 'Low','Medium','High'

  Map<String, List<Map<String, dynamic>>> _groupRecordsByDate() {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (var r in _filteredRecords) {
      final key = DateFormat('dd MMMM').format(r['date'] as DateTime);
      groups.putIfAbsent(key, () => []).add(r);
    }
    return groups;
  }

  String _severityCategory(double confidence) {
    if (confidence >= 0.8) return 'High';
    if (confidence >= 0.5) return 'Medium';
    return 'Low';
  }

  @override
  void initState() {
    super.initState();
    _filteredRecords = List<Map<String, dynamic>>.from(_records);
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final q = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredRecords = _records.where((r) {
        final treeId = (r['treeId'] ?? '').toString().toLowerCase();
        final location = (r['location'] ?? '').toString().toLowerCase();
        final pest = (r['pest'] ?? '').toString().toLowerCase();

        if (q.isNotEmpty) {
          if (!(treeId.contains(q) ||
              location.contains(q) ||
              pest.contains(q))) {
            return false;
          }
        }

        if (_selectedPests.isNotEmpty) {
          if (!_selectedPests.contains(r['pest'])) return false;
        }

        if (_selectedSeverities.isNotEmpty) {
          final sev = _severityCategory((r['confidence'] as double));
          if (!_selectedSeverities.contains(sev)) return false;
        }

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupRecordsByDate();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              const Text(
                'History',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d7a3e),
                ),
              ),
              const SizedBox(height: 12),
              // Search
              TextField(
                controller: _searchController,
                onChanged: (_) => _applyFilters(),
                decoration: InputDecoration(
                  hintText: 'Search (tree id, location, pest)',
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

              // Stats cards
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
                              color: Color.fromRGBO(0, 0, 0, 0.08),
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
                            const Text(
                              'Total Scans',
                              style: TextStyle(color: Colors.black54),
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
                          children: const [
                            Text(
                              '176',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Total Trees',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Filters (pest chips + severity chips)
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Pest chips
                  for (var pest in AppConstants.pestTypes)
                    ChoiceChip(
                      label: Text(pest),
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
                  // Severity chips
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('High'),
                    selected: _selectedSeverities.contains('High'),
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selectedSeverities.add('High');
                        } else {
                          _selectedSeverities.remove('High');
                        }
                        _applyFilters();
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Medium'),
                    selected: _selectedSeverities.contains('Medium'),
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selectedSeverities.add('Medium');
                        } else {
                          _selectedSeverities.remove('Medium');
                        }
                        _applyFilters();
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Low'),
                    selected: _selectedSeverities.contains('Low'),
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selectedSeverities.add('Low');
                        } else {
                          _selectedSeverities.remove('Low');
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
                  ),
                ),
                const SizedBox(height: 8),
                for (var r in entry.value) _buildRecordCard(r),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> r) {
    final date = r['date'] as DateTime;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  r['image'] as String,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (c, o, s) => Container(
                    width: 72,
                    height: 72,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r['treeId'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Date: ${DateFormat('dd MMM yyyy | hh:mm a').format(date)}",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      "Location: ${r['location']}",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          "Pest type: ${Helpers.getPestEmoji(r['pest'] as String)} ${r['pest']}",
                          style: const TextStyle(fontSize: 12),
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
}

class KnowledgeScreen extends StatelessWidget {
  const KnowledgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              const Text(
                'Knowledge',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d7a3e),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gabay sa Kalusugan ng Niyog',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 14),

              // Stacked poster cards (green frames with white content)
              _KnowledgePoster(
                width: width,
                title: 'Plant Health Overview',
                lines: [
                  'Common pests and diseases',
                  'Identification tips and control measures',
                ],
              ),
              const SizedBox(height: 14),
              _KnowledgePoster(
                width: width,
                title: 'Pest Control Methods',
                lines: [
                  'Biological control',
                  'Cultural practices and sanitation',
                ],
              ),
              const SizedBox(height: 14),
              _KnowledgePoster(
                width: width,
                title: 'Monitoring & Prevention',
                lines: [
                  'When to inspect trees',
                  'Record keeping and thresholds',
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _KnowledgePoster extends StatelessWidget {
  final double width;
  final String title;
  final List<String> lines;

  const _KnowledgePoster({
    required this.width,
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    final frameColor = const Color(0xFFe6f3d9);
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: frameColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.06), blurRadius: 6),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2d7a3e),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column: text snippets
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: lines
                              .map(
                                (l) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    '• $l',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Right column: stacked thumbnails
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(6),
                                image: const DecorationImage(
                                  image: AssetImage('assets/images/thumb.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(6),
                                image: const DecorationImage(
                                  image: AssetImage('assets/images/thumb.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // small caption area
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Icon(Icons.info_outline, size: 16, color: Colors.white70),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Stack(
        children: [
          // background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF6FFF6), Color(0xFFE8F5E8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  const Text(
                    'Directories',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFe6b800),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Makipag-ugnayan sa PCA o Lokal na Opisina',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 18),

                  // Centered contact card
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: w * 0.92,
                        minWidth: 300,
                      ),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Contact List:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),

                              // Contact entries
                              _directoryRow(
                                title: 'PCA Alaminos, Laguna',
                                phone: '09123456789',
                                email: 'pca@alaminos.com',
                                org: 'PCA Alaminos',
                              ),
                              const Divider(),
                              _directoryRow(
                                title: 'City Agriculturist',
                                phone: '09123456789',
                                email: 'city@agri.com',
                                org: 'PCA Agriculturist',
                              ),
                              const Divider(),
                              _directoryRow(
                                title: 'Barangay Agriculturist',
                                phone: '09123456789',
                                email: 'brgy@agri.com',
                                org: 'PCA Alaminos',
                              ),

                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _directoryRow({
    required String title,
    required String phone,
    required String email,
    required String org,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 8.0, top: 4),
            child: Icon(Icons.location_pin, color: Color(0xFFe64a19)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(phone),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(email),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.public, size: 16, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(org),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _language = 'English';

  Future<void> _chooseLanguage() async {
    final sel = await showDialog<String>(
      context: context,
      builder: (c) => SimpleDialog(
        title: const Text('Select Language'),
        children: [
          SimpleDialogOption(
            child: const Text('English'),
            onPressed: () => Navigator.pop(c, 'English'),
          ),
          SimpleDialogOption(
            child: const Text('Filipino'),
            onPressed: () => Navigator.pop(c, 'Filipino'),
          ),
        ],
      ),
    );
    if (sel != null) setState(() => _language = sel);
  }

  Future<void> _showInfo(String title, String content) async {
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _dataManagement() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.import_export),
              title: const Text('Export Data'),
              onTap: () {
                Navigator.pop(c);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Export started')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete All Data'),
              onTap: () async {
                final conf = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: const Text('Confirm Delete'),
                    content: const Text('This will delete all local data.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(d, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(d, true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
                if (!mounted) return;
                if (!c.mounted) return;
                Navigator.pop(c);
                if (conf == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All data deleted')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // subtle background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFAFAFA), Color(0xFFFFFFFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFe6b800),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Account Settings card
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.person, color: Color(0xFF2d7a3e)),
                              SizedBox(width: 8),
                              Text(
                                'Account Settings',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.person_outline,
                              color: Color(0xFF2d7a3e),
                            ),
                            title: const Text('Manage Profile'),
                            subtitle: const Text(
                              'Update your personal information',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProfileScreen(),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.lock_outline,
                              color: Color(0xFF2d7a3e),
                            ),
                            title: const Text('Change Password'),
                            subtitle: const Text(
                              'Secure your account with a new password',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ChangePasswordScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // General Preferences
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.tune, color: Color(0xFF2d7a3e)),
                              SizedBox(width: 8),
                              Text(
                                'General Preferences',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.language,
                              color: Colors.green,
                            ),
                            title: const Text('Language'),
                            subtitle: Text('Current: $_language'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _chooseLanguage,
                          ),
                          ValueListenableBuilder<ThemeMode>(
                            valueListenable: ThemeService.themeMode,
                            builder: (context, mode, _) {
                              return SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Dark Mode'),
                                subtitle: const Text(
                                  'Switch between light and dark themes',
                                ),
                                value: mode == ThemeMode.dark,
                                activeThumbColor: const Color(0xFF2d7a3e),
                                onChanged: (v) => ThemeService.setDark(v),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Privacy & Security
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.lock, color: Color(0xFF2d7a3e)),
                              SizedBox(width: 8),
                              Text(
                                'Privacy & Security',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.policy,
                              color: Colors.grey,
                            ),
                            title: const Text('Privacy Policy'),
                            subtitle: const Text(
                              'Read our data protection guidelines',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showInfo(
                              'Privacy Policy',
                              'Privacy policy details placeholder.',
                            ),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.gavel,
                              color: Colors.grey,
                            ),
                            title: const Text('Terms of Service'),
                            subtitle: const Text(
                              "Review the application's terms and conditions",
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showInfo(
                              'Terms of Service',
                              'Terms of service placeholder.',
                            ),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.delete_outline,
                              color: Colors.grey,
                            ),
                            title: const Text('Data Management'),
                            subtitle: const Text(
                              'Export or delete your personal data',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _dataManagement,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // App Info and Logout
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.info_outline,
                                color: Color(0xFF2d7a3e),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'App Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.info,
                              color: Colors.green,
                            ),
                            title: const Text('About CocoGuard'),
                            subtitle: const Text('Version 1.0.0'),
                            onTap: () => _showInfo(
                              'About CocoGuard',
                              'CocoGuard\nVersion 1.0.0\n© CocoGuard',
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Simple logout flow: navigate back to login
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                  (route) => false,
                                );
                              },
                              icon: const Icon(Icons.logout),
                              label: const Text('Log Out'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFe64a19),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Simple Profile screen (restored to original static layout)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final name = 'Juan Dela Cruz';
    final email = 'juan@example.com';
    final dob = DateTime(1990, 1, 1);
    final phone = '+63 912 345 6789';
    final location = 'Brgy 2 Cabuyao, Laguna';

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF6FFF6), Color(0xFFE8F5E8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFe6b800),
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFF2d7a3e),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 18,
                      ),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 36,
                            backgroundColor: Color(0xFF2d7a3e),
                            child: Text('👤', style: TextStyle(fontSize: 32)),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            email,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: 140,
                            child: OutlinedButton(
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const EditProfileScreen(),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                side: const BorderSide(
                                  color: Color(0xFF2d7a3e),
                                ),
                              ),
                              child: const Text(
                                'Edit Profile',
                                style: TextStyle(color: Color(0xFF2d7a3e)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Personal Details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2d7a3e),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.cake,
                                color: Colors.green,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Date of Birth',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(DateFormat('MMMM d, yyyy').format(dob)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.male,
                                color: Colors.green,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Gender',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('Male'),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Contact Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2d7a3e),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.email,
                                size: 18,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(email)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                size: 18,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(phone)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 18,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(location)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.lock_outline),
                          title: const Text('Change Password'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ChangePasswordScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.settings_outlined),
                          title: const Text('Settings'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.logout,
                            color: Color(0xFFe64a19),
                          ),
                          title: const Text('Logout'),
                          trailing: const Icon(Icons.exit_to_app),
                          onTap: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                              (r) => false,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtl;
  late TextEditingController _emailCtl;
  late TextEditingController _phoneCtl;
  late TextEditingController _locationCtl;
  late TextEditingController _genderCtl;
  late DateTime _dob;

  @override
  void initState() {
    super.initState();
    final u = UserService.user.value;
    _nameCtl = TextEditingController(text: u.fullName);
    _emailCtl = TextEditingController(text: u.email);
    _phoneCtl = TextEditingController(text: u.phone);
    _locationCtl = TextEditingController(text: u.location);
    _genderCtl = TextEditingController(text: u.gender);
    _dob = u.dob;
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _phoneCtl.dispose();
    _locationCtl.dispose();
    _genderCtl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  void _save() {
    final updated = UserService.user.value.copyWith(
      fullName: _nameCtl.text.trim(),
      email: _emailCtl.text.trim(),
      phone: _phoneCtl.text.trim(),
      location: _locationCtl.text.trim(),
      gender: _genderCtl.text.trim(),
      dob: _dob,
    );
    UserService.user.value = updated;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFF2d7a3e),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _nameCtl,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailCtl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtl,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationCtl,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _genderCtl,
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Date of Birth: ${DateFormat('MMMM d, yyyy').format(_dob)}',
                    ),
                  ),
                  TextButton(onPressed: _pickDob, child: const Text('Change')),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldCtl = TextEditingController();
  final _newCtl = TextEditingController();
  final _confirmCtl = TextEditingController();

  @override
  void dispose() {
    _oldCtl.dispose();
    _newCtl.dispose();
    _confirmCtl.dispose();
    super.dispose();
  }

  void _change() {
    final n = _newCtl.text.trim();
    final c = _confirmCtl.text.trim();
    if (n.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }
    if (n != c) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    // No real backend here — just show success
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Password changed')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: const Color(0xFF2d7a3e),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _oldCtl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newCtl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmCtl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _change,
                  child: const Text('Change Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SurveyScreen extends StatelessWidget {
  const SurveyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Survey'),
        backgroundColor: const Color(0xFF2d7a3e),
      ),
      body: const Center(
        child: Text('Survey Screen', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
