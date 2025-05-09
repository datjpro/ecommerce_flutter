import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BottomWidget extends StatefulWidget {
  final VoidCallback? onHomeTap;
  BottomWidget({this.onHomeTap});

  @override
  _BottomWidgetState createState() => _BottomWidgetState();
}

class _BottomWidgetState extends State<BottomWidget> {
  int _selectedIndex = 0;

  final List<String> _routes = ['/home', '/chat', '/notifications', '/account'];

  void _updateSelectedIndex(BuildContext context) {
    final String? route = ModalRoute.of(context)?.settings.name;
    if (route != null) {
      final idx = _routes.indexOf(route);
      if (idx != -1 && idx != _selectedIndex) {
        setState(() {
          _selectedIndex = idx;
        });
      }
    }
  }

  void _onItemTapped(int index) async {
    if (_selectedIndex == index) {
      if (index == 0 && widget.onHomeTap != null) {
        widget.onHomeTap!(); // Scroll lên đầu nếu đang ở Home
      }
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
    if (index == 3) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        Navigator.pushNamed(context, '/login');
      } else {
        Navigator.pushNamed(context, '/account');
      }
    } else {
      Navigator.pushNamed(context, _routes[index]);
      if (index == 0 && widget.onHomeTap != null) {
        // Đợi chuyển trang xong rồi scroll lên đầu
        Future.delayed(Duration(milliseconds: 300), () {
          widget.onHomeTap!();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _updateSelectedIndex(context); // Cập nhật index mỗi lần build
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      selectedItemColor: Colors.orange,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Trò chuyện'),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Thông báo',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
      ],
    );
  }
}
