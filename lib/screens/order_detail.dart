import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
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

      if (response.statusCode == 200) {
        final List<dynamic> details = json.decode(response.body);

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
      setState(() {
        error = 'Lỗi kết nối: $e';
        isLoading = false;
      });
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
    } catch (e) {
      print('Error fetching seller info: $e');
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0đ';
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    return formatter.format(value is String ? int.tryParse(value) ?? 0 : value);
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
      case 'delivered':
      case 'hoàn thành':
        return '4CAF50'; // Green
      case 'processing':
      case 'đang xử lý':
        return '2196F3'; // Blue
      case 'pending':
      case 'chờ xử lý':
        return 'FFC107'; // Amber
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
          final product = detail['productId'] ?? {};
          final imageUrl =
              (product['image'] != null &&
                      product['image'] is List &&
                      product['image'].isNotEmpty)
                  ? product['image'][0]
                  : null;

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
                      imageUrl != null
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
                        product['name'] ?? 'Sản phẩm: ${product['_id'] ?? ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (product['describe'] != null) ...[
                        Text(
                          product['describe'],
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
                            _formatCurrency(product['price']),
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
                            '${detail['quantity'] ?? 0}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tổng: ${_formatCurrency(detail['totalPrice'])}',
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
      subtotal += (detail['totalPrice'] ?? 0).toDouble();
    }

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
          _buildPaymentRow(
            'Phí vận chuyển:',
            _formatCurrency(widget.order['transportId']?['fee'] ?? 0),
          ),
          if (widget.order['discount'] != null &&
              widget.order['discount'] != 0) ...[
            const SizedBox(height: 12),
            _buildPaymentRow(
              'Giảm giá:',
              '-${_formatCurrency(widget.order['discount'])}',
              isDiscount: true,
            ),
          ],
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _buildPaymentRow(
            'Tổng thanh toán:',
            _formatCurrency(widget.order['totalOrder']),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // Contact support functionality
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
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed:
                  status.toLowerCase() == 'đã hủy' ||
                          status.toLowerCase() == 'cancelled'
                      ? null
                      : () {
                        // Order tracking functionality
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
        ],
      ),
    );
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
