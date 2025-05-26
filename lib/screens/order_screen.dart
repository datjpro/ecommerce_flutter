import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'order_detail.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({Key? key}) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> orders = [];
  bool isLoading = true;
  late TabController _tabController;
  final List<String> _tabs = [
    'Tất cả',
    'Chờ xử lý',
    'Đã xác nhận',
    'Đang chuẩn bị',
    'Đang giao',
    'Đã giao',
    'Hoàn thành',
    'Đã hủy',
  ];
  final Map<String, String> _statusMapping = {
    'Tất cả': 'all',
    'Chờ xử lý': 'pending',
    'Đã xác nhận': 'confirmed',
    'Đang chuẩn bị': 'preparing',
    'Đang giao': 'shipping',
    'Đã giao': 'delivered',
    'Hoàn thành': 'completed',
    'Đã hủy': 'cancelled',
  };
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        fetchOrders(_statusMapping[_tabs[_tabController.index]] ?? 'all');
      }
    });
    fetchOrders('all');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchOrders(String status) async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final url =
          status == 'all'
              ? 'http://localhost:4000/api/order/user/$userId'
              : 'http://localhost:4000/api/order/user/$userId?status=$status';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> fetchedOrders = data is List ? data : [];
        if (status != 'all') {
          fetchedOrders =
              fetchedOrders
                  .where((order) => order['status'] == status)
                  .toList();
        }
        setState(() {
          orders = fetchedOrders;
          isLoading = false;
        });
        // Lưu số lượng đơn hàng vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('orderCount', fetchedOrders.length);
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString.substring(0, 10);
    }
  }

  String formatPrice(dynamic price) {
    if (price == null) return '0₫';
    try {
      final numPrice = price is String ? double.parse(price) : price.toDouble();
      return currencyFormat.format(numPrice);
    } catch (e) {
      return '$price₫';
    }
  }

  Color getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.indigo;
      case 'shipping':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String translateStatus(String? status) {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'preparing':
        return 'Đang chuẩn bị';
      case 'shipping':
        return 'Đang giao';
      case 'delivered':
        return 'Đã giao';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status ?? 'Không xác định';
    }
  }

  Widget buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Không có đơn hàng nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy mua sắm ngay!',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to shop page
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/shop', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Mua sắm ngay'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldContext = context;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        title: const Text(
          'Đơn hàng của tôi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: _tabs.map((String name) => Tab(text: name)).toList(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh:
            () => fetchOrders(
              _statusMapping[_tabs[_tabController.index]] ?? 'all',
            ),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : orders.isEmpty
                ? buildEmptyState()
                : ListView.builder(
                  itemCount: orders.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final shipping = order['shippingInfo'] ?? {};
                    final status = order['status'];
                    final orderItems = order['orderItems'] as List? ?? [];
                    final itemCount = orderItems.length;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            final orderId = order['_id'];

                            if (!mounted) return;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => OrderDetailScreen(
                                      orderId: orderId,
                                      order: order,
                                    ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header section with order ID and status
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Đơn #${order['_id'].toString().substring(order['_id'].toString().length - 6)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: getStatusColor(
                                          status,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: getStatusColor(status),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        translateStatus(status),
                                        style: TextStyle(
                                          color: getStatusColor(status),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Shipping info section
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person_outline,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${shipping['name'] ?? 'Không có tên'}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone_outlined,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${shipping['phone'] ?? 'Không có SĐT'}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${shipping['address'] ?? 'Không có địa chỉ'}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Divider
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: Colors.grey[200],
                              ),

                              // Order summary section
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$itemCount sản phẩm',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 14,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              formatDate(order['createdAt']),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'Tổng tiền:',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          formatPrice(order['totalOrder']),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Action buttons section
                              _buildActionButtons(
                                status,
                                order,
                                scaffoldContext,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }

  Widget _buildActionButtons(
    String status,
    Map<String, dynamic> order,
    BuildContext scaffoldContext,
  ) {
    List<Widget> buttons = [];

    switch (status) {
      case 'pending':
        buttons.add(
          Expanded(
            child: OutlinedButton(
              onPressed: () => _cancelOrder(order, scaffoldContext),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Hủy đơn'),
            ),
          ),
        );
        break;

      case 'confirmed':
      case 'preparing':
        // Có thể thêm nút "Liên hệ seller" hoặc không có nút nào
        break;

      case 'shipping':
        buttons.add(
          Expanded(
            child: ElevatedButton(
              onPressed: () => _confirmReceived(order, scaffoldContext),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Đã nhận được hàng'),
            ),
          ),
        );
        break;

      case 'delivered':
        buttons.add(
          Expanded(
            child: OutlinedButton(
              onPressed: () => _completeOrder(order, scaffoldContext),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                side: BorderSide(color: Theme.of(context).primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Hoàn thành đơn hàng'),
            ),
          ),
        );
        break;

      case 'completed':
        buttons.add(
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                // Logic đánh giá sản phẩm
                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                  const SnackBar(
                    content: Text('Tính năng đánh giá đang phát triển'),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                side: BorderSide(color: Theme.of(context).primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Đánh giá'),
            ),
          ),
        );
        break;

      case 'cancelled':
        // Không có nút nào cho đơn hàng đã hủy
        break;
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(children: buttons),
    );
  }

  Future<void> _cancelOrder(
    Map<String, dynamic> order,
    BuildContext scaffoldContext,
  ) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hủy đơn hàng'),
            content: const Text('Bạn có chắc muốn hủy đơn hàng này không?'),
            actions: [
              TextButton(
                child: const Text('Không'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('Có'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  final orderId = order['_id'];
                  try {
                    final response = await http.patch(
                      Uri.parse(
                        'http://localhost:4000/api/order/cancel/$orderId',
                      ),
                      headers: {'Content-Type': 'application/json'},
                    );
                    if (!mounted) return;
                    if (response.statusCode == 200 ||
                        response.statusCode == 204) {
                      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                        const SnackBar(
                          content: Text('Đã hủy đơn hàng thành công!'),
                        ),
                      );
                      fetchOrders(
                        _statusMapping[_tabs[_tabController.index]] ?? 'all',
                      );
                    } else {
                      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Hủy đơn hàng thất bại: ${response.body}',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(
                      scaffoldContext,
                    ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
                  }
                },
              ),
            ],
          ),
    );
  }

  Future<void> _confirmReceived(
    Map<String, dynamic> order,
    BuildContext scaffoldContext,
  ) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xác nhận nhận hàng'),
            content: const Text(
              'Bạn đã nhận được hàng và hài lòng với đơn hàng này?',
            ),
            actions: [
              TextButton(
                child: const Text('Chưa nhận'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('Đã nhận'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  final orderId = order['_id'];
                  try {
                    final response = await http.patch(
                      Uri.parse(
                        'http://localhost:4000/api/order/delivered/$orderId',
                      ),
                      headers: {'Content-Type': 'application/json'},
                    );
                    if (!mounted) return;
                    if (response.statusCode == 200 ||
                        response.statusCode == 204) {
                      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                        const SnackBar(
                          content: Text('Đã xác nhận nhận hàng thành công!'),
                        ),
                      );
                      fetchOrders(
                        _statusMapping[_tabs[_tabController.index]] ?? 'all',
                      );
                    } else {
                      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                        SnackBar(
                          content: Text('Xác nhận thất bại: ${response.body}'),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(
                      scaffoldContext,
                    ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
                  }
                },
              ),
            ],
          ),
    );
  }

  Future<void> _completeOrder(
    Map<String, dynamic> order,
    BuildContext scaffoldContext,
  ) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hoàn thành đơn hàng'),
            content: const Text(
              'Bạn có muốn đánh dấu đơn hàng này là hoàn thành không?',
            ),
            actions: [
              TextButton(
                child: const Text('Hủy'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('Hoàn thành'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  final orderId = order['_id'];
                  try {
                    final response = await http.patch(
                      Uri.parse(
                        'http://localhost:4000/api/order/complete/$orderId',
                      ),
                      headers: {'Content-Type': 'application/json'},
                    );
                    if (!mounted) return;
                    if (response.statusCode == 200 ||
                        response.statusCode == 204) {
                      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                        const SnackBar(
                          content: Text('Đã hoàn thành đơn hàng thành công!'),
                        ),
                      );
                      fetchOrders(
                        _statusMapping[_tabs[_tabController.index]] ?? 'all',
                      );
                    } else {
                      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Hoàn thành thất bại: ${response.body}',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(
                      scaffoldContext,
                    ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
                  }
                },
              ),
            ],
          ),
    );
  }
}
