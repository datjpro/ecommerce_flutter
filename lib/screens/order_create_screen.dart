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
  String? transportId; // Không set mặc định nữa
  String paymentMethod = "cod"; // Mặc địn  h là COD

  bool isLoading = false;
  bool isUserInfoLoading = true;

  List<Map<String, dynamic>> paymentMethods = [];
  List<Map<String, dynamic>> transportMethods = [];
  int selectedTransportFee = 0;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndInfo();
    fetchPaymentMethods();
    fetchTransportMethods(); // Gọi khi khởi tạo
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

  Future<void> fetchPaymentMethods() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('http://localhost:3007/api/payment/all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      // print('Payment API status: ${response.statusCode}');
      // print('Payment API body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // data là List
          paymentMethods = List<Map<String, dynamic>>.from(data);
          if (paymentMethods.isNotEmpty) {
            paymentId = paymentMethods.first['_id'];
          }
        });
      } else {
        // Hiển thị lỗi cho người dùng
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lấy phương thức thanh toán: ${response.body}'),
          ),
        );
      }
    } catch (e) {
      print('Payment API error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi lấy phương thức thanh toán: $e')),
      );
    }
  }

  // Sửa lại hàm fetchTransportMethods để tránh lỗi khi danh sách rỗng hoặc không có GHN
  Future<void> fetchTransportMethods() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('http://localhost:3005/api/transport/all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          transportMethods = List<Map<String, dynamic>>.from(data);
          // Mặc định là GHN nếu có, nếu không thì lấy cái đầu tiên, nếu không có thì null
          Map<String, dynamic>? ghn;
          if (transportMethods.isNotEmpty) {
            try {
              ghn = transportMethods.firstWhere(
                (t) => t['shippingCarrier'] == 'GHN',
                orElse: () => transportMethods.first,
              );
            } catch (e) {
              ghn = null;
            }
          } else {
            ghn = null;
          }
          if (ghn != null && ghn.containsKey('_id')) {
            transportId = ghn['_id'];
            selectedTransportFee = ghn['fee'] ?? 0;
          } else {
            transportId = null;
            selectedTransportFee = 0;
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lấy phương thức vận chuyển: ${response.body}'),
          ),
        );
      }
    } catch (e) {
      print('Transport API error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi lấy phương thức vận chuyển: $e')),
      );
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate() || userId == null) return;

    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // Tạo orderDetailsItems từ selectedItems
    List<Map<String, dynamic>> orderDetailsItems =
        widget.selectedItems.map((item) {
          final product = item['productId'];
          return {
            "productId": product['_id'] ?? product['id'],
            "sellerId":
                product['sellerId'] ??
                product['seller_id'] ??
                "", // Lấy sellerId từ product
            "quantity": item['quantity'],
            "totalPrice": (product['price'] * item['quantity']),
          };
        }).toList();

    final orderData = {
      "totalOrder": widget.totalPrice + selectedTransportFee, // Cộng phí ship
      "shippingFee": selectedTransportFee,
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
      "orderDetailsItems":
          orderDetailsItems, // Thêm orderDetailsItems vào orderData
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:4000/api/order/create'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(orderData),
      );

      setState(() => isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Không cần tạo orderDetails riêng nữa vì đã gửi trong orderDetailsItems
        // Hiển thị dialog thông báo thành công
        showDialog(
          context: context,
          barrierDismissible: true,
          builder:
              (context) => AlertDialog(
                title: const Text('Thành công'),
                content: Text(data['message'] ?? 'Đặt hàng thành công!'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Đóng dialog
                      Navigator.of(context).pop(); // Quay lại màn hình trước
                    },
                    child: Text('OK'),
                  ),
                ],
              ),
        );
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
                                    Text('Tổng tiền hàng:'),
                                    Text(
                                      'đ${widget.totalPrice.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Phí vận chuyển:'),
                                    Text(
                                      'đ${selectedTransportFee.toString()}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                Divider(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Tổng thanh toán:'),
                                    Text(
                                      'đ${(widget.totalPrice + selectedTransportFee).toStringAsFixed(0)}',
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
                                  items:
                                      paymentMethods.map((pm) {
                                        final method =
                                            pm['paymentMethod'] ?? '';
                                        return DropdownMenuItem<String>(
                                          value: pm['_id'],
                                          child: Row(
                                            children: [
                                              Icon(
                                                method == 'cod'
                                                    ? Icons.money
                                                    : Icons
                                                        .account_balance_wallet,
                                                color:
                                                    method == 'cod'
                                                        ? Colors.green
                                                        : Colors.purple,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                method == 'cod'
                                                    ? 'Thanh toán khi nhận hàng'
                                                    : (method == 'momo'
                                                        ? 'Ví MoMo'
                                                        : method.toString()),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
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
                                  items:
                                      transportMethods.map((tm) {
                                        return DropdownMenuItem<String>(
                                          value: tm['_id'],
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.local_shipping,
                                                color: Colors.orange,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                '${tm['shippingCarrier']} (đ${tm['fee']})',
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      transportId = v;
                                      final selected = transportMethods
                                          .firstWhere(
                                            (tm) => tm['_id'] == v,
                                            orElse: () => {},
                                          );
                                      if (selected is Map &&
                                          selected.containsKey('fee')) {
                                        selectedTransportFee =
                                            selected['fee'] ?? 0;
                                      } else {
                                        selectedTransportFee = 0;
                                      }
                                    });
                                  },
                                  validator:
                                      (v) =>
                                          v == null || v.isEmpty
                                              ? 'Chọn phương thức vận chuyển'
                                              : null,
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
                                  String? imageUrl;
                                  if (product['image'] != null) {
                                    if (product['image'] is String) {
                                      imageUrl = product['image'];
                                    } else if (product['image'] is List &&
                                        (product['image'] as List).isNotEmpty) {
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
