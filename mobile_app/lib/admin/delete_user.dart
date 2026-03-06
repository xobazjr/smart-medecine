import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DeleteUserPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const DeleteUserPage({super.key, required this.user});

  @override
  State<DeleteUserPage> createState() => _DeleteUserPageState();
}

class _DeleteUserPageState extends State<DeleteUserPage> {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  late Future<List<dynamic>> futureUsers;

  String? deletingUserId;

  @override
  void initState() {
    super.initState();
    futureUsers = fetchUsers();
  }

  Future<List<dynamic>> fetchUsers() async {
    final response = await http.get(
      Uri.parse(
        'https://smart-medicine-topaz.vercel.app/api/patients/list?caretaker_name=${widget.user["username"]}',
      ),

      headers: {"Authorization": "Bearer ${await _getToken()}"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<void> deleteUser(String userId) async {
    setState(() {
      deletingUserId = userId;
    });

    try {
      final response = await http.post(
        Uri.parse(
          'https://smart-medicine-topaz.vercel.app/api/patients/delete',
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": userId}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ลบผู้ใช้สำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          deletingUserId = null;
          futureUsers = fetchUsers();
        });
      } else {
        setState(() {
          deletingUserId = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        deletingUserId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network Error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ลบผู้ใช้งาน')),
      body: FutureBuilder<List<dynamic>>(
        future: futureUsers,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final users = snapshot.data!;

            if (users.isEmpty) {
              return const Center(child: Text('ไม่มีผู้ใช้งาน'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final userId = user["user_id"].toString();

                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: ListTile(
                    title: Text(
                      user["username"],
                      style: const TextStyle(fontWeight: FontWeight.normal),
                    ),
                    subtitle: const Text("ลบบัญชีนี้ออกจากระบบ"),
                    trailing: deletingUserId == userId
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('ยืนยันการลบ'),
                                  content: Text(
                                    'คุณต้องการลบ ${user["username"]} ใช่หรือไม่?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop(false);
                                      },
                                      child: const Text('ยกเลิก'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop(true);
                                      },
                                      child: const Text(
                                        'ลบ',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              // ถ้ากดยืนยัน
                              if (confirm == true) {
                                deleteUser(userId);
                              }
                            },
                          ),
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
