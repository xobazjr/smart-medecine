import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditDrugPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const EditDrugPage({super.key, required this.user});

  @override
  State<EditDrugPage> createState() => _EditDrugPageState();
}

class _EditDrugPageState extends State<EditDrugPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _eachController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingPatients = true;
  bool _isLoadingDrugs = false;

  // final String caretakerName = "xobazjr";

  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _drugs = [];

  String? _selectedPatientUsername;
  String? _selectedDrugId;

  @override
  void initState() {
    super.initState();
    fetchPatients();
  }

  Future<void> fetchPatients() async {
    Future<String?> _getToken() async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    }

    final url = Uri.parse(
      'https://smart-medicine-topaz.vercel.app/api/patients/list?caretaker_name=${widget.user["username"]}',
    );

    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer ${await _getToken()}"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _patients = List<Map<String, dynamic>>.from(data);
          _isLoadingPatients = false;
        });
      } else {
        setState(() => _isLoadingPatients = false);
      }
    } catch (e) {
      setState(() => _isLoadingPatients = false);
    }
  }

  Future<void> fetchDrugs(String username) async {
    setState(() => _isLoadingDrugs = true);

    final url = Uri.parse(
      'https://smart-medicine-topaz.vercel.app/api/medicine/list?caretaker_name=${widget.user["username"]}&piname=$username',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          final user = data.firstWhere(
            (u) => u["username"] == username,
            orElse: () => null,
          );

          setState(() {
            if (user != null && user["drugs"] != null) {
              _drugs = List<Map<String, dynamic>>.from(user["drugs"]);
            } else {
              _drugs = [];
            }

            _isLoadingDrugs = false;
          });
        } else {
          setState(() {
            _drugs = [];
            _isLoadingDrugs = false;
          });
        }
      } else {
        setState(() => _isLoadingDrugs = false);
      }
    } catch (e) {
      setState(() => _isLoadingDrugs = false);
    }
  }

  Future<void> updateDrug() async {
    if (_selectedDrugId == null) return;

    setState(() => _isLoading = true);

    final url = Uri.parse(
      'https://smart-medicine-topaz.vercel.app/api/medicine/edit',
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id": _selectedDrugId,
        "drug_name": _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        "total_drugs": int.tryParse(_totalController.text),
        "each_taken": int.tryParse(_eachController.text),
        "warning": _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
      }),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("แก้ไขยาสำเร็จ"),
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
    _nameController.dispose();
    _totalController.dispose();
    _eachController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แก้ไขยา')),
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
                        value: _selectedPatientUsername,
                        items: _patients
                            .map(
                              (patient) => DropdownMenuItem(
                                value: patient["username"].toString(),
                                child: Text(
                                  patient["username"]?.toString() ?? "",
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPatientUsername = value;
                            _selectedDrugId = null;
                            _drugs.clear();
                          });

                          if (value != null) {
                            fetchDrugs(value);
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'เลือกผู้ป่วย',
                          border: OutlineInputBorder(),
                        ),
                      ),
                const SizedBox(height: 20),
                _isLoadingDrugs
                    ? const CircularProgressIndicator()
                    : DropdownButtonFormField<String>(
                        value: _selectedDrugId,
                        items: _drugs
                            .map(
                              (drug) => DropdownMenuItem(
                                value: drug["drug_id"].toString(),
                                child: Text(
                                  drug["drug_name"]?.toString() ?? "",
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDrugId = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'เลือกยา',
                          border: OutlineInputBorder(),
                        ),
                      ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อยาใหม่',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _totalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'จำนวนยาใหม่',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _eachController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'จำนวนที่กินใหม่',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'รายละเอียดใหม่',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 25),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: updateDrug,
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
