import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  Map<String, dynamic>? customerData;
  bool loading = true;
  String? error;
  bool updating = false;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  String gender = 'Nam';
  String? userId;

  @override
  void initState() {
    super.initState();
    fetchCustomerInfo();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    birthdayController.dispose();
    super.dispose();
  }

  Future<void> fetchCustomerInfo() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('userId');
      if (userId == null || userId!.isEmpty) {
        setState(() {
          error = "Không tìm thấy userId đăng nhập";
          loading = false;
        });
        return;
      }

      final url = Uri.parse(
        'http://localhost:3002/api/customer/by-user/$userId',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        customerData = json.decode(response.body);
        fullNameController.text = customerData!['fullName'] ?? '';
        phoneController.text = customerData!['phone'] ?? '';
        addressController.text = customerData!['address'] ?? '';
        birthdayController.text =
            customerData!['birthday'] != null
                ? customerData!['birthday'].toString().substring(0, 10)
                : '';
        gender = customerData!['gender'] ?? 'Nam';

        setState(() {
          loading = false;
        });
      } else {
        setState(() {
          error = "Không tìm thấy thông tin khách hàng";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Lỗi kết nối: $e";
        loading = false;
      });
    }
  }

  Future<void> updateCustomerInfo() async {
    setState(() {
      updating = true;
    });

    final url = Uri.parse(
      'http://localhost:3002/api/customer/update-by-user/$userId',
    );
    final body = json.encode({
      "fullName": fullNameController.text,
      "phone": phoneController.text,
      "address": addressController.text,
      "birthday": birthdayController.text,
      "gender": gender,
    });

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        await fetchCustomerInfo();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cập nhật thành công!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật thất bại: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
    } finally {
      setState(() {
        updating = false;
      });
    }
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.person, size: 40, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullNameController.text.isNotEmpty
                        ? fullNameController.text
                        : "Khách hàng",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    customerData?['email'] ?? "",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    phoneController.text,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        onTap: onTap,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blue.shade700),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade700,
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(child: Text(error!))
              : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListView(
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: fullNameController,
                              label: 'Họ tên',
                              icon: Icons.person_outline,
                            ),
                            _buildTextField(
                              controller: phoneController,
                              label: 'Số điện thoại',
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                            ),
                            _buildTextField(
                              controller: addressController,
                              label: 'Địa chỉ',
                              icon: Icons.location_on_outlined,
                            ),
                            _buildTextField(
                              controller: birthdayController,
                              label: 'Ngày sinh (YYYY-MM-DD)',
                              icon: Icons.cake_outlined,
                              readOnly: true,
                              onTap: () async {
                                FocusScope.of(
                                  context,
                                ).requestFocus(FocusNode());
                                DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      birthdayController.text.isNotEmpty
                                          ? DateTime.parse(
                                            birthdayController.text,
                                          )
                                          : DateTime(1990, 1, 1),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  birthdayController.text = picked
                                      .toIso8601String()
                                      .substring(0, 10);
                                }
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: DropdownButtonFormField<String>(
                                value: gender,
                                items:
                                    ['Nam', 'Nữ', 'Khác']
                                        .map(
                                          (g) => DropdownMenuItem(
                                            value: g,
                                            child: Text(g),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    gender = value!;
                                  });
                                },
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.wc,
                                    color: Colors.blue.shade700,
                                  ),
                                  labelText: 'Giới tính',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon:
                                    updating
                                        ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                        : const Icon(Icons.save_alt),
                                label: const Text(
                                  'Lưu thay đổi',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  backgroundColor: Colors.blue.shade700,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: updating ? null : updateCustomerInfo,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
