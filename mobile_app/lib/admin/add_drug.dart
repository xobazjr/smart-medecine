import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddDrugPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const AddDrugPage({super.key, required this.user});

  @override
  State<AddDrugPage> createState() => _AddDrugPageState();
}

class _AddDrugPageState extends State<AddDrugPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _eachController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String? _selectedPatient;
  String _timing = "after";

  bool _isLoading = false;

  final List<String> _patients = ["ahgong", "ugay"];

  Set<String> _selectedTimes = {};

  /// fixed alarm times
  final Map<String, String> fixedTimes = {
    "Morning": "08:00",
    "Noon": "12:00",
    "Evening": "18:00",
    "Bedtime": "21:00",
  };

  /// เพิ่มยา
  Future<void> addDrug() async {
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("กรุณาเลือกผู้ป่วย")));
      return;
    }

    if (_selectedPatient != "ahgong") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("ยังไม่ติดตั้งอุปกรณ์"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedTimes.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("กรุณาเลือกช่วงเวลากินยา")));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final url = Uri.parse(
      "https://smart-medicine-topaz.vercel.app/api/medicine/add",
    );

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "drug_name": _nameController.text,
        "start_date": DateTime.now().toIso8601String(),
        "start_time": "08:00",
        "total_drugs": int.tryParse(_totalController.text) ?? 0,
        "each_taken": int.tryParse(_eachController.text) ?? 0,
        "description": _descController.text,
        "warning": _descController.text,
        "image_url": "",
        "timing": _timing,
        "frequency": "daily",
        "username": _selectedPatient,
        "take_morning": _selectedTimes.contains("Morning"),
        "take_noon": _selectedTimes.contains("Noon"),
        "take_evening": _selectedTimes.contains("Evening"),
        "take_bedtime": _selectedTimes.contains("Bedtime"),
      }),
    );

    print("STATUS = ${response.statusCode}");
    print("BODY = ${response.body}");

    if (response.statusCode == 201) {
      await sendMqtt();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("เพิ่มยาสำเร็จ"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("เพิ่มยาไม่สำเร็จ"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// ดึงยา + ส่ง MQTT
  Future<void> sendMqtt() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final listRes = await http.get(
      Uri.parse(
        "https://smart-medicine-topaz.vercel.app/api/medicine/list?caretaker_name=${widget.user["username"]}",
      ),
      headers: {"Authorization": "Bearer $token"},
    );

    if (listRes.statusCode != 200) return;

    final data = jsonDecode(listRes.body);

    List alarms = [];

    for (var user in data) {
      if (user["username"] == "ahgong") {
        for (var drug in user["drugs"]) {
          if (drug["total_drugs"] != 0) {
            if (drug["take_morning"] == true) {
              alarms.add({"name": drug["drug_name"], "time": "08:00"});
            }

            if (drug["take_noon"] == true) {
              alarms.add({"name": drug["drug_name"], "time": "12:00"});
            }

            if (drug["take_evening"] == true) {
              alarms.add({"name": drug["drug_name"], "time": "18:00"});
            }

            if (drug["take_bedtime"] == true) {
              alarms.add({"name": drug["drug_name"], "time": "21:00"});
            }
          }
        }
      }
    }

    final mqttRes = await http.post(
      Uri.parse("https://smart-medicine-topaz.vercel.app/api/mqtt/set_box"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"username": "ahgong", "alarms": alarms}),
    );

    print("MQTT STATUS ${mqttRes.statusCode}");
    print(mqttRes.body);
  }

  Widget buildTimeButton(String label, String value) {
    final selected = _selectedTimes.contains(value);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (selected) {
              _selectedTimes.remove(value);
            } else {
              _selectedTimes.add(value);
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.deepPurple : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(color: selected ? Colors.white : Colors.black),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("เพิ่มยา")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedPatient,
              items: _patients.map((p) {
                return DropdownMenuItem(value: p, child: Text(p));
              }).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedPatient = v;
                });
              },
              decoration: const InputDecoration(
                labelText: "เลือกผู้ป่วย",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "ชื่อยา",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: _totalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "จำนวนยา",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: _eachController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "กินครั้งละ",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text("ก่อน / หลังอาหาร"),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _timing == "before"
                          ? Colors.deepPurple
                          : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _timing = "before";
                      });
                    },
                    child: const Text("ก่อนอาหาร"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _timing == "after"
                          ? Colors.deepPurple
                          : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _timing = "after";
                      });
                    },
                    child: const Text("หลังอาหาร"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text("ช่วงเวลากินยา"),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                buildTimeButton("เช้า", "Morning"),
                const SizedBox(width: 8),
                buildTimeButton("กลางวัน", "Noon"),
                const SizedBox(width: 8),
                buildTimeButton("เย็น", "Evening"),
                const SizedBox(width: 8),
                buildTimeButton("ก่อนนอน", "Bedtime"),
              ],
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "รายละเอียดยา",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: addDrug,
                    child: const Text("บันทึก"),
                  ),
          ],
        ),
      ),
    );
  }
}
