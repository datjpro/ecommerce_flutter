import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Discount {
  final String id;
  final String description;
  final String discountType;
  final DateTime startDate;
  final DateTime endDate;
  final double discountAmount;

  Discount({
    required this.id,
    required this.description,
    required this.discountType,
    required this.startDate,
    required this.endDate,
    required this.discountAmount,
  });

  factory Discount.fromJson(Map<String, dynamic> json) {
    return Discount(
      id: json['_id'] ?? '',
      description: json['description'] ?? '',
      discountType: json['discountType'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
    );
  }
}

// Định nghĩa model Discount ở trên hoặc trong file riêng

class DiscountScreen extends StatefulWidget {
  const DiscountScreen({Key? key}) : super(key: key);

  @override
  State<DiscountScreen> createState() => _DiscountScreenState();
}

class _DiscountScreenState extends State<DiscountScreen> {
  late Future<List<Discount>> discountsFuture;

  @override
  void initState() {
    super.initState();
    discountsFuture = fetchDiscounts();
  }

  Future<List<Discount>> fetchDiscounts() async {
    final url = Uri.parse('http://localhost:4002/api/discount/all');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Discount.fromJson(json)).toList();
    } else {
      throw Exception('Không thể tải danh sách khuyến mãi');
    }
  }

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
           "${date.month.toString().padLeft(2, '0')}/"
           "${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khuyến mãi'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Discount>>(
        future: discountsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có khuyến mãi nào.'));
          }

          final discounts = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: discounts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final discount = discounts[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(
                    discount.discountType == 'percentage'
                        ? Icons.percent
                        : Icons.attach_money,
                    color: Colors.green[700],
                  ),
                  title: Text(
                    discount.description,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        discount.discountType == 'percentage'
                          ? 'Giảm ${discount.discountAmount.toStringAsFixed(0)}%'
                          : 'Giảm ${discount.discountAmount.toStringAsFixed(0)}đ',
                        style: const TextStyle(color: Colors.black87),
                      ),
                      Text(
                        'Từ ${formatDate(discount.startDate)} đến ${formatDate(discount.endDate)}',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
