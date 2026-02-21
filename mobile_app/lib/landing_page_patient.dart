import 'package:flutter/material.dart';
import 'user/settings_page.dart';
import 'user/drugs_page.dart';
import 'user/history_page.dart';
import 'user/home_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    DrugsPage(),
    HistoryPage(),
    SettingsPage(),
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.shifting,
        backgroundColor: const Color(0xFF095086),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'หน้าหลัก',
            backgroundColor: Color(0xFF095086),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication),
            label: 'ยา',
            backgroundColor: Color(0xFF095086),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.query_stats_sharp),
            label: 'สถิติ',
            backgroundColor: Color(0xFF095086),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'ตั้งค่า',
            backgroundColor: Color(0xFF095086),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF9BD2F2),
        onTap: _onItemTapped,
      ),
    );
  }
}
