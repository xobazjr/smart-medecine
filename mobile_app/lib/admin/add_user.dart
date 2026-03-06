import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddUserPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const AddUserPage({super.key, required this.user});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _telController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;

  final String caretakerName = "xobazjr";

  Future<void> addUser() async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(
      'https://smart-medicine-topaz.vercel.app/api/patients/add',
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": _usernameController.text.trim(),
        "password": _passwordController.text.trim(),
        "tel": _telController.text.trim(),
        "caretaker_name": caretakerName,
        "morning_time": "08:00:00",
        "noon_time": "12:00:00",
        "evening_time": "18:00:00",
        "bedtime_time": "22:00:00",
      }),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("เพิ่มผู้ป่วยสำเร็จ"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("เพิ่มไม่สำเร็จ: ${response.body}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _telController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มผู้ป่วย')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อบัญชี',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกชื่อบัญชี';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'รหัสผ่าน',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกรหัสผ่าน';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'ยืนยันรหัสผ่าน',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกยืนยันรหัสผ่าน';
                  }
                  if (value != _passwordController.text) {
                    return 'รหัสผ่านไม่ตรงกัน';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _telController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'เบอร์โทร',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 25),

              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          addUser();
                        }
                      },
                      child: const Text('บันทึก'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
