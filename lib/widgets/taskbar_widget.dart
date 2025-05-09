import 'package:flutter/material.dart';

class TaskbarWidget extends StatelessWidget {
  final bool showBack;
  final VoidCallback? onBack;
  final Color backgroundColor;
  final double elevation;
  final List<Map<String, dynamic>> cartItems; // Dữ liệu giỏ hàng

  const TaskbarWidget({
    Key? key,
    this.showBack = false,
    this.onBack,
    this.backgroundColor = Colors.orange,
    this.elevation = 4.0,
    this.cartItems = const [
      {'id': 1, 'quantity': 2},
      {'id': 2, 'quantity': 1},
    ],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Tính tổng số lượng sản phẩm trong giỏ hàng
    final totalCartItems = cartItems.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int),
    );

    return Material(
      elevation: elevation,
      color: backgroundColor,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Nút Back
            if (showBack)
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: onBack ?? () => Navigator.pop(context),
                splashRadius: 24,
              )
            else
              const SizedBox(
                width: 48,
              ), // Giữ khoảng cách khi không có nút back
            // Search Bar
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Tìm sản phẩm, thương hiệu và tên shop',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                  onTap: () {
                    // Có thể thêm logic khi focus vào search bar
                  },
                ),
              ),
            ),
            // Cart Icon
            Container(
              width: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                    onPressed: () => Navigator.pushNamed(context, '/cart'),
                    splashRadius: 24,
                  ),
                  if (totalCartItems > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          totalCartItems > 99 ? '99+' : '$totalCartItems',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
