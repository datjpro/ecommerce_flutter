import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> order;

  const OrderDetailScreen({
    Key? key,
    required this.orderId,
    required this.order,
  }) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  List<dynamic> orderDetails = [];
  Map<String, dynamic> sellerInfo = {};
  Map<String, dynamic> productDetails =
      {}; // Thêm map để lưu thông tin sản phẩm
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchOrderDetails();
  }

  Future<void> fetchOrderDetails() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Lấy chi tiết đơn hàng
      final response = await http.get(
        Uri.parse(
          'http://localhost:4001/api/orderDetails/order/${widget.orderId}',
        ),
      );

      // print('Response status: ${response.statusCode}');
      // print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> details = json.decode(response.body);

        // Debug: In ra dữ liệu để kiểm tra
        // print('Order details count: ${details.length}');
        // for (int i = 0; i < details.length; i++) {
        //   print('Detail $i: ${details[i]}');
        // }

        // Lấy thông tin sản phẩm cho từng detail
        for (var detail in details) {
          final productId = detail['productId'];
          if (productId != null) {
            await fetchProductInfo(productId);
          }
        }

        // Lấy thông tin seller nếu có
        if (details.isNotEmpty) {
          final sellerId = details[0]['sellerId'];
          if (sellerId != null && sellerId.isNotEmpty) {
            await fetchSellerInfo(sellerId);
          }
        }

        setState(() {
          orderDetails = details;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Không thể tải chi tiết đơn hàng';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error in fetchOrderDetails: $e');
      setState(() {
        error = 'Lỗi kết nối: $e';
        isLoading = false;
      });
    }
  }

  Future<void> fetchProductInfo(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:4003/api/product/$productId'),
      );

      // print('Product API response status: ${response.statusCode}');
      // print('Product API response body: ${response.body}');

      if (response.statusCode == 200) {
        final productData = json.decode(response.body);
        setState(() {
          productDetails[productId] = productData;
        });
      }
    } catch (e) {
      // print('Error fetching product info: $e');
    }
  }

  Future<void> fetchSellerInfo(String sellerId) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3001/api/seller/$sellerId'),
      );

      if (response.statusCode == 200) {
        setState(() {
          sellerInfo = json.decode(response.body);
        });
      }
    } catch (e) {}
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0đ';

    double numValue = 0;

    if (value is num) {
      numValue = value.toDouble();
    } else if (value is String) {
      numValue = double.tryParse(value) ?? 0;
    } else {
      // Thử chuyển đổi toString rồi parse
      numValue = double.tryParse(value.toString()) ?? 0;
    }

    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    return formatter.format(numValue);
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (_) {
      return dateString.substring(0, min(dateString.length, 10));
    }
  }

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'hoàn thành':
        return '009688'; // Teal
      case 'delivered':
      case 'đã giao':
        return '4CAF50'; // Green
      case 'processing':
      case 'đang xử lý':
        return '2196F3'; // Blue
      case 'pending':
      case 'chờ xử lý':
        return 'FFC107'; // Amber
      case 'confirmed':
      case 'đã xác nhận':
        return '2196F3'; // Blue
      case 'preparing':
      case 'đang chuẩn bị':
        return '3F51B5'; // Indigo
      case 'shipping':
      case 'đang giao':
        return '9C27B0'; // Purple
      case 'cancelled':
      case 'đã hủy':
        return 'F44336'; // Red
      default:
        return '9E9E9E'; // Grey
    }
  }

  @override
  Widget build(BuildContext context) {
    final shipping = widget.order['shippingInfo'] ?? {};
    final status = widget.order['status'] ?? '';
    final statusColor = _getStatusColor(status);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Chi tiết đơn hàng',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black87),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Trợ giúp đơn hàng')),
              );
            },
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(error!, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: fetchOrderDetails,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Summary Card
                    _buildOrderSummaryCard(shipping, status, statusColor),

                    // Seller Information
                    if (sellerInfo.isNotEmpty) _buildSellerInfoCard(),

                    // Product List
                    _buildProductListHeader(),
                    _buildProductItems(),

                    // Order Summary
                    _buildOrderSummaryPayment(),

                    // Action Buttons
                    _buildActionButtons(status),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
    );
  }

  Widget _buildOrderSummaryCard(
    Map<String, dynamic> shipping,
    String status,
    String statusColor,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(int.parse('0xFF$statusColor')).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Color(int.parse('0xFF$statusColor')),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(widget.order['createdAt']),
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Mã đơn hàng:',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '#${widget.order['_id'] ?? ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Khách hàng:',
                  shipping['name'] ?? 'N/A',
                  Icons.person_outline,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Địa chỉ:',
                  '${shipping['address'] ?? ''}, ${shipping['province'] ?? ''}',
                  Icons.location_on_outlined,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Số điện thoại:',
                  shipping['phone'] ?? 'N/A',
                  Icons.phone_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.store, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Thông tin người bán',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSellerInfoRow(
            'Tên cửa hàng:',
            sellerInfo['shopName'] ?? sellerInfo['name'] ?? 'N/A',
          ),
          const SizedBox(height: 8),
          _buildSellerInfoRow('Email:', sellerInfo['email'] ?? 'N/A'),
          if (sellerInfo['phone'] != null) ...[
            const SizedBox(height: 8),
            _buildSellerInfoRow('Số điện thoại:', sellerInfo['phone']),
          ],
          if (sellerInfo['address'] != null) ...[
            const SizedBox(height: 8),
            _buildSellerInfoRow('Địa chỉ:', sellerInfo['address']),
          ],
        ],
      ),
    );
  }

  Widget _buildSellerInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildProductListHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text(
            'Sản phẩm đã đặt',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${orderDetails.length}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItems() {
    if (orderDetails.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'Không có sản phẩm nào',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: orderDetails.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final detail = orderDetails[index];

          // Lấy productId từ detail (đây là string ID)
          final productId = detail['productId'];

          // Lấy thông tin sản phẩm từ productDetails map
          final product = productDetails[productId] ?? {};

          // Debug: In ra thông tin
          // print('Detail: $detail');
          // print('ProductId: $productId');
          // print('Product from productDetails: $product');

          // Xử lý hình ảnh an toàn
          String? imageUrl;
          try {
            final imageData = product['image'];
            if (imageData != null) {
              if (imageData is List && imageData.isNotEmpty) {
                final firstImage = imageData[0];
                imageUrl = firstImage?.toString();
              } else if (imageData is String && imageData.isNotEmpty) {
                imageUrl = imageData;
              }
            }
          } catch (e) {
            // print('Error processing image data: $e');
            // imageUrl = null;
          }

          // Lấy thông tin sản phẩm với giá trị mặc định
          final productName =
              product['name']?.toString() ?? 'Sản phẩm ID: $productId';
          final productDescription =
              product['describe']?.toString() ??
              product['description']?.toString();
          final productPrice = product['price']; // Giá gốc từ sản phẩm
          final quantity = detail['quantity'];
          final totalPrice = detail['totalPrice']; // Tổng giá từ order detail

          // Debug: In ra các giá trị
          // print('Product name: $productName');
          // print('Product price: $productPrice');
          // print('Quantity: $quantity');
          // print('Total price: $totalPrice');

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      imageUrl != null && imageUrl.isNotEmpty
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Icon(
                                    Icons.image,
                                    size: 30,
                                    color: Colors.grey[400],
                                  ),
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                  ),
                                );
                              },
                            ),
                          )
                          : Icon(
                            Icons.shopping_bag,
                            size: 30,
                            color: Colors.grey[400],
                          ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (productDescription != null &&
                          productDescription.isNotEmpty) ...[
                        Text(
                          productDescription,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                      ],
                      Row(
                        children: [
                          Text(
                            _formatCurrency(productPrice),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const Text(
                            ' × ',
                            style: TextStyle(color: Colors.black54),
                          ),
                          Text(
                            '${quantity ?? 0}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tổng: ${_formatCurrency(totalPrice)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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
    );
  }

  Widget _buildOrderSummaryPayment() {
    // Tính tổng tiền từ orderDetails
    double subtotal = 0;
    for (var detail in orderDetails) {
      final totalPrice = detail['totalPrice'];
      if (totalPrice != null) {
        if (totalPrice is num) {
          subtotal += totalPrice.toDouble();
        } else if (totalPrice is String) {
          subtotal += double.tryParse(totalPrice) ?? 0;
        }
      }
    }

    // Lấy tổng thanh toán từ order
    final totalOrder = widget.order['totalOrder'];
    double totalOrderAmount = 0;
    if (totalOrder != null) {
      if (totalOrder is num) {
        totalOrderAmount = totalOrder.toDouble();
      } else if (totalOrder is String) {
        totalOrderAmount = double.tryParse(totalOrder) ?? 0;
      }
    }

    // Tính phí vận chuyển = tổng thanh toán - tổng tiền hàng - giảm giá
    final discount = widget.order['discount'] ?? 0;
    double discountAmount = 0;
    if (discount is num) {
      discountAmount = discount.toDouble();
    } else if (discount is String) {
      discountAmount = double.tryParse(discount.toString()) ?? 0;
    }

    double shippingFee = totalOrderAmount - subtotal + discountAmount;
    if (shippingFee < 0) shippingFee = 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin thanh toán',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildPaymentRow('Tổng tiền hàng:', _formatCurrency(subtotal)),
          const SizedBox(height: 12),
          _buildPaymentRow('Phí vận chuyển:', _formatCurrency(shippingFee)),
          if (discountAmount > 0) ...[
            const SizedBox(height: 12),
            _buildPaymentRow(
              'Giảm giá:',
              '-${_formatCurrency(discountAmount)}',
              isDiscount: true,
            ),
          ],
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _buildPaymentRow(
            'Tổng thanh toán:',
            _formatCurrency(totalOrderAmount),
            isTotal: true,
          ),
          const SizedBox(height: 16),
          _buildPaymentMethodRow(
            (widget.order['paymentId'] is Map &&
                    widget.order['paymentId']?['paymentMethod'] != null)
                ? widget.order['paymentId']['paymentMethod']
                : (widget.order['paymentMethod'] ?? 'cod'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String status) {
    List<Widget> buttons = [];

    // Nút hỗ trợ luôn có
    buttons.add(
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () {
            // Contact support functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tính năng hỗ trợ đang phát triển')),
            );
          },
          icon: const Icon(Icons.support_agent),
          label: const Text('Hỗ trợ'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );

    buttons.add(const SizedBox(width: 12));

    // Nút theo trạng thái
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'đã giao':
        buttons.add(
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showConfirmDeliveryDialog(),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Xác nhận giao hàng'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        );
        break;
      case 'cancelled':
      case 'đã hủy':
        buttons.add(
          Expanded(
            child: ElevatedButton.icon(
              onPressed: null, // Disabled
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Đã hủy'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        );
        break;
      default:
        buttons.add(
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // Order tracking functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tính năng theo dõi đang phát triển'),
                  ),
                );
              },
              icon: const Icon(Icons.local_shipping_outlined),
              label: const Text('Theo dõi'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: buttons),
    );
  }

  void _showConfirmDeliveryDialog() {
    String feedback = '';
    int rating = 5;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Xác nhận giao hàng thành công',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bạn đã nhận được hàng và hài lòng với đơn hàng này?',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Đánh giá của bạn:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () {
                            setState(() {
                              rating = index + 1;
                            });
                          },
                          icon: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 30,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nhận xét (tùy chọn):',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Chia sẻ trải nghiệm của bạn về sản phẩm...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                      onChanged: (value) {
                        feedback = value;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Hủy'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _confirmDelivery(feedback, rating);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Xác nhận'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelivery(String feedback, int rating) async {
    try {
      // Hiển thị loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // Lấy userId từ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        Navigator.pop(context); // Đóng loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy thông tin người dùng')),
        );
        return;
      }

      // Gọi API xác nhận giao hàng - sử dụng order detail ID đầu tiên
      if (orderDetails.isNotEmpty) {
        final orderDetailId = orderDetails[0]['_id'];

        final response = await http.put(
          Uri.parse(
            'http://localhost:4001/api/orderDetails/customer/confirm-delivery/$orderDetailId',
          ),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'userId': userId,
            'feedback': feedback.isEmpty ? 'Sản phẩm tốt' : feedback,
            'rating': rating,
          }),
        );

        Navigator.pop(context); // Đóng loading dialog

        if (response.statusCode == 200 || response.statusCode == 204) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xác nhận giao hàng thành công!'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh lại dữ liệu
          fetchOrderDetails();

          // Có thể pop về màn hình trước hoặc update UI
          Navigator.pop(context);
        } else {
          final errorMessage =
              json.decode(response.body)['message'] ?? 'Có lỗi xảy ra';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Xác nhận thất bại: $errorMessage'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        Navigator.pop(context); // Đóng loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy thông tin chi tiết đơn hàng'),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Đóng loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(
    String label,
    String value, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color:
                isDiscount
                    ? Colors.green
                    : isTotal
                    ? Colors.red
                    : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodRow(String method) {
    IconData icon;
    String methodName;

    final normalized = method.toLowerCase().replaceAll('mono', 'momo');

    switch (normalized) {
      case 'credit_card':
      case 'card':
        icon = Icons.credit_card;
        methodName = 'Thẻ tín dụng';
        break;
      case 'paypal':
        icon = Icons.payment;
        methodName = 'PayPal';
        break;
      case 'bank_transfer':
      case 'banking':
        icon = Icons.account_balance;
        methodName = 'Chuyển khoản ngân hàng';
        break;
      case 'momo':
        icon = Icons.account_balance_wallet;
        methodName = 'Ví MoMo';
        break;
      case 'cod':
      default:
        icon = Icons.money;
        methodName = 'Thanh toán khi nhận hàng (COD)';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phương thức thanh toán',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  methodName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int min(int a, int b) => a < b ? a : b;
}
