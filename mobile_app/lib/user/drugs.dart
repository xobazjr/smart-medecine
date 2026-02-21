import 'package:flutter/material.dart';

class DrugsPage extends StatelessWidget {
  const DrugsPage({super.key});

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
