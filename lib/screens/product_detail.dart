import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/taskbar_widget.dart';
import '../widgets/product_widget.dart'; // Để dùng lại ProductWidget

class ProductDetailScreen extends StatefulWidget {
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Map? product;
  List images = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Lấy dữ liệu product từ arguments
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    if (args != null && product == null) {
      product = args;
      images = product!['image'] is List ? product!['image'] : [];
      _increaseView(product!['_id']);
      setState(() {}); // Cập nhật lại UI nếu cần
    }
  }

  Future<void> _increaseView(String id) async {
    try {
      await http.get(Uri.parse('http://localhost:4003/api/product/view/$id'));
      // Sau khi tăng view, lấy lại thông tin sản phẩm mới nhất
      final detailRes = await http.get(
        Uri.parse('http://localhost:4003/api/product/$id'),
      );
      if (detailRes.statusCode == 200) {
        setState(() {
          product = json.decode(detailRes.body);
          images = product!['image'] is List ? product!['image'] : [];
        });
      }
    } catch (e) {
      // Có thể log lỗi nếu muốn
    }
  }

  @override
  Widget build(BuildContext context) {
    if (product == null) {
      return Scaffold(
        body: Column(
          children: [
            TaskbarWidget(showBack: true, onBack: () => Navigator.pop(context)),
            Expanded(child: Center(child: Text('Không có dữ liệu sản phẩm'))),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          TaskbarWidget(showBack: true, onBack: () => Navigator.pop(context)),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (images.isNotEmpty)
                    SizedBox(
                      height: 250,
                      child: PageView.builder(
                        itemCount: images.length,
                        itemBuilder:
                            (context, index) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  images[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder:
                                      (context, error, stackTrace) => Icon(
                                        Icons.broken_image,
                                        size: 100,
                                        color: Colors.grey,
                                      ),
                                ),
                              ),
                            ),
                      ),
                    ),
                  SizedBox(height: 16),
                  Text(
                    product!['name'] ?? '',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    product!['price'] != null
                        ? '${product!['price'].toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')} đ'
                        : '',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    product!['describe'] ?? '',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Tình trạng: ${product!['status'] ?? ''}',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Lượt xem: ${product!['views'] ?? 0}',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  if (product!['categoryId'] != null &&
                      product!['categoryId'] is Map)
                    Text(
                      'Danh mục: ${product!['categoryId']['name'] ?? ''}',
                      style: TextStyle(fontSize: 16),
                    ),
                  SizedBox(height: 24),
                  Text(
                    'Sản phẩm khác',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  OtherProductsWidget(currentProductId: product!['_id']),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget hiển thị sản phẩm khác
class OtherProductsWidget extends StatefulWidget {
  final String currentProductId;
  const OtherProductsWidget({required this.currentProductId});

  @override
  State<OtherProductsWidget> createState() => _OtherProductsWidgetState();
}

class _OtherProductsWidgetState extends State<OtherProductsWidget> {
  List products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:4003/api/product/all'),
      );
      if (response.statusCode == 200) {
        final allProducts = json.decode(response.body);
        final productList = allProducts['products'] ?? [];
        setState(() {
          products =
              productList
                  .where((p) => p['_id'] != widget.currentProductId)
                  .toList();
          isLoading = false;
        });
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Không có sản phẩm khác'),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount:
          products.length > 4
              ? 4
              : products.length, // Hiển thị tối đa 4 sản phẩm
      itemBuilder: (context, index) {
        final product = products[index];
        final imageUrl =
            (product['image'] is List && product['image'].isNotEmpty)
                ? product['image'][0]
                : (product['image'] ?? '');

        return GestureDetector(
          onTap: () {
            Navigator.pushReplacementNamed(
              context,
              '/product_detail',
              arguments: product,
            );
          },
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                    child:
                        imageUrl != ''
                            ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Icon(
                                    Icons.broken_image,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                            )
                            : Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.image,
                                size: 60,
                                color: Colors.grey,
                              ),
                            ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    product['name'] ?? '',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    product['price'] != null
                        ? '${product['price'].toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')} đ'
                        : '',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
