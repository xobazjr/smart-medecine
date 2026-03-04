import 'package:flutter/material.dart';

class EditDrugPage extends StatelessWidget {
  const EditDrugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แก้ไขยา')),
      body: Center(
        child: Text(
          'Edit Drug Page',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
