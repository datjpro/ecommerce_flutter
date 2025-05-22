import 'package:ecommerce_flutter/screens/order_create_screen.dart';
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
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text('Bạn cần đăng nhập để thêm vào giỏ hàng')),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: 'ĐĂNG NHẬP',
          onPressed: () {
            Navigator.pushNamed(context, '/login');
          },
          textColor: Colors.white,
        ),
      ),
    );
    return;
  }

  try {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3003/api/cart/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'productId': product['_id'],
        'quantity': quantity,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Đã thêm $quantity sản phẩm vào giỏ hàng'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          action: SnackBarAction(
            label: 'XEM GIỎ HÀNG',
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
            textColor: Colors.white,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Lỗi khi thêm vào giỏ hàng: ${response.body}'),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text('Lỗi kết nối: $e')),
          ],
        ),
        backgroundColor: Colors.red.shade700,
      ),
    );
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
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3003/api/cart/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          cartItems = data['items'] ?? [];
          isLoading = false;
        });
        _updateTotal();
      } else {
        setState(() {
          cartItems = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading cart: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Không thể tải giỏ hàng: $e')),
            ],
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
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

  Future<void> handleUpdateQuantity(String cartItemId, int newQuantity) async {
    if (userId == null) return;
    if (newQuantity < 1) return;

    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:3003/api/cart/updateCart/$cartItemId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'quantity': newQuantity}),
      );

      if (response.statusCode == 200) {
        // Cập nhật trực tiếp trên UI, không load lại toàn bộ cart
        setState(() {
          final index = cartItems.indexWhere(
            (item) => item['_id'] == cartItemId,
          );
          if (index != -1) {
            cartItems[index]['quantity'] = newQuantity;
          }
        });
        _updateTotal();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Không thể cập nhật số lượng sản phẩm'),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Lỗi kết nối: $e')),
            ],
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> handleIncrease(String cartItemId, int currentQuantity) async {
    await handleUpdateQuantity(cartItemId, currentQuantity + 1);
  }

  Future<void> handleDecrease(String cartItemId, int currentQuantity) async {
    if (currentQuantity > 1) {
      await handleUpdateQuantity(cartItemId, currentQuantity - 1);
    }
  }

  Future<void> handleDelete(String cartItemId, {bool reloadCart = true}) async {
    try {
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:3003/api/cart/deleteCart/$cartItemId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Đã xóa sản phẩm khỏi giỏ hàng'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            duration: Duration(seconds: 2),
            action: SnackBarAction(
              label: 'HOÀN TÁC',
              textColor: Colors.white,
              onPressed: () {
                _loadCart(); // Reload cart to undo deletion
              },
            ),
          ),
        );

        // Only reload cart if flag is true
        if (reloadCart) {
          await _loadCart();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Lỗi khi xóa sản phẩm: $e')),
            ],
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void handleBuyNow() {
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Vui lòng chọn ít nhất một sản phẩm'),
            ],
          ),
          backgroundColor: Colors.blue.shade600,
        ),
      );
      return;
    }

    final selectedCartItems =
        cartItems
            .where(
              (item) =>
                  selectedItems.contains(item['productId']['_id'].toString()),
            )
            .toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => OrderCreateScreen(
              selectedItems: selectedCartItems,
              totalPrice: totalSelectedPrice,
            ),
      ),
    );
  }

  String formatCurrency(dynamic price) {
    if (price == null) return '₫0';
    return '₫${price.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Giỏ hàng'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0.5,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Theme.of(context).primaryColor),
              SizedBox(height: 16),
              Text(
                'Đang tải giỏ hàng...',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (cartItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Giỏ hàng'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0.5,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 100,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: 24),
              Text(
                'Giỏ hàng của bạn đang trống',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Hãy thêm sản phẩm vào giỏ hàng để mua sắm',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/products');
                },
                icon: Icon(Icons.shopping_bag),
                label: Text('Tiếp tục mua sắm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Giỏ hàng (${cartItems.length})',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed:
                selectedItems.isEmpty
                    ? null
                    : () async {
                      bool? confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: Text('Xác nhận xóa'),
                              content: Text(
                                'Bạn có chắc muốn xóa ${selectedItems.length} sản phẩm đã chọn?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(false),
                                  child: Text('HỦY'),
                                ),
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(true),
                                  child: Text(
                                    'XÓA',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                      );

                      if (confirm == true) {
                        // Delete selected items
                        // Implementation not shown here
                      }
                    },
            color: selectedItems.isEmpty ? Colors.grey : Colors.red,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header: Select All with Material design card
          Card(
            margin: EdgeInsets.all(8),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Checkbox(
                    value:
                        cartItems.isNotEmpty &&
                        selectedItems.length == cartItems.length,
                    onChanged: (_) => handleSelectAll(),
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  Text(
                    'Chọn tất cả sản phẩm',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Spacer(),
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue.shade600,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Vuốt để xóa',
                    style: TextStyle(color: Colors.blue.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

          // Cart Items
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

                // Use Dismissible for swipe-to-delete
                return Dismissible(
                  key: Key(item['_id'].toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.delete, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Xóa',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onDismissed: (direction) {
                    // Xóa item khỏi danh sách trước khi gọi API
                    setState(() {
                      // Cập nhật danh sách selected items
                      selectedItems.removeWhere(
                        (id) => id == product['_id'].toString(),
                      );

                      // Xóa item từ giao diện ngay lập tức
                      cartItems.removeAt(index);
                    });

                    // Sau đó mới gọi API xóa
                    handleDelete(item['_id'].toString(), reloadCart: false);
                  },
                  confirmDismiss: (DismissDirection direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text("Xác nhận xóa"),
                          content: Text(
                            "Bạn có chắc muốn xóa sản phẩm này khỏi giỏ hàng?",
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text("HỦY"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(
                                "XÓA",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Card(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 1,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Checkbox
                          Checkbox(
                            value: isSelected,
                            onChanged:
                                (_) =>
                                    handleSelectItem(product['_id'].toString()),
                            activeColor: Theme.of(context).primaryColor,
                          ),
                          // Product image with rounded corners
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 80,
                              height: 80,
                              child:
                                  productImage.isNotEmpty
                                      ? Image.network(
                                        productImage,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  color: Colors.grey.shade200,
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    size: 40,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                ),
                                      )
                                      : Container(
                                        color: Colors.grey.shade200,
                                        child: Icon(
                                          Icons.image_not_supported,
                                          size: 40,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                            ),
                          ),
                          SizedBox(width: 12),
                          // Product details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['name'] ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Text(
                                        product['status'] ?? 'Còn hàng',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                    if (product['brand'] != null) ...[
                                      SizedBox(width: 6),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          product['brand'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  formatCurrency(product['price']),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                SizedBox(height: 8),
                                // Quantity selector
                                Row(
                                  children: [
                                    _buildQuantityButton(
                                      Icons.remove,
                                      () => handleDecrease(
                                        item['_id'].toString(),
                                        item['quantity'],
                                      ),
                                      item['quantity'] <= 1,
                                    ),
                                    Container(
                                      width: 40,
                                      height: 32,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          top: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                          bottom: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        '${item['quantity']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    _buildQuantityButton(
                                      Icons.add,
                                      () => handleIncrease(
                                        item['_id'].toString(),
                                        item['quantity'],
                                      ),
                                      false,
                                    ),
                                    Spacer(),
                                    // Total price
                                    Text(
                                      formatCurrency(
                                        product['price'] * item['quantity'],
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.red.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Checkout summary
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            padding: EdgeInsets.all(16),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Order summary section
                  Row(
                    children: [
                      Checkbox(
                        value:
                            cartItems.isNotEmpty &&
                            selectedItems.length == cartItems.length,
                        onChanged: (_) => handleSelectAll(),
                        activeColor: Theme.of(context).primaryColor,
                      ),
                      Text(
                        'Tất cả (${selectedItems.length}/${cartItems.length})',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Tổng thanh toán:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            formatCurrency(totalSelectedPrice),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Checkout button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedItems.isEmpty ? null : handleBuyNow,
                      child: Text(
                        'TIẾN HÀNH ĐẶT HÀNG (${selectedItems.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ),
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
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          color: isDisabled ? Colors.grey.shade100 : Colors.white,
          borderRadius:
              icon == Icons.remove
                  ? BorderRadius.horizontal(left: Radius.circular(4))
                  : BorderRadius.horizontal(right: Radius.circular(4)),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDisabled ? Colors.grey.shade400 : Colors.grey.shade700,
        ),
      ),
    );
  }
}
