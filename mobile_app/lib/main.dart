import 'package:flutter/material.dart';
import 'login_page.dart';
// import 'user/settings_page.dart';
// import 'user/drugs_page.dart';
// import 'user/history_page.dart';
// import 'user/home_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}
