import 'package:flutter/material.dart';
import 'dashboard_home.dart';
import 'history/history_screen.dart';
import 'knowledge/knowledge_screen.dart';
import 'contact_screen.dart';
import 'profile_screen.dart';
import '../services/translation_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardHome(
        onNavigate: (index) => setState(() => _selectedIndex = index),
      ),
      const HistoryScreen(),
      const KnowledgeScreen(),
      const ContactScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2d7a3e),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: tr('dashboard.dashboard'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: tr('nav.history'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.book),
            label: tr('dashboard.knowledge'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.folder),
            label: tr('dashboard.directories'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: tr('nav.profile'),
          ),
        ],
      ),
    );
  }
}
