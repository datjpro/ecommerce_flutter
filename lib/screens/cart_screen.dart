import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Hàm sửa đổi để kiểm tra và tạo giỏ hàng nếu cần
Future<void> addToCart(Map product, int quantity, BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId');
  if (userId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bạn cần đăng nhập để thêm vào giỏ hàng')),
    );
    return;
  }

  try {
    final response = await http.post(
      Uri.parse('http://localhost:3003/api/cart/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'productId': product['_id'],
        'quantity': quantity,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm $quantity sản phẩm vào giỏ hàng')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi thêm vào giỏ hàng: ${response.body}')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
  }
}

class CartScreen extends StatefulWidget {
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<dynamic> cartItems = [];
  Set<String> selectedItems = {};
  bool isLoading = true;
  double totalSelectedPrice = 0;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() {
      isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
    if (userId == null) {
      setState(() {
        isLoading = false;
      });
      // Xử lý khi chưa đăng nhập
      return;
    }
    final response = await http.get(
      Uri.parse('http://localhost:3003/api/cart/user/$userId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // data['products'] là danh sách sản phẩm trong giỏ
      setState(() {
        cartItems = data['products'] ?? [];
        isLoading = false;
      });
      _updateTotal();
    } else {
      setState(() {
        cartItems = [];
        isLoading = false;
      });
    }
  }

  void handleSelectItem(String productId) {
    setState(() {
      if (selectedItems.contains(productId)) {
        selectedItems.remove(productId);
      } else {
        selectedItems.add(productId);
      }
      _updateTotal();
    });
  }

  void handleSelectAll() {
    setState(() {
      if (selectedItems.length == cartItems.length) {
        selectedItems.clear();
      } else {
        selectedItems =
            cartItems
                .map((item) => item['productId']['_id'].toString())
                .toSet();
      }
      _updateTotal();
    });
  }

  void _updateTotal() {
    double total = 0;
    for (var item in cartItems) {
      if (selectedItems.contains(item['productId']['_id'].toString())) {
        total += (item['productId']['price'] ?? 0) * (item['quantity'] ?? 1);
      }
    }
    setState(() {
      totalSelectedPrice = total;
    });
  }

  Future<void> handleUpdateQuantity(String productId, int newQuantity) async {
    if (userId == null) return;
    if (newQuantity < 1) return;

    try {
      final response = await http.put(
        Uri.parse('http://localhost:3003/api/cart/updateProductInCart'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'productId': productId,
          'quantity': newQuantity,
        }),
      );

      if (response.statusCode == 200) {
        await _loadCart();
      } else {
        await _loadCart();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể cập nhật số lượng sản phẩm')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
    }
  }

  Future<void> handleIncrease(String productId, int currentQuantity) async {
    await handleUpdateQuantity(productId, currentQuantity + 1);
  }

  Future<void> handleDecrease(String productId, int currentQuantity) async {
    if (currentQuantity > 1) {
      await handleUpdateQuantity(productId, currentQuantity - 1);
    }
  }

  Future<void> handleDelete(String cartItemId) async {
    final response = await http.delete(
      Uri.parse('http://localhost:3003/api/cart/deleteCart/$cartItemId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      setState(() {
        // Cập nhật danh sách selected items
        final cartItem = cartItems.firstWhere(
          (item) => item['_id'] == cartItemId,
          orElse: () => null,
        );
        if (cartItem != null) {
          selectedItems.removeWhere(
            (id) => id == cartItem['productId']['_id'].toString(),
          );
        }
      });
      await _loadCart();
    }
  }

  void handleBuyNow() {
    // Chuyển sang trang thanh toán với selectedItems
    // Navigator.pushNamed(context, '/payment');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Giỏ hàng')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (cartItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Giỏ hàng')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
              SizedBox(height: 20),
              Text(
                'Giỏ hàng trống',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/');
                },
                child: Text('Tiếp tục mua sắm'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Giỏ hàng của bạn'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Header: Select All
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Checkbox(
                  value:
                      cartItems.isNotEmpty &&
                      selectedItems.length == cartItems.length,
                  onChanged: (_) => handleSelectAll(),
                ),
                Text(
                  'Chọn tất cả',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          // Cart Items
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                final product = item['productId'];
                final isSelected = selectedItems.contains(
                  product['_id'].toString(),
                );

                // Lấy hình ảnh đầu tiên từ mảng hình ảnh
                final productImage =
                    product['image'] is List && product['image'].isNotEmpty
                        ? product['image'][0]
                        : '';

                return Container(
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: isSelected,
                        onChanged:
                            (_) => handleSelectItem(product['_id'].toString()),
                      ),
                      Container(
                        width: 80,
                        height: 80,
                        margin: EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          image:
                              productImage.isNotEmpty
                                  ? DecorationImage(
                                    image: NetworkImage(productImage),
                                    fit: BoxFit.cover,
                                  )
                                  : null,
                          color: Colors.grey.shade200,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name'] ?? '',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Giá: đ${product['price'] ?? 0}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tình trạng: ${product['status'] ?? 'N/A'}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                _buildQuantityButton(
                                  Icons.remove,
                                  () => handleDecrease(
                                    product['_id'].toString(),
                                    item['quantity'],
                                  ),
                                  item['quantity'] <= 1,
                                ),
                                Container(
                                  width: 40,
                                  height: 30,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    '${item['quantity']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                _buildQuantityButton(
                                  Icons.add,
                                  () => handleIncrease(
                                    product['_id'].toString(),
                                    item['quantity'],
                                  ),
                                  false,
                                ),
                                Spacer(),
                                TextButton(
                                  onPressed:
                                      () =>
                                          handleDelete(item['_id'].toString()),
                                  child: Text(
                                    'Xóa',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Thành tiền: đ${((product['price'] ?? 0) * (item['quantity'] ?? 1)).toString()}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Footer
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Checkbox(
                  value:
                      cartItems.isNotEmpty &&
                      selectedItems.length == cartItems.length,
                  onChanged: (_) => handleSelectAll(),
                ),
                Text('Chọn tất cả (${selectedItems.length})'),
                Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Tổng thanh toán: ',
                            style: TextStyle(color: Colors.black),
                          ),
                          TextSpan(
                            text: 'đ${totalSelectedPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: selectedItems.isEmpty ? null : handleBuyNow,
                      child: Text('Mua hàng'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        disabledBackgroundColor: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(
    IconData icon,
    VoidCallback? onPressed,
    bool isDisabled,
  ) {
    return InkWell(
      onTap: isDisabled ? null : onPressed,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          color: isDisabled ? Colors.grey.shade200 : Colors.white,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isDisabled ? Colors.grey.shade400 : null,
        ),
      ),
    );
  }
}
