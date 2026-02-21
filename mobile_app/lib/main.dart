import 'package:flutter/material.dart';
import 'user/settings.dart';
import 'user/drugs.dart';
import 'user/stats.dart';
import 'user/homa.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  // static const TextStyle optionStyle = TextStyle(
  //   fontSize: 30,
  //   fontWeight: FontWeight.bold,
  // );

  static const List<Widget> _widgetOptions = <Widget>[
    // Text('Index 0: Home', style: optionStyle),
    HomePage(),
    // Text('Index 1: Drugs', style: optionStyle),
    DrugsPage(),
    // Text('Index 2: Stats', style: optionStyle),
    StatsPage(),
    // Text('Index 3: Settings', style: optionStyle),
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
