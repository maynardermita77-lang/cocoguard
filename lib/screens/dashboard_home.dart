import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import '../services/user_service.dart';
import '../services/api_endpoints.dart';
import '../services/weather_service.dart';
import '../services/notification_service.dart';
import '../widgets/offline_indicator.dart';
import '../services/translation_service.dart';
import 'package:intl/intl.dart';

class DashboardHome extends StatefulWidget {
  final Function(int)? onNavigate;

  const DashboardHome({super.key, this.onNavigate});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  bool _showMenu = false;
  String _userName = 'User';

  // Weather state
  int? _temperature;
  String? _location;
  String? _weatherDescription;
  bool _isLoadingWeather = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadWeather();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      await NotificationService.getUnreadCount();
    } catch (e) {
      developer.log('Failed to load notifications: $e', name: 'DashboardHome');
    }
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await AuthApi.getCurrentUser();
      if (mounted && userData['full_name'] != null) {
        setState(() {
          _userName = userData['full_name'];
        });
        // Update UserService as well
        UserService.user.value = UserService.user.value.copyWith(
          fullName: userData['full_name'],
        );
      }
    } catch (e) {
      // If fails, try to use UserService data
      if (mounted) {
        setState(() {
          _userName = UserService.user.value.fullName;
        });
      }
    }
  }

  Future<void> _loadWeather() async {
    try {
      final weatherData = await WeatherService.getCurrentWeather();
      if (mounted) {
        setState(() {
          _temperature = weatherData['temp'];
          _location = '${weatherData['city']}, ${weatherData['country']}';
          _weatherDescription = weatherData['description'];
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      developer.log('Weather error: $e', name: 'DashboardHome');
      if (mounted) {
        setState(() {
          _location = 'Location unavailable';
          _temperature = null;
          _weatherDescription = 'Unable to fetch weather';
          _isLoadingWeather = false;
        });
      }
    }
  }

  void _showImageViewer(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4,
                child: Center(
                  child: Image.asset(imagePath, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Split background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height / 2,
            child: Image.asset(
              'assets/images/top_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (c, o, s) => Container(color: Colors.white),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height / 2,
            child: Image.asset(
              'assets/images/bottom_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (c, o, s) => Container(color: Colors.white),
            ),
          ),
          // Main content
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Offline indicator (shows only when offline or has pending scans)
                const OfflineIndicator(),
                // Header with profile and menu
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Profile section
                      Expanded(
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.person,
                                color: Color(0xFF2d7a3e),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr('dashboard.greeting'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    _userName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Menu button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showMenu = !_showMenu;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.menu,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      // Notification button with badge
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (_) => const NotificationsScreen(),
                                ),
                              )
                              .then((_) => _loadNotifications());
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ValueListenableBuilder<int>(
                            valueListenable: NotificationService.unreadCount,
                            builder: (context, count, child) {
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const Center(
                                    child: Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  if (count > 0)
                                    Positioned(
                                      right: 2,
                                      top: 2,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 18,
                                          minHeight: 18,
                                        ),
                                        child: Text(
                                          count > 99 ? '99+' : count.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      // Settings button
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Location and Weather Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Weather Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Color(0xFF2d7a3e),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _location ?? 'Loading...',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isLoadingWeather
                                        ? '--'
                                        : _temperature?.toString() ?? '--',
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tr('dashboard.celsius'),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Text(
                                          _weatherDescription ??
                                              tr('common.loading'),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 12,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    DateFormat(
                                      'MMM dd EEEE',
                                    ).format(DateTime.now()),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2d7a3e), Color(0xFF1a4d29)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '52nd',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            tr('dashboard.founding_anniversary'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Features Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('dashboard.features'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.1,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        children: [
                          _FeatureCard(
                            icon: Icons.camera_alt,
                            label: tr('dashboard.camera'),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CameraScreen(),
                                ),
                              );
                            },
                          ),
                          _FeatureCard(
                            icon: Icons.schedule,
                            label: tr('dashboard.history'),
                            onTap: () {
                              widget.onNavigate?.call(1);
                            },
                          ),
                          _FeatureCard(
                            icon: Icons.lightbulb,
                            label: tr('dashboard.knowledge'),
                            onTap: () {
                              widget.onNavigate?.call(2);
                            },
                          ),
                          _FeatureCard(
                            icon: Icons.phone,
                            label: tr('dashboard.directories'),
                            onTap: () {
                              widget.onNavigate?.call(3);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Infographic Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('dashboard.infographic'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GestureDetector(
                          onTap: () {
                            _showImageViewer(context, 'assets/images/info.png');
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/info.png',
                              fit: BoxFit.contain,
                              errorBuilder: (c, o, s) => Container(
                                color: Colors.grey[300],
                                height: 200,
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                    size: 48,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // Side Menu
          if (_showMenu)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showMenu = false;
                });
              },
              child: Container(color: Colors.black.withValues(alpha: 0.5)),
            ),
          if (_showMenu)
            Positioned(
              top: 0,
              left: 0,
              bottom: 0,
              width: 250,
              child: Container(
                color: const Color(0xFF2d7a3e),
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tr('dashboard.menu'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showMenu = false;
                                });
                              },
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white30),
                      Expanded(
                        child: ListView(
                          children: [
                            _MenuItem(
                              icon: Icons.home,
                              label: tr('dashboard.dashboard'),
                              onTap: () {
                                setState(() {
                                  _showMenu = false;
                                });
                                if (widget.onNavigate != null) {
                                  widget.onNavigate!(0);
                                }
                              },
                            ),
                            _MenuItem(
                              icon: Icons.history,
                              label: tr('dashboard.history'),
                              onTap: () {
                                setState(() {
                                  _showMenu = false;
                                });
                                if (widget.onNavigate != null) {
                                  widget.onNavigate!(1);
                                }
                              },
                            ),
                            _MenuItem(
                              icon: Icons.school,
                              label: tr('dashboard.knowledge'),
                              onTap: () {
                                setState(() {
                                  _showMenu = false;
                                });
                                if (widget.onNavigate != null) {
                                  widget.onNavigate!(2);
                                }
                              },
                            ),
                            _MenuItem(
                              icon: Icons.contact_mail,
                              label: tr('dashboard.directories'),
                              onTap: () {
                                setState(() {
                                  _showMenu = false;
                                });
                                if (widget.onNavigate != null) {
                                  widget.onNavigate!(3);
                                }
                              },
                            ),
                            _MenuItem(
                              icon: Icons.person,
                              label: tr('dashboard.profile'),
                              onTap: () {
                                setState(() {
                                  _showMenu = false;
                                });
                                if (widget.onNavigate != null) {
                                  widget.onNavigate!(4);
                                }
                              },
                            ),
                            _MenuItem(
                              icon: Icons.settings,
                              label: tr('dashboard.settings'),
                              onTap: () {
                                setState(() {
                                  _showMenu = false;
                                });
                                if (widget.onNavigate != null) {
                                  widget.onNavigate!(5);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          tr('dashboard.version'),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        widget.onTap();
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      child: Transform.scale(
        scale: _isPressed ? 0.95 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isPressed
                  ? [const Color(0xFF6d9535), const Color(0xFF4a7623)]
                  : [const Color(0xFF7cb342), const Color(0xFF558b2f)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isPressed ? 0.3 : 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 38),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
