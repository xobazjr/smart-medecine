import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'add_user.dart';
import 'add_drug.dart';
import 'delete_drug.dart';
import 'delete_user.dart';
import 'edit_user.dart';
import 'edit_drug.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<Map<String, dynamic>>? _statusFuture;
  Timer? _timer;

  Future<Map<String, dynamic>> fetchStatus() async {
    final response = await http.get(
      Uri.parse('https://smart-medicine-topaz.vercel.app/api/get_status'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load status');
    }
  }

  @override
  void initState() {
    super.initState();

    _statusFuture = fetchStatus();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _statusFuture = fetchStatus();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('หน้าหลัก')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              FutureBuilder<Map<String, dynamic>>(
                future: _statusFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final status = snapshot.data!;

                    return Column(
                      children: [
                        Text(
                          status["is_online"] == true
                              ? "สถานะบอร์ด: ออนไลน์"
                              : "สถานะบอร์ด: ออฟไลน์",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: status["is_online"] == true
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Last seen: ${status["last_seen"]}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "วันที่: ${status["date"]}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          "เวลา: ${status["time"]}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    );
                  } else if (snapshot.hasError) {
                    return Text('เกิดข้อผิดพลาด: ${snapshot.error}');
                  }

                  return const CircularProgressIndicator();
                },
              ),

              const SizedBox(height: 30),

              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  // กล่องที่ 1 เพิ่มยา
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddDrugPage(user: widget.user),
                        ),
                      );
                    },
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.medication,
                            color: Color(0xFF9BD2F2),
                            size: 50,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "เพิ่มยา",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // กล่องที่ 2 ลบยา
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DeleteDrugPage(user: widget.user),
                        ),
                      );
                    },
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.delete,
                            color: Color(0xFF9BD2F2),
                            size: 50,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "ลบยา",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // กล่องที่ 3 เพิ่มผู้ใช้งาน
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddUserPage(user: widget.user),
                        ),
                      );
                    },
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.person_add,
                            color: Color(0xFF9BD2F2),
                            size: 50,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "เพิ่มผู้ป่วย",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // กล่องที่ 4 ลบผู้ใช้งาน
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DeleteUserPage(user: widget.user),
                        ),
                      );
                    },
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.person_remove,
                            color: Color(0xFF9BD2F2),
                            size: 50,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "ลบผู้ป่วย",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // กล่องที่ 5 แก้ไขผู้ใช้งาน
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditUserPage(user: widget.user),
                        ),
                      );
                    },
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.person_search,
                            color: Color(0xFF9BD2F2),
                            size: 50,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "แก้ไขผู้ป่วย",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // กล่องที่ 6 แก้ไขยา
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditDrugPage(user: widget.user),
                        ),
                      );
                    },
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.medical_services,
                            color: Color(0xFF9BD2F2),
                            size: 50,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "แก้ไขยา",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
