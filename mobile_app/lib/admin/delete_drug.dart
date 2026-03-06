import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DeleteDrugPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const DeleteDrugPage({super.key, required this.user});

  @override
  State<DeleteDrugPage> createState() => _DeleteDrugPageState();
}

class _DeleteDrugPageState extends State<DeleteDrugPage> {
  late Future<List<dynamic>> futureUsers;

  int? deletingDrugId;

  @override
  void initState() {
    super.initState();
    futureUsers = fetchDrugs();
  }

  Future<List<dynamic>> fetchDrugs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse(
        'https://smart-medicine-topaz.vercel.app/api/medicine/list?caretaker_name=${widget.user["username"]}',
      ),

      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load drugs');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ลบยา')),
      body: FutureBuilder<List<dynamic>>(
        future: futureUsers,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final users = snapshot.data!;

            return ListView(
              children: users.map((user) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user["username"],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...user["drugs"].map<Widget>((drug) {
                        return Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),

                              child: ListTile(
                                title: Text(
                                  drug["drug_name"],
                                  style: const TextStyle(
                                    color: Color(0xFF5F5F5F),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  drug["warning"],
                                  style: const TextStyle(
                                    color: Color(0xFF5F5F5F),
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                tileColor: Colors.white,
                                trailing: deletingDrugId == drug["drug_id"]
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () async {
                                          setState(() {
                                            deletingDrugId = drug["drug_id"];
                                          });

                                          final response = await http.post(
                                            Uri.parse(
                                              'https://smart-medicine-topaz.vercel.app/api/medicine/delete',
                                            ),
                                            headers: {
                                              "Content-Type":
                                                  "application/json",
                                            },
                                            body: jsonEncode({
                                              "id": drug["drug_id"],
                                            }),
                                          );

                                          if (!mounted) return;

                                          if (response.statusCode == 200) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text('ลบยาสำเร็จ'),
                                              ),
                                            );

                                            setState(() {
                                              deletingDrugId = null;
                                              futureUsers = fetchDrugs();
                                            });
                                          } else {
                                            setState(() {
                                              deletingDrugId = null;
                                            });

                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text('ลบยาไม่สำเร็จ'),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                );
              }).toList(),
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
