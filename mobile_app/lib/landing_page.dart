// import 'package:flutter/material.dart';
// import 'admin/settings_page.dart';
// import 'admin/drugs_page.dart';
// import 'admin/history_page.dart';
// import 'admin/home_page.dart';

// class LandingPage extends StatefulWidget {
//   const LandingPage({super.key});

//   @override
//   State<LandingPage> createState() => _LandingPageState();
// }

// class _LandingPageState extends State<LandingPage> {
//   int _selectedIndex = 0;

//   static const List<Widget> _widgetOptions = <Widget>[
//     HomePage(),
//     DrugsPage(),
//     HistoryPage(),
//     SettingsPage(),
//   ];

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
//       bottomNavigationBar: BottomNavigationBar(
//         type: BottomNavigationBarType.shifting,
//         backgroundColor: const Color(0xFF095086),
//         items: const <BottomNavigationBarItem>[
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'หน้าหลัก',
//             backgroundColor: Color(0xFF095086),
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.medication),
//             label: 'ยา',
//             backgroundColor: Color(0xFF095086),
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.query_stats_sharp),
//             label: 'สถิติ',
//             backgroundColor: Color(0xFF095086),
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings),
//             label: 'ตั้งค่า',
//             backgroundColor: Color(0xFF095086),
//           ),
//         ],
//         currentIndex: _selectedIndex,
//         selectedItemColor: const Color(0xFF9BD2F2),
//         onTap: _onItemTapped,
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'admin/settings_page.dart';
import 'admin/drugs_page.dart';
import 'admin/history_page.dart';
import 'admin/home_page.dart';

/// Flutter code sample for [NavigationBar].

void main() => runApp(const LandingPage());

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Navigation());
  }
}

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // final ThemeData theme = Theme.of(context);
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
            // icon: Badge(child: Icon(Icons.medication_outlined)),
            icon: Icon(Icons.medication_outlined),
            label: 'ยา',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.query_stats_sharp, color: Colors.white),
            // icon: Badge(
            //   label: Text('2'),
            //   child: Icon(Icons.query_stats_outlined),
            // ),
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
        HomePage(), // index 0
        DrugsPage(), // index 1
        HistoryPage(), // index 2
        SettingsPage(), // index 3
      ][_selectedIndex],
    );
  }
}
