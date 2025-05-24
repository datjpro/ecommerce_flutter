import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/taskbar_widget.dart';
import '../widgets/bottom_widhet.dart';
import 'setting_screen.dart';
import 'discount_screen.dart';
import 'order_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = 'Khách hàng';
  String _email = '';
  String _avatarUrl = '';
  int _orderCount = 0;
  int _wishlistCount = 0;
  String? _userId; // Thêm biến này

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();

    // Lấy thông tin người dùng từ SharedPreferences
    final username = prefs.getString('username');
    final email = prefs.getString('email');
    final avatarUrl = prefs.getString('avatarUrl');
    final wishlistCount = prefs.getInt('wishlistCount') ?? 0;
    final userId = prefs.getString('userId'); // Lấy userId

    int orderCount = 0;

    if (userId != null) {
      try {
        final url = 'http://localhost:4000/api/order/user/$userId';
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          List<dynamic> fetchedOrders = data is List ? data : [];
          orderCount = fetchedOrders.length;
          await prefs.setInt('orderCount', orderCount);
        }
      } catch (e) {
        // Có thể log lỗi nếu cần
      }
    }

    setState(() {
      _username = username ?? 'Khách hàng';
      _email = email ?? '';
      _avatarUrl = avatarUrl ?? '';
      _orderCount = orderCount;
      _wishlistCount = wishlistCount;
      _userId = userId; // Cập nhật userId
    });
  }

  void _navigateToSetting(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingScreen()),
    ).then((_) {
      // Tải lại thông tin người dùng khi quay lại từ màn hình cài đặt
      _loadUserInfo();
    });
  }

  Future<void> _logout(BuildContext context) async {
    // Hiển thị hộp thoại xác nhận
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Xác nhận đăng xuất'),
            content: Text('Bạn có chắc chắn muốn đăng xuất không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('userId');
      await prefs.remove('email');
      await prefs.remove('username');
      await prefs.remove('avatarUrl');

      // Đảm bảo widget vẫn được mount trước khi navigate
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            TaskbarWidget(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadUserInfo,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Header section with user info
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 24.0,
                          horizontal: 16.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.orange.shade100,
                              backgroundImage:
                                  _avatarUrl.isNotEmpty
                                      ? NetworkImage(_avatarUrl)
                                      : null,
                              child:
                                  _avatarUrl.isEmpty
                                      ? Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.orange.shade800,
                                      )
                                      : null,
                            ),
                            SizedBox(height: 16),
                            Text(
                              _username,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            if (_email.isNotEmpty) ...[
                              SizedBox(height: 4),
                              Text(
                                _email,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                            // Thêm dòng này để hiển thị userId
                            if (_userId != null && _userId!.isNotEmpty) ...[
                              SizedBox(height: 4),
                              Text(
                                'User ID: $_userId',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _navigateToSetting(context),
                              icon: Icon(Icons.edit, size: 18),
                              label: Text('Chỉnh sửa hồ sơ'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      // Dashboard counters
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildDashboardItem(
                                context,
                                icon: Icons.receipt_long,
                                title: 'Đơn hàng',
                                count: _orderCount,
                                color: Colors.blue,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _buildDashboardItem(
                                context,
                                icon: Icons.favorite,
                                title: 'Yêu thích',
                                count: _wishlistCount,
                                color: Colors.red,
                                onTap: () {},
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Menu items
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            
                            _buildDivider(),
                            _buildMenuItem(
                              icon: Icons.favorite,
                              title: 'Sản phẩm yêu thích',
                              subtitle:
                                  'Quản lý danh sách sản phẩm bạn quan tâm',
                              iconColor: Colors.red,
                              onTap: () {},
                            ),
                            _buildDivider(),
                            _buildMenuItem(
                              icon: Icons.local_offer,
                              title: 'Khuyến mãi',
                              subtitle: 'Xem các ưu đãi và mã giảm giá',
                              iconColor: Colors.green,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DiscountScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildDivider(),
                            _buildMenuItem(
                              icon: Icons.help_outline,
                              title: 'Trợ giúp & Hỗ trợ',
                              subtitle: 'Câu hỏi thường gặp, liên hệ hỗ trợ',
                              iconColor: Colors.purple,
                              onTap: () {},
                            ),
                            _buildDivider(),
                            _buildMenuItem(
                              icon: Icons.logout,
                              title: 'Đăng xuất',
                              subtitle: 'Đăng xuất khỏi tài khoản của bạn',
                              iconColor: Colors.red,
                              onTap: () => _logout(context),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Version info
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Text(
                          'Phiên bản ứng dụng: 1.0.0',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
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

  Widget _buildDashboardItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            SizedBox(height: 12),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Colors.grey.shade800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey.shade400,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 20,
      endIndent: 20,
      color: Colors.grey.shade200,
    );
  }
}
