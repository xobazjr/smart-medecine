import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditUserPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const EditUserPage({super.key, required this.user});

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _telController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingPatients = true;

  // final String caretakerName = "xobazjr";

  List<Map<String, dynamic>> _patients = [];
  String? _selectedPatientId;

  String? _oldUsername;

  @override
  void initState() {
    super.initState();
    fetchPatients();
  }

  Future<void> fetchPatients() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse(
      'https://smart-medicine-topaz.vercel.app/api/patients/list?caretaker_name=${widget.user["username"]}',
    );

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        _patients = List<Map<String, dynamic>>.from(data);
        _isLoadingPatients = false;
      });
    } else {
      setState(() {
        _isLoadingPatients = false;
      });
    }
  }

  Future<void> updateUser() async {
    if (_selectedPatientId == null) return;

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(
      'https://smart-medicine-topaz.vercel.app/api/patients/edit',
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id": _selectedPatientId,
        "username": _usernameController.text.trim().isEmpty
            ? _oldUsername
            : _usernameController.text.trim(),
        "password": _passwordController.text.trim(),
        "tel": _telController.text.trim(),
        "caretaker_name": widget.user["username"],
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
          content: Text("แก้ไขผู้ป่วยสำเร็จ"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("แก้ไขไม่สำเร็จ: ${response.body}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _telController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แก้ไขผู้ป่วย')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _isLoadingPatients
                    ? const CircularProgressIndicator()
                    : DropdownButtonFormField<String>(
                        value: _selectedPatientId,
                        items: _patients
                            .map(
                              (patient) => DropdownMenuItem(
                                value: patient["user_id"].toString(),
                                child: Text(patient["username"]),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPatientId = value;

                            // ✅ เก็บชื่อเดิมตอนเลือก
                            final selected = _patients.firstWhere(
                              (p) => p["user_id"].toString() == value,
                            );
                            _oldUsername = selected["username"].toString();
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'เลือกผู้ป่วย',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null) {
                            return 'กรุณาเลือกผู้ป่วย';
                          }
                          return null;
                        },
                      ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อบัญชีใหม่',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'รหัสผ่านใหม่',
                    border: OutlineInputBorder(),
                  ),
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
                    if (_passwordController.text.isNotEmpty &&
                        value != _passwordController.text) {
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
                            updateUser();
                          }
                        },
                        child: const Text('บันทึกการแก้ไข'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
