import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrderCreateScreen extends StatefulWidget {
  final List<dynamic> selectedItems;
  final double totalPrice;

  const OrderCreateScreen({
    Key? key,
    required this.selectedItems,
    required this.totalPrice,
  }) : super(key: key);

  @override
  State<OrderCreateScreen> createState() => _OrderCreateScreenState();
}

class _OrderCreateScreenState extends State<OrderCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String? userId;
  String? paymentId = "6821d8beac81a5ddf96daf0c"; // giả lập
  String? transportId = "6821d8beac81a5ddf96daf0d"; // giả lập

  bool isLoading = false;
  bool isUserInfoLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndInfo();
  }

  Future<void> _loadUserIdAndInfo() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
    if (userId != null) {
      await _fetchCustomerInfo(userId!);
    }
    setState(() {
      isUserInfoLoading = false;
    });
  }

  Future<void> _fetchCustomerInfo(String userId) async {
    try {
      final url = Uri.parse(
        'http://localhost:3002/api/customer/by-user/$userId',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _nameCtrl.text = data['fullName'] ?? '';
        _phoneCtrl.text = data['phone'] ?? '';
        _addressCtrl.text = data['address'] ?? '';
        _provinceCtrl.text = '';
      }
    } catch (e) {
      // Không làm gì, user có thể tự nhập
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate() || userId == null) return;

    setState(() => isLoading = true);

    final orderData = {
      "totalOrder": widget.totalPrice,
      "status": "pending",
      "shippingInfo": {
        "name": _nameCtrl.text,
        "phone": _phoneCtrl.text,
        "province": _provinceCtrl.text,
        "address": _addressCtrl.text,
      },
      "discountId": [],
      "customerId": userId,
      "paymentId": paymentId,
      "transportId": transportId,
      "userId": userId,
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:4000/api/order/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(orderData),
      );

      setState(() => isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final orderId = data['order']?['_id'] ?? data['orderId'] ?? data['_id'];
        // Tạo chi tiết đơn hàng cho từng sản phẩm
        if (orderId != null) {
          for (var item in widget.selectedItems) {
            final product = item['productId'];
            final orderDetailData = {
              "orderId": orderId,
              "productId": product['_id'] ?? product['id'],
              "quantity": item['quantity'],
              "totalPrice": (product['price'] * item['quantity']),
            };
            await http.post(
              Uri.parse('http://localhost:4001/api/orderDetails/create'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(orderDetailData),
            );
          }
        }
        // Hiển thị dialog thông báo thành công, chỉ cần click ra ngoài để đóng
        showDialog(
          context: context,
          barrierDismissible: true,
          builder:
              (context) => AlertDialog(
                title: const Text('Thành công'),
                content: Text(data['message'] ?? 'Đặt hàng thành công!'),
              ),
        ).then((_) {
          Navigator.of(context).pop();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đặt hàng: ${response.body}')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đặt hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          isLoading || isUserInfoLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      "Đang xử lý...",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              )
              : Container(
                color: Colors.grey[50],
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order Summary Card
                        Card(
                          elevation: 2,
                          margin: EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.shopping_cart,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Tóm tắt đơn hàng',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Số lượng sản phẩm:'),
                                    Text(
                                      '${widget.selectedItems.length}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Tổng thanh toán:'),
                                    Text(
                                      'đ${widget.totalPrice.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Shipping Information Card
                        Card(
                          elevation: 2,
                          margin: EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.local_shipping,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Thông tin giao hàng',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(height: 24),
                                TextFormField(
                                  controller: _nameCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Họ tên',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: Icon(Icons.person),
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.auto,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  validator:
                                      (v) =>
                                          v == null || v.isEmpty
                                              ? 'Nhập họ tên'
                                              : null,
                                ),
                                SizedBox(height: 16),
                                TextFormField(
                                  controller: _phoneCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Số điện thoại',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: Icon(Icons.phone),
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.auto,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  validator:
                                      (v) =>
                                          v == null || v.isEmpty
                                              ? 'Nhập số điện thoại'
                                              : null,
                                ),
                                SizedBox(height: 16),
                                TextFormField(
                                  controller: _provinceCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Tỉnh/Thành phố',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: Icon(Icons.location_city),
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.auto,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  validator:
                                      (v) =>
                                          v == null || v.isEmpty
                                              ? 'Nhập tỉnh/thành phố'
                                              : null,
                                ),
                                SizedBox(height: 16),
                                TextFormField(
                                  controller: _addressCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Địa chỉ chi tiết',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: Icon(Icons.home),
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.auto,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  maxLines: 2,
                                  validator:
                                      (v) =>
                                          v == null || v.isEmpty
                                              ? 'Nhập địa chỉ'
                                              : null,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Payment and Delivery Methods Card
                        Card(
                          elevation: 2,
                          margin: EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.payment, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text(
                                      'Phương thức thanh toán',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: paymentId,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: "6821d8beac81a5ddf96daf0c",
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.money,
                                            color: Colors.green,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Thanh toán khi nhận hàng'),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: "other",
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.credit_card,
                                            color: Colors.blue,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Khác (giả lập)'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onChanged:
                                      (v) => setState(() => paymentId = v),
                                ),
                                SizedBox(height: 24),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.local_shipping,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Phương thức vận chuyển',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: transportId,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: "6821d8beac81a5ddf96daf0d",
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.local_shipping,
                                            color: Colors.orange,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Giao hàng tiêu chuẩn'),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: "other",
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delivery_dining,
                                            color: Colors.purple,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Khác (giả lập)'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onChanged:
                                      (v) => setState(() => transportId = v),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Product Details Card
                        Card(
                          elevation: 2,
                          margin: EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.inventory, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text(
                                      'Chi tiết sản phẩm',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(height: 24),
                                ...widget.selectedItems.map((item) {
                                  final product = item['productId'];
                                  // Safely extract the image URL, ensuring it's a string
                                  String? imageUrl;
                                  if (product['image'] != null) {
                                    if (product['image'] is String) {
                                      imageUrl = product['image'];
                                    } else if (product['image'] is List &&
                                        (product['image'] as List).isNotEmpty) {
                                      // If image is a list, use the first item
                                      final firstImage =
                                          (product['image'] as List).first;
                                      imageUrl =
                                          firstImage is String
                                              ? firstImage
                                              : null;
                                    }
                                  }

                                  return Card(
                                    elevation: 0,
                                    color: Colors.grey[100],
                                    margin: EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              image:
                                                  imageUrl != null
                                                      ? DecorationImage(
                                                        image: NetworkImage(
                                                          imageUrl,
                                                        ),
                                                        fit: BoxFit.cover,
                                                      )
                                                      : null,
                                            ),
                                            child:
                                                imageUrl == null
                                                    ? Icon(
                                                      Icons.image_not_supported,
                                                      color: Colors.grey,
                                                    )
                                                    : null,
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product['name']?.toString() ??
                                                      'Sản phẩm',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'đ${product['price']?.toString() ?? '0'} x ${item['quantity']?.toString() ?? '1'}',
                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            'đ${((product['price'] ?? 0) * (item['quantity'] ?? 1)).toString()}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),

                        // Checkout Button
                        SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child:
                                isLoading
                                    ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text('Đang xử lý...'),
                                      ],
                                    )
                                    : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.shopping_cart_checkout),
                                        SizedBox(width: 12),
                                        Text(
                                          'Đặt hàng ngay',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                        ),
                        SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
