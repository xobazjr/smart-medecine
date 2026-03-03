import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddDrugPage extends StatefulWidget {
  const AddDrugPage({super.key});

  @override
  State<AddDrugPage> createState() => _AddDrugPageState();
}

class _AddDrugPageState extends State<AddDrugPage> {
  final _formKey = GlobalKey<FormState>();

  TimeOfDay _timeOfDay = TimeOfDay.now();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _eachController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();

  List<String> _patients = [];
  String? _selectedPatient;

  bool _isLoading = false;
  bool _isLoadingPatients = true;

  @override
  void initState() {
    super.initState();
    fetchPatients();
  }

  Future<void> fetchPatients() async {
    final response = await http.get(
      Uri.parse(
        'https://smart-medicine-topaz.vercel.app/api/patients/list?caretaker_name=xobazjr',
      ),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        _patients = data.map<String>((e) => e["username"].toString()).toList();
        _isLoadingPatients = false;
      });
    } else {
      setState(() {
        _isLoadingPatients = false;
      });
    }
  }

  Future<void> selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _dateController.text = picked.toString().split(' ')[0];
      });
    }
  }

  Future<void> selectTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _timeOfDay,
    );

    if (picked != null) {
      setState(() {
        _timeOfDay = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  Future<void> addDrug() async {
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("กรุณาเลือกผู้ป่วย")));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(
      'https://smart-medicine-topaz.vercel.app/api/medicine/add',
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "drug_name": _nameController.text,
        "start_date": _dateController.text,
        "start_time": _timeController.text,
        "total_drugs": int.parse(_totalController.text),
        "each_taken": int.parse(_eachController.text),
        "description": _descController.text,
        "warning": _descController.text,
        "image_url": _imageController.text,
        "take_morning": 1,
        "take_noon": 0,
        "take_evening": 0,
        "take_bedtime": 0,
        "timing": "after",
        "frequency": "daily",
        "username": _selectedPatient,
      }),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 201) {
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalController.dispose();
    _eachController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _descController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มยา')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _isLoadingPatients
                    ? const CircularProgressIndicator()
                    : DropdownButtonFormField<String>(
                        value: _selectedPatient,
                        items: _patients
                            .map(
                              (username) => DropdownMenuItem(
                                value: username,
                                child: Text(username),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPatient = value;
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
                const SizedBox(height: 15),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อยา',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกชื่อยา';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _totalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'จำนวนยาทั้งหมด',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _eachController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'จำนวนยาที่ต้องกิน',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: selectDate,
                  decoration: const InputDecoration(
                    labelText: 'เลือกวันที่',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _timeController,
                  readOnly: true,
                  onTap: selectTime,
                  decoration: const InputDecoration(
                    labelText: 'เลือกเวลา',
                    prefixIcon: Icon(Icons.access_time),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _descController,
                  minLines: 4,
                  maxLines: 8,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    hintText: 'รายละเอียดยา',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _imageController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'ลิงก์รูปภาพ',
                    prefixIcon: Icon(Icons.image),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกลิงก์รูปภาพ';
                    }

                    final uri = Uri.tryParse(value.trim());

                    if (uri == null ||
                        !uri.hasAbsolutePath ||
                        !(uri.scheme == 'http' || uri.scheme == 'https')) {
                      return 'กรุณากรอก URL ให้ถูกต้อง (ต้องขึ้นต้นด้วย http หรือ https)';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            await addDrug();
                          }
                        },
                        child: const Text('บันทึก'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
