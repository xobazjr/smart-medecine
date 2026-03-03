import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DeleteUserPage extends StatefulWidget {
  const DeleteUserPage({super.key});

  @override
  State<DeleteUserPage> createState() => _DeleteUserPageState();
}

class _DeleteUserPageState extends State<DeleteUserPage> {
  late Future<List<dynamic>> futureUsers;
  int? deletingUserId;

  @override
  void initState() {
    super.initState();
    futureUsers = fetchUsers();
  }

  Future<List<dynamic>> fetchUsers() async {
    final response = await http.get(
      Uri.parse(
        'https://smart-medicine-topaz.vercel.app/api/patients/list?caretaker_name=xobazjr',
      ),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<void> deleteUser(int userId) async {
    setState(() {
      deletingUserId = userId;
    });

    final response = await http.post(
      Uri.parse('https://smart-medicine-topaz.vercel.app/api/patients/delete'),
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
        const SnackBar(
          content: Text('ลบผู้ใช้ไม่สำเร็จ'),
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
                    subtitle: Text("ลบบัญชีนี้ออกจากระบบ"),
                    trailing: deletingUserId == user["user_id"]
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('ยืนยันการลบ'),
                                  content: Text(
                                    'คุณต้องการลบ ${user["username"]} ใช่หรือไม่?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('ยกเลิก'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        deleteUser(user["user_id"]);
                                      },
                                      child: const Text(
                                        'ลบ',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
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
