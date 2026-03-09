import 'package:flutter/material.dart';
import 'patient/settings_page.dart';
import 'patient/drugs_page.dart';
import 'patient/history_page.dart';
import 'patient/home_page.dart';

class LandingPagePatient extends StatefulWidget {
  final Map<String, dynamic> user;
  const LandingPagePatient({super.key, required this.user});

  @override
  State<LandingPagePatient> createState() => _LandingPagePatientState();
}

class _LandingPagePatientState extends State<LandingPagePatient> {
  int _selectedIndex = 0;

  List<Widget> get _widgetOptions => [
    HomePage(user: widget.user),
    DrugsPage(user: widget.user),
    HistoryPage(user: widget.user),
    SettingsPage(user: widget.user),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        indicatorColor: const Color(0xFF9BD2F2),
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Colors.white),
            label: 'หน้าหลัก',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication, color: Colors.white),
            label: 'ยา',
          ),
          NavigationDestination(
            icon: Icon(Icons.query_stats_outlined),
            selectedIcon: Icon(Icons.query_stats_sharp, color: Colors.white),
            label: 'สถิติ',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: Colors.white),
            label: 'ตั้งค่า',
          ),
        ],
      ),
    );
  }
}
