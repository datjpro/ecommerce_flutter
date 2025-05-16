import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/taskbar_widget.dart';
import '../widgets/bottom_widhet.dart';
import 'setting_screen.dart';
import 'discount_screen.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userId = 'Không xác định';
  String _email = 'email@example.com';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId');
  print('DEBUG: userId from SharedPreferences: $userId');
  setState(() {
    _userId = userId ?? 'Không xác định';
    _email = prefs.getString('email') ?? 'email@example.com';
  });
}


  void _navigateToSetting(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingScreen()),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token'); // Xóa token
    await prefs.remove('userId'); // Xóa userId
    await prefs.remove('email'); // Xóa email
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/home',
      (route) => false,
    ); // Quay về HomeScreen và xóa stack
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            TaskbarWidget(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 24),
                      CircleAvatar(
                        radius: 48,
                        // Thay bằng ảnh thật nếu có
                        backgroundColor: Colors.orange[100],
                      ),
                      SizedBox(height: 16),
                      Text(
  'ID người dùng: $_userId',
  style: TextStyle(
    fontSize: 16,
    color: Colors.grey[800],
    fontWeight: FontWeight.w500,
  ),
),

                      SizedBox(height: 8),
                      Text(
                        _email,
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _navigateToSetting(context),
                        icon: Icon(Icons.settings),
                        label: Text('Chỉnh sửa thông tin'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      SizedBox(height: 32),
                      // Thêm các mục khác nếu muốn
                      ListTile(
                        leading: Icon(Icons.history, color: Colors.orange),
                        title: Text('Lịch sử đơn hàng'),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {},
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.favorite, color: Colors.red),
                        title: Text('Sản phẩm yêu thích'),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {},
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.local_offer, color: Colors.green),
                        title: Text('Khuyến mãi'),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => DiscountScreen()),
                          );
                        },
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.help, color: Colors.blue),
                        title: Text('Trợ giúp'),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {},
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.logout, color: Colors.red),
                        title: Text('Đăng xuất'),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          _logout(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomWidget(),
    );
  }
}