import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatelessWidget {
  final List<dynamic> orderDetails;
  final Map<String, dynamic> order;

  const OrderDetailScreen({
    Key? key,
    required this.orderDetails,
    required this.order,
  }) : super(key: key);

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
    final shipping = order['shippingInfo'] ?? {};
    final status = order['status'] ?? '';
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
              // Show help dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Trợ giúp đơn hàng')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Card
            Container(
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
                      color: Color(
                        int.parse('0xFF$statusColor'),
                      ).withOpacity(0.1),
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
                          _formatDate(order['createdAt']),
                          style: TextStyle(color: Colors.black54, fontSize: 14),
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
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '#${order['_id'] ?? ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.copy,
                                size: 16,
                                color: Colors.black54,
                              ),
                              onPressed: () {
                                // Copy order ID to clipboard
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã sao chép mã đơn hàng'),
                                  ),
                                );
                              },
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
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
                          shipping['address'] ?? 'N/A',
                          Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          'Số điện thoại:',
                          shipping['phone'] ?? 'N/A',
                          Icons.phone_outlined,
                        ),
                        if (shipping['email'] != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Email:',
                            shipping['email'],
                            Icons.email_outlined,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Product List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Sản phẩm đã đặt',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${orderDetails.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Product Items
            Container(
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
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child:
                              detail['imageUrl'] != null
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      detail['imageUrl'],
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
                                detail['productName'] ??
                                    'Sản phẩm: ${detail['productId'] ?? ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              if (detail['variant'] != null) ...[
                                Text(
                                  'Phân loại: ${detail['variant']}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                              Row(
                                children: [
                                  Text(
                                    _formatCurrency(detail['price']),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatCurrency(detail['totalPrice']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Order Summary
            Container(
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
                  _buildPaymentRow(
                    'Tổng tiền hàng:',
                    _formatCurrency(order['subtotal'] ?? order['totalOrder']),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentRow(
                    'Phí vận chuyển:',
                    _formatCurrency(order['shippingFee'] ?? 0),
                  ),
                  if (order['discount'] != null && order['discount'] != 0) ...[
                    const SizedBox(height: 12),
                    _buildPaymentRow(
                      'Giảm giá:',
                      '-${_formatCurrency(order['discount'])}',
                      isDiscount: true,
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildPaymentRow(
                    'Tổng thanh toán:',
                    _formatCurrency(order['totalOrder']),
                    isTotal: true,
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentMethodRow(order['paymentMethod'] ?? 'COD'),
                ],
              ),
            ),

            // Action Buttons
            Padding(
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
            ),
            const SizedBox(height: 24),
          ],
        ),
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

    switch (method.toLowerCase()) {
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
