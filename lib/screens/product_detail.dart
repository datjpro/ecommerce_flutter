import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/purchase_benefits_widget.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Map<String, dynamic>? product;
  List images = [];
  int quantity = 1;
  String? thumbnailImage;
  bool loading = true;

  // Thêm các biến cho carousel
  PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _carouselTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;

    // Handle both product object passing and ID passing
    if (args is Map<String, dynamic>) {
      setState(() {
        product = args;
        images = product!['image'] is List ? product!['image'] : [];
        thumbnailImage = images.isNotEmpty ? images[0] : null;
        loading = false;
      });
      _startAutoSlide();
    } else if (args is String) {
      // If only ID is passed
      fetchProduct(args);
    }
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _carouselTimer?.cancel();
    if (images.length <= 1) return;
    _carouselTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (_pageController.hasClients && images.isNotEmpty) {
        int nextPage = (_currentPage + 1) % images.length;
        _pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> fetchProduct(String id) async {
    setState(() {
      loading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:4003/api/product/$id'),
      );

      if (response.statusCode == 200) {
        setState(() {
          product = json.decode(response.body);
          images = product!['image'] is List ? product!['image'] : [];
          thumbnailImage = images.isNotEmpty ? images[0] : null;
          loading = false;
        });
        _startAutoSlide();
      } else {
        // Handle error
        setState(() {
          loading = false;
        });
        // Navigate to not found page
        Navigator.pushReplacementNamed(context, '/not-found');
      }
    } catch (error) {
      print('Error fetching product: $error');
      setState(() {
        loading = false;
      });
      // Navigate to not found page
      Navigator.pushReplacementNamed(context, '/not-found');
    }
  }

  void handleAddToCart() async {
    if (product == null) return;
    if (quantity <= 0 || quantity > product!['quantity']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Số lượng phải từ 1 đến ${product!['quantity']}'),
        ),
      );
      return;
    }
    await addToCart(product!, quantity, context);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Chi tiết sản phẩm')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Chi tiết sản phẩm')),
        body: Center(child: Text('Không tìm thấy sản phẩm.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết sản phẩm'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Navigation breadcrumbs
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: SingleChildScrollView(
            //     scrollDirection: Axis.horizontal,
            //     child: Wrap(
            //       children: [
            //         TextButton(
            //           onPressed: () => Navigator.pushNamed(context, '/'),
            //           child: Text('Trang chủ'),
            //         ),
            //         Text(' / '),
            //         TextButton(
            //           onPressed:
            //               () => Navigator.pushNamed(context, '/products'),
            //           child: Text('Sản phẩm'),
            //         ),
            //         Text(' / '),
            //         if (product!['categoryId'] != null &&
            //             product!['categoryId'] is Map)
            //           Wrap(
            //             children: [
            //               TextButton(
            //                 onPressed:
            //                     () => Navigator.pushNamed(
            //                       context,
            //                       '/category/${product!['categoryId']['_id']}',
            //                     ),
            //                 child: Text(product!['categoryId']['name']),
            //               ),
            //               Text(' / '),
            //             ],
            //           ),
            //         Text(
            //           product!['name'] ?? '',
            //           style: TextStyle(fontWeight: FontWeight.bold),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),

            // Product details container
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column: Product images (carousel)
                  Expanded(
                    flex: 10,
                    child: Column(
                      children: [
                        // Carousel
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child:
                              images.isNotEmpty
                                  ? Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      PageView.builder(
                                        controller: _pageController,
                                        itemCount: images.length,
                                        onPageChanged: (index) {
                                          setState(() {
                                            _currentPage = index;
                                            thumbnailImage = images[index];
                                          });
                                        },
                                        itemBuilder: (context, index) {
                                          return Image.network(
                                            images[index],
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Icon(
                                                      Icons.broken_image,
                                                      size: 100,
                                                    ),
                                          );
                                        },
                                      ),
                                      // Indicator dots
                                      Positioned(
                                        bottom: 8,
                                        left: 0,
                                        right: 0,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: List.generate(
                                            images.length,
                                            (index) => Container(
                                              margin: EdgeInsets.symmetric(
                                                horizontal: 3,
                                              ),
                                              width:
                                                  _currentPage == index
                                                      ? 12
                                                      : 8,
                                              height:
                                                  _currentPage == index
                                                      ? 12
                                                      : 8,
                                              decoration: BoxDecoration(
                                                color:
                                                    _currentPage == index
                                                        ? Colors.blue
                                                        : Colors.grey[400],
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                  : Icon(Icons.image_not_supported, size: 100),
                        ),
                        // Thumbnail images
                        if (images.length > 1) ...[
                          SizedBox(height: 16),
                          SizedBox(
                            height: 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: images.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () {
                                    _pageController.jumpToPage(index);
                                  },
                                  child: Container(
                                    width: 80,
                                    margin: EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color:
                                            _currentPage == index
                                                ? Colors.blue
                                                : Colors.grey[300]!,
                                        width: _currentPage == index ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(7),
                                      child: Image.network(
                                        images[index],
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(Icons.broken_image),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(width: 16),

                  // Right column: Product info
                  Expanded(
                    flex: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product name
                        Text(
                          product!['name'] ?? '',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),

                        // Reviews section
                        Row(
                          children: List.generate(
                            5,
                            (index) =>
                                Icon(Icons.star, color: Colors.amber, size: 20),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Benefits section
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'An tâm mua sắm',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              PurchaseBenefitsWidget(),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),

                        // Price
                        Text(
                          product!['price'] != null
                              ? '₫${product!['price'].toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}'
                              : '',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 24),

                        // Quantity selector
                        Wrap(
                          spacing: 16,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('Số Lượng:', style: TextStyle(fontSize: 16)),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Decrease button
                                  InkWell(
                                    onTap: () {
                                      if (quantity > 1) {
                                        setState(() {
                                          quantity--;
                                        });
                                      }
                                    },
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      alignment: Alignment.center,
                                      child: Icon(Icons.remove),
                                    ),
                                  ),
                                  // Quantity input
                                  Container(
                                    width: 50,
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        left: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                        right: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                    ),
                                    child: TextField(
                                      controller: TextEditingController(
                                        text: quantity.toString(),
                                      ),
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.zero,
                                        border: InputBorder.none,
                                      ),
                                      onChanged: (value) {
                                        int? val = int.tryParse(value);
                                        if (val != null) {
                                          if (val < 1) {
                                            setState(() {
                                              quantity = 1;
                                            });
                                          } else if (val >
                                              product!['quantity']) {
                                            setState(() {
                                              quantity = product!['quantity'];
                                            });
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Chỉ còn ${product!['quantity']} sản phẩm trong kho',
                                                ),
                                              ),
                                            );
                                          } else {
                                            setState(() {
                                              quantity = val;
                                            });
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                  // Increase button
                                  InkWell(
                                    onTap: () {
                                      if (quantity < product!['quantity']) {
                                        setState(() {
                                          quantity++;
                                        });
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Chỉ còn ${product!['quantity']} sản phẩm trong kho',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      alignment: Alignment.center,
                                      child: Icon(Icons.add),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Wrap(
                              children: [
                                Text(
                                  '${product!['quantity']} ',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  'Sản phẩm ${product!['status']}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 32),

                        // Add to cart buttons
                        Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          children: [
                            ElevatedButton.icon(
                              onPressed: handleAddToCart,
                              icon: Icon(Icons.shopping_cart),
                              label: Text('Thêm vào giỏ hàng'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blue,
                                side: BorderSide(color: Colors.blue),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // Handle voucher purchase
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Mua với voucher')),
                                );
                              },
                              child: Text(
                                'Mua với Voucher ${product!['discounted_price'] ?? ''}',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
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

            // Related products section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sản phẩm khác',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  OtherProductsWidget(currentProductId: product!['_id']),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget for displaying related products
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
      print('Error fetching related products: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (products.isEmpty) {
      return Center(child: Text('Không có sản phẩm khác'));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: products.length > 4 ? 4 : products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final imageUrl =
            (product['image'] is List && product['image'].isNotEmpty)
                ? product['image'][0]
                : '';

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
                // Product image
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                    child:
                        imageUrl.isNotEmpty
                            ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder:
                                  (context, error, stackTrace) => Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                                  ),
                            )
                            : Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: Icon(
                                  Icons.image,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                  ),
                ),
                // Product info
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        product['price'] != null
                            ? '₫${product['price'].toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}'
                            : '',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
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

// Supporting widget implementation
class PurchaseBenefitsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildBenefitItem(Icons.verified_user, 'Hàng chính hãng 100%'),
        _buildBenefitItem(Icons.assignment_return, '7 ngày miễn phí trả hàng'),
        _buildBenefitItem(Icons.local_shipping, 'Miễn phí vận chuyển'),
      ],
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.green),
          SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
