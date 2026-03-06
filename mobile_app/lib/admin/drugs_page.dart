import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DrugsPage extends StatelessWidget {
  final Map<String, dynamic> user;
  const DrugsPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ยา')),
      body: Center(
        child: Text(
          'Drugs Page',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
