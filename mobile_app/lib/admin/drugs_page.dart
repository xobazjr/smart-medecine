import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DrugsPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const DrugsPage({super.key, required this.user});

  @override
  State<DrugsPage> createState() => _AdminDrugsPageState();
}

class _AdminDrugsPageState extends State<DrugsPage> {
  late Future<List<dynamic>> futureUsers;

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

  String getTimeText(drug) {
    List<String> times = [];

    if (drug["take_morning"] == true) {
      times.add("เช้า ${drug["morning_time"] ?? ""}");
    }
    if (drug["take_noon"] == true) {
      times.add("กลางวัน ${drug["noon_time"] ?? ""}");
    }
    if (drug["take_evening"] == true) {
      times.add("เย็น ${drug["evening_time"] ?? ""}");
    }
    if (drug["take_bedtime"] == true) {
      times.add("ก่อนนอน ${drug["bedtime_time"] ?? ""}");
    }

    return times.join(" | ");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายการยา')),
      body: FutureBuilder<List<dynamic>>(
        future: futureUsers,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final users = snapshot.data!;

            return ListView(
              children: users.map((user) {
                final drugs = user["drugs"]
                    .where((drug) => drug["total_drugs"] != 0)
                    .toList();

                if (drugs.isEmpty) return const SizedBox();

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user["username"],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      ...drugs.map<Widget>((drug) {
                        return Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.medication,
                                  size: 40,
                                  color: Colors.blue,
                                ),

                                title: Text(
                                  drug["drug_name"],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("จำนวนยา: ${drug["total_drugs"]}"),
                                    Text(
                                      "กินครั้งละ: ${drug["each_taken"]} เม็ด",
                                    ),
                                    Text(getTimeText(drug)),
                                  ],
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
          }

          if (snapshot.hasError) {
            return Center(child: Text("${snapshot.error}"));
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
