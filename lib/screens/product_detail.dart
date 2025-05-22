import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
  bool isFavorite = false;

  // Carousel variables
  PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _carouselTimer;

  // Tab controller for product details
  int _selectedTab = 0;

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
    _carouselTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (_pageController.hasClients && images.isNotEmpty) {
        int nextPage = (_currentPage + 1) % images.length;
        _pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 600),
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
        Uri.parse('http://10.0.2.2:4003/api/product/$id'),
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
        setState(() {
          loading = false;
        });
        Navigator.pushReplacementNamed(context, '/not-found');
      }
    } catch (error) {
      print('Error fetching product: $error');
      setState(() {
        loading = false;
      });
      Navigator.pushReplacementNamed(context, '/not-found');
    }
  }

  // Thay đổi hàm handleAddToCart để trả về true nếu đã đăng nhập, false nếu chưa đăng nhập
  Future<bool> handleAddToCart() async {
    if (product == null) return false;
    if (quantity <= 0 || quantity > product!['quantity']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: Colors.red.shade800,
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Số lượng phải từ 1 đến ${product!['quantity']}'),
            ],
          ),
        ),
      );
      return false;
    }

    // Kiểm tra đăng nhập trước
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: Colors.red.shade800,
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Vui lòng đăng nhập để thêm vào giỏ hàng'),
            ],
          ),
          action: SnackBarAction(
            label: 'ĐĂNG NHẬP',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
          ),
        ),
      );
      return false;
    }

    // Nếu đã đăng nhập, tiến hành thêm vào giỏ hàng
    bool success = await addToCart(product!, quantity, context);

    // Chỉ hiển thị thông báo thành công nếu thực sự thành công
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: Colors.green.shade700,
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Đã thêm vào giỏ hàng')),
            ],
          ),
          action: SnackBarAction(
            label: 'XEM GIỎ HÀNG',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
        ),
      );
    }
    return success;
  }

  String formatCurrency(dynamic price) {
    if (price == null) return '';
    return '₫${price.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
  }

  Widget _buildRatingBar(double rating, {int totalReviews = 0}) {
    return Row(
      children: [
        ...List.generate(5, (index) {
          return Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: index < rating ? Colors.amber : Colors.grey,
            size: 18,
          );
        }),
        SizedBox(width: 8),
        Text(
          rating.toString(),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(width: 4),
        Flexible(
          // Sửa từ Expanded thành Flexible
          child: Text(
            '($totalReviews đánh giá)',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Chi tiết sản phẩm'),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Theme.of(context).primaryColor),
              SizedBox(height: 16),
              Text(
                'Đang tải sản phẩm...',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (product == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Chi tiết sản phẩm'),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
              SizedBox(height: 16),
              Text(
                'Không tìm thấy sản phẩm',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/products');
                },
                child: Text('Xem sản phẩm khác'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back),
            color: Colors.black87,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.black87,
              ),
              onPressed: () {
                setState(() {
                  isFavorite = !isFavorite;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text(
                      isFavorite
                          ? 'Đã thêm vào danh sách yêu thích'
                          : 'Đã xóa khỏi danh sách yêu thích',
                    ),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
          Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.shopping_cart, color: Colors.black87),
                  onPressed: () {
                    Navigator.pushNamed(context, '/cart');
                  },
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '0',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image carousel with overlay gradient
            Stack(
              children: [
                Container(
                  height: 360,
                  width: double.infinity,
                  child:
                      images.isNotEmpty
                          ? PageView.builder(
                            controller: _pageController,
                            itemCount: images.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentPage = index;
                                thumbnailImage = images[index];
                              });
                            },
                            itemBuilder: (context, index) {
                              return Hero(
                                tag: 'product-${product!['_id']}-$index',
                                child: Image.network(
                                  images[index],
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Container(
                                        color: Colors.grey[200],
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 100,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                ),
                              );
                            },
                          )
                          : Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.image_not_supported,
                              size: 100,
                              color: Colors.grey[400],
                            ),
                          ),
                ),
                // Gradient overlay at the bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                ),
                // Indicator dots
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      images.length,
                      (index) => AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        margin: EdgeInsets.symmetric(horizontal: 3),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color:
                              _currentPage == index
                                  ? Theme.of(context).primaryColor
                                  : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Product details
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name and price
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                product?['name'] ??
                                    '', // Thêm dấu ? để kiểm tra null
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          // Thay vì mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              // Thêm Expanded cho cột giá
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formatCurrency(product!['price']),
                                    style: TextStyle(
                                      fontSize: 28,
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (product!['discounted_price'] != null) ...[
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          formatCurrency(
                                            product!['discounted_price'],
                                          ),
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            '-20%',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Bao widget đánh giá trong một container có chiều rộng cố định
                            Container(
                              width: 140, // Giới hạn chiều rộng
                              child: _buildRatingBar(4.5, totalReviews: 120),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Divider(),

                  // Benefits section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'An tâm mua sắm',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          SizedBox(height: 12),
                          EnhancedPurchaseBenefitsWidget(),
                        ],
                      ),
                    ),
                  ),

                  // Quantity selection
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Số lượng',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  // Decrease button
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        if (quantity > 1) {
                                          setState(() {
                                            quantity--;
                                          });
                                        }
                                      },
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        bottomLeft: Radius.circular(8),
                                      ),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.remove,
                                          color:
                                              quantity > 1
                                                  ? Colors.black87
                                                  : Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Quantity input
                                  Container(
                                    width: 60,
                                    height: 40,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        left: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                        right: BorderSide(
                                          color: Colors.grey.shade300,
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
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
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
                                                behavior:
                                                    SnackBarBehavior.floating,
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
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
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
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              content: Text(
                                                'Chỉ còn ${product!['quantity']} sản phẩm trong kho',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(8),
                                        bottomRight: Radius.circular(8),
                                      ),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.add,
                                          color:
                                              quantity < product!['quantity']
                                                  ? Colors.black87
                                                  : Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              'Còn ${product!['quantity']} sản phẩm',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Product detail tabs
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Tab buttons
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildTabButton('Thông tin', 0),
                              _buildTabButton('Đánh giá', 1),
                              _buildTabButton('Chính sách', 2),
                            ],
                          ),
                        ),
                        // Tab content
                        Container(
                          padding: EdgeInsets.all(16),
                          child: SingleChildScrollView(
                            child:
                                [
                                  // Product description tab
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Mô tả sản phẩm',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        product!['description'] ??
                                            'Không có mô tả sản phẩm',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.grey.shade800,
                                          height: 1.5,
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      Text(
                                        'Thông số kỹ thuật',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            _buildSpecRow(
                                              'Thương hiệu',
                                              'Brand XYZ',
                                              true,
                                            ),
                                            _buildSpecRow(
                                              'Xuất xứ',
                                              'Việt Nam',
                                              false,
                                            ),
                                            _buildSpecRow(
                                              'Chất liệu',
                                              'Premium',
                                              true,
                                            ),
                                            _buildSpecRow(
                                              'Kích thước',
                                              'Standard',
                                              false,
                                            ),
                                            _buildSpecRow(
                                              'Bảo hành',
                                              '12 tháng',
                                              true,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Reviews tab
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Đánh giá sản phẩm',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextButton.icon(
                                            onPressed: () {},
                                            icon: Icon(Icons.rate_review),
                                            label: Text('Viết đánh giá'),
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  Theme.of(
                                                    context,
                                                  ).primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16),
                                      Container(
                                        padding: EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  '4.5',
                                                  style: TextStyle(
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: List.generate(
                                                        5,
                                                        (index) => Icon(
                                                          index < 4.5
                                                              ? Icons.star
                                                              : Icons.star_half,
                                                          color: Colors.amber,
                                                          size: 24,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      '120 đánh giá',
                                                      style: TextStyle(
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 16),
                                            _buildRatingBar2(
                                              5,
                                              82,
                                              'Rất hài lòng',
                                            ),
                                            _buildRatingBar2(4, 24, 'Hài lòng'),
                                            _buildRatingBar2(
                                              3,
                                              10,
                                              'Bình thường',
                                            ),
                                            _buildRatingBar2(
                                              2,
                                              3,
                                              'Không hài lòng',
                                            ),
                                            _buildRatingBar2(
                                              1,
                                              1,
                                              'Rất không hài lòng',
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      // Sample reviews
                                      _buildReviewItem(
                                        name: 'Nguyễn Văn A',
                                        rating: 5,
                                        date: '12/05/2025',
                                        comment:
                                            'Sản phẩm rất tốt, đóng gói cẩn thận, giao hàng nhanh. Tôi rất hài lòng với sản phẩm này!',
                                      ),
                                      Divider(),
                                      _buildReviewItem(
                                        name: 'Trần Thị B',
                                        rating: 4,
                                        date: '10/05/2025',
                                        comment:
                                            'Sản phẩm đẹp, chất lượng tốt. Giao hàng hơi lâu nhưng vẫn ổn.',
                                      ),
                                    ],
                                  ),
                                  // Policies tab
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Chính sách mua hàng',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      _buildPolicyItem(
                                        Icons.local_shipping,
                                        'Chính sách vận chuyển',
                                        'Miễn phí vận chuyển cho đơn hàng từ 300,000đ. Phí vận chuyển 30,000đ cho đơn hàng dưới 300,000đ.',
                                      ),
                                      _buildPolicyItem(
                                        Icons.assignment_return,
                                        'Chính sách đổi trả',
                                        'Được đổi trả trong vòng 7 ngày kể từ ngày nhận hàng nếu sản phẩm còn nguyên vẹn, có hóa đơn và tem mác đầy đủ.',
                                      ),
                                      _buildPolicyItem(
                                        Icons.security,
                                        'Chính sách bảo hành',
                                        'Bảo hành chính hãng 12 tháng theo tiêu chuẩn nhà sản xuất.',
                                      ),
                                      _buildPolicyItem(
                                        Icons.payment,
                                        'Phương thức thanh toán',
                                        'Hỗ trợ thanh toán qua thẻ tín dụng, chuyển khoản ngân hàng, ví điện tử và thanh toán khi nhận hàng (COD).',
                                      ),
                                    ],
                                  ),
                                ][_selectedTab],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Related products section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Sản phẩm tương tự',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/products');
                              },
                              child: Text('Xem thêm'),
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        EnhancedOtherProductsWidget(
                          currentProductId: product!['_id'],
                          categoryId:
                              product!['categoryId'] is Map
                                  ? product!['categoryId']['_id']
                                  : product!['categoryId'],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Chat button
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tính năng đang phát triển')),
                  );
                },
                icon: Icon(Icons.message_outlined),
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(width: 12),
            // Add to cart button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await handleAddToCart();
                },
                icon: Icon(Icons.shopping_cart_outlined),
                label: Text('THÊM VÀO GIỎ HÀNG'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            // Buy now button
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  bool loggedIn = await handleAddToCart();
                  if (loggedIn) {
                    Navigator.pushNamed(context, '/checkout');
                  }
                  // Nếu chưa đăng nhập, chỉ hiện thông báo, không chuyển trang
                },
                child: Text('MUA NGAY'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color:
                    isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color:
                  isSelected ? Theme.of(context).primaryColor : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, bool isEven) {
    return Container(
      color: isEven ? Colors.grey.shade50 : Colors.white,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar2(int stars, int count, String label) {
    double percentage = (count / 120) * 100;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$stars★',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  height: 8,
                  width: percentage * 2,
                  decoration: BoxDecoration(
                    color:
                        stars >= 4
                            ? Colors.green
                            : stars >= 3
                            ? Colors.amber
                            : Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem({
    required String name,
    required double rating,
    required String date,
    required String comment,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                child: Icon(Icons.person, color: Colors.grey.shade700),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        );
                      }),
                      SizedBox(width: 8),
                      Text(
                        date,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(comment, style: TextStyle(color: Colors.grey.shade800)),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(IconData icon, String title, String description) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          SizedBox(width: 16),
          Expanded(
            // Đảm bảo thêm Expanded cho text có thể dài
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced purchase benefits widget
class EnhancedPurchaseBenefitsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildBenefitItem(
          Icons.verified_user,
          'Hàng chính hãng 100%',
          'Cam kết sản phẩm chính hãng từ nhà sản xuất',
        ),
        _buildBenefitItem(
          Icons.assignment_return,
          '7 ngày miễn phí trả hàng',
          'Trả hàng miễn phí trong 7 ngày nếu có lỗi từ nhà sản xuất',
        ),
        _buildBenefitItem(
          Icons.local_shipping,
          'Miễn phí vận chuyển',
          'Miễn phí vận chuyển cho đơn hàng từ 300.000đ',
        ),
      ],
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: Colors.blue.shade700),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced related products widget
class EnhancedOtherProductsWidget extends StatefulWidget {
  final String currentProductId;
  final String? categoryId;

  const EnhancedOtherProductsWidget({
    required this.currentProductId,
    this.categoryId,
  });

  @override
  State<EnhancedOtherProductsWidget> createState() =>
      _EnhancedOtherProductsWidgetState();
}

class _EnhancedOtherProductsWidgetState
    extends State<EnhancedOtherProductsWidget> {
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
        Uri.parse('http://10.0.2.2:4003/api/product/all'),
      );

      if (response.statusCode == 200) {
        final allProducts = json.decode(response.body);
        final productList = allProducts['products'] ?? [];

        setState(() {
          products =
              productList
                  .where(
                    (p) =>
                        p['_id'] != widget.currentProductId &&
                        (widget.categoryId == null ||
                            (p['categoryId'] is Map
                                ? p['categoryId']['_id'] == widget.categoryId
                                : p['categoryId'] == widget.categoryId)),
                  )
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

  String formatCurrency(dynamic price) {
    if (price == null) return '';
    return '₫${price.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (products.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'Không có sản phẩm tương tự',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return Container(
      height: 320, // Kích thước cố định là tốt
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length > 6 ? 6 : products.length,
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
            child: Container(
              width: 180,
              margin: EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Container(
                      height: 180,
                      width: 180,
                      child: Stack(
                        children: [
                          imageUrl.isNotEmpty
                              ? Hero(
                                tag: 'related-product-${product['_id']}',
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder:
                                      (context, error, stackTrace) => Container(
                                        color: Colors.grey[200],
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 60,
                                          color: Colors.grey,
                                        ),
                                      ),
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
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade500,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '-20%',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Product info
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                product['name'] ?? '',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              index < 4 ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 14,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          formatCurrency(product['price']),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (product['discounted_price'] != null) ...[
                          SizedBox(height: 2),
                          Text(
                            formatCurrency(product['discounted_price']),
                            style: TextStyle(
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

Future<bool> addToCart(
  Map<String, dynamic> product,
  int quantity,
  BuildContext context,
) async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId');

  if (userId == null) {
    return false;
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
      return true;
    } else {
      print('Failed to add to cart: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Không thể thêm vào giỏ hàng: ${response.statusCode}'),
            ],
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return false;
    }
  } catch (error) {
    print('Error adding to cart: $error');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Text('Lỗi kết nối: $error'),
          ],
        ),
        backgroundColor: Colors.red.shade700,
      ),
    );
    return false;
  }
}
