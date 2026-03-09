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

  List<dynamic> allUsers = [];
  List<dynamic> filteredUsers = [];

  TextEditingController searchController = TextEditingController();

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
      final data = jsonDecode(response.body);

      allUsers = data;
      filteredUsers = data;

      return data;
    } else {
      throw Exception('Failed to load drugs');
    }
  }

  void searchDrug(String keyword) {
    setState(() {
      if (keyword.isEmpty) {
        filteredUsers = allUsers;
      } else {
        filteredUsers = allUsers.map((user) {
          var drugs = List.from(user["drugs"]).where((drug) {
            return drug["drug_name"].toLowerCase().contains(
              keyword.toLowerCase(),
            );
          }).toList();

          return {"username": user["username"], "drugs": drugs};
        }).toList();
      }
    });
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
            final users = filteredUsers;

            return Column(
              children: [
                /// SEARCH BAR
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: "ค้นหายา",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: searchDrug,
                  ),
                ),

                /// DRUG LIST
                Expanded(
                  child: ListView(
                    children: users.map((user) {
                      final drugs = List.from(
                        user["drugs"],
                      ).where((drug) => drug["total_drugs"] != 0).toList();

                      if (drugs.isEmpty) return const SizedBox();

                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// USER NAME
                            Text(
                              user["username"],
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 10),

                            /// DRUG ITEMS
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

                                    /// MASTER ITEM
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "จำนวนยา: ${drug["total_drugs"]}",
                                          ),
                                          Text(
                                            "กินครั้งละ: ${drug["each_taken"]} เม็ด",
                                          ),
                                          Text(getTimeText(drug)),
                                        ],
                                      ),

                                      /// GO TO DETAIL PAGE
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                DrugDetailPage(drug: drug),
                                          ),
                                        );
                                      },
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
                  ),
                ),
              ],
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

class DrugDetailPage extends StatelessWidget {
  final Map<String, dynamic> drug;

  const DrugDetailPage({super.key, required this.drug});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(drug["drug_name"])),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              drug["drug_name"],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Text("จำนวนยา: ${drug["total_drugs"]} เม็ด"),

            const SizedBox(height: 10),

            Text("กินครั้งละ: ${drug["each_taken"]} เม็ด"),

            const SizedBox(height: 10),

            Text("รายละเอียด: ${drug["description"] ?? "-"}"),

            const SizedBox(height: 10),

            Text("คำเตือน: ${drug["warning"] ?? "-"}"),
          ],
        ),
      ),
    );
  }
}
