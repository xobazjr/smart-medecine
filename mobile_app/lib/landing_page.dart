import 'package:flutter/material.dart';
import 'admin/settings_page.dart';
import 'admin/drugs_page.dart';
import 'admin/history_page.dart';
import 'admin/home_page.dart';

class LandingPage extends StatelessWidget {
  final Map<String, dynamic> user;

  const LandingPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Navigation(user: user));
  }
}

class Navigation extends StatefulWidget {
  final Map<String, dynamic> user;

  const Navigation({super.key, required this.user});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        indicatorColor: const Color(0xFF095086),
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home, color: Colors.white),
            icon: Icon(Icons.home_outlined),
            label: 'หน้าหลัก',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.medication, color: Colors.white),
            icon: Icon(Icons.medication_outlined),
            label: 'ยา',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.query_stats_sharp, color: Colors.white),
            icon: Icon(Icons.query_stats_outlined),
            label: 'ประวัติ',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.settings, color: Colors.white),
            icon: Icon(Icons.settings_outlined),
            label: 'ตั้งค่า',
          ),
        ],
      ),
      body: [
        HomePage(user: widget.user),
        DrugsPage(user: widget.user),
        HistoryPage(user: widget.user),
        SettingsPage(user: widget.user),
      ][_selectedIndex],
    );
  }
}
