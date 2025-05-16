import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class CategoryListScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryListScreen({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  List products = [];
  bool isLoading = true;
  ScrollController _scrollController = ScrollController();
  bool _isSearchExpanded = false;
  TextEditingController _searchController = TextEditingController();
  String _sortOption = 'recommended';
  bool _isFilterVisible = false;
  RangeValues _priceRange = RangeValues(0, 10000000);

  final currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchProducts() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(
      'http://localhost:4003/api/product/by-category/${widget.categoryId}',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          products = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải sản phẩm. Vui lòng thử lại sau.'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: ${e.toString()}')));
    }
  }

  void _sortProducts() {
    setState(() {
      switch (_sortOption) {
        case 'price_asc':
          products.sort((a, b) => (a['price'] ?? 0).compareTo(b['price'] ?? 0));
          break;
        case 'price_desc':
          products.sort((a, b) => (b['price'] ?? 0).compareTo(a['price'] ?? 0));
          break;
        case 'newest':
          products.sort((a, b) {
            final aDate =
                a['createdAt'] != null
                    ? DateTime.parse(a['createdAt'])
                    : DateTime.now();
            final bDate =
                b['createdAt'] != null
                    ? DateTime.parse(b['createdAt'])
                    : DateTime.now();
            return bDate.compareTo(aDate);
          });
          break;
        case 'popular':
          // Giả sử có trường rating hoặc sold để sắp xếp theo mức độ phổ biến
          products.sort((a, b) => (b['sold'] ?? 0).compareTo(a['sold'] ?? 0));
          break;
        default: // recommended
          // Giữ nguyên thứ tự từ API
          break;
      }
    });
  }

  void _filterProducts() {
    String searchQuery = _searchController.text.toLowerCase();

    setState(() {
      if (searchQuery.isEmpty) {
        // Nếu không có từ khóa tìm kiếm, chỉ lọc theo giá
        products =
            products.where((product) {
              final price = product['price'] ?? 0;
              return price >= _priceRange.start && price <= _priceRange.end;
            }).toList();
      } else {
        // Lọc theo từ khóa tìm kiếm và giá
        products =
            products.where((product) {
              final name = product['name']?.toLowerCase() ?? '';
              final description = product['description']?.toLowerCase() ?? '';
              final price = product['price'] ?? 0;

              return (name.contains(searchQuery) ||
                      description.contains(searchQuery)) &&
                  (price >= _priceRange.start && price <= _priceRange.end);
            }).toList();
      }
    });

    _sortProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body:
          isLoading
              ? _buildLoadingIndicator()
              : products.isEmpty
              ? _buildEmptyState()
              : _buildProductGrid(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title:
          _isSearchExpanded
              ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm ${widget.categoryName}...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
                onSubmitted: (_) => _filterProducts(),
              )
              : Text(
                widget.categoryName,
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
      leading: IconButton(
        icon: Icon(
          _isSearchExpanded ? Icons.arrow_back : Icons.arrow_back,
          color: Colors.black87,
        ),
        onPressed: () {
          if (_isSearchExpanded) {
            setState(() {
              _isSearchExpanded = false;
              _searchController.clear();
            });
            _filterProducts();
          } else {
            Navigator.pop(context);
          }
        },
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isSearchExpanded ? Icons.clear : Icons.search,
            color: Colors.black87,
          ),
          onPressed: () {
            setState(() {
              _isSearchExpanded = !_isSearchExpanded;
            });
            if (!_isSearchExpanded) {
              _searchController.clear();
              _filterProducts();
            }
          },
        ),
        IconButton(
          icon: Icon(Icons.shopping_cart_outlined, color: Colors.black87),
          onPressed: () {
            Navigator.pushNamed(context, '/cart');
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(_isFilterVisible ? 120 : 50),
        child: Column(
          children: [
            Container(
              height: 50,
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildSortOption('Đề xuất', 'recommended'),
                          _buildSortOption('Mới nhất', 'newest'),
                          _buildSortOption('Phổ biến', 'popular'),
                          _buildSortOption('Giá thấp → cao', 'price_asc'),
                          _buildSortOption('Giá cao → thấp', 'price_desc'),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    icon: Icon(
                      _isFilterVisible
                          ? Icons.filter_list
                          : Icons.filter_alt_outlined,
                      color: _isFilterVisible ? Colors.blue : Colors.black87,
                    ),
                    onPressed: () {
                      setState(() {
                        _isFilterVisible = !_isFilterVisible;
                      });
                    },
                  ),
                ],
              ),
            ),
            if (_isFilterVisible)
              Container(
                height: 70,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Khoảng giá: ${currencyFormatter.format(_priceRange.start.round())} - ${currencyFormatter.format(_priceRange.end.round())}',
                        style: TextStyle(fontSize: 12),
                      ),
                      RangeSlider(
                        values: _priceRange,
                        min: 0,
                        max: 10000000,
                        divisions: 20,
                        activeColor: Colors.blue,
                        inactiveColor: Colors.blue.withOpacity(0.2),
                        onChanged: (values) {
                          setState(() {
                            _priceRange = values;
                          });
                        },
                        onChangeEnd: (_) => _filterProducts(),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, String value) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortOption = value;
        });
        _sortProducts();
      },
      child: Container(
        margin: EdgeInsets.only(right: 16),
        child: Text(
          title,
          style: TextStyle(
            color: _sortOption == value ? Colors.blue : Colors.black87,
            fontWeight:
                _sortOption == value ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          SizedBox(height: 16),
          Text('Đang tải sản phẩm...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Không có sản phẩm nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Danh mục này hiện chưa có sản phẩm',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => fetchProducts(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return RefreshIndicator(
      onRefresh: fetchProducts,
      color: Colors.blue,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: MasonryGridView.count(
          controller: _scrollController,
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final bool hasDiscount =
                product['originalPrice'] != null &&
                product['originalPrice'] > product['price'];

            // Tính phần trăm giảm giá nếu có
            int discountPercent = 0;
            if (hasDiscount) {
              final originalPrice = product['originalPrice'] ?? 0;
              final currentPrice = product['price'] ?? 0;
              if (originalPrice > 0) {
                discountPercent =
                    (((originalPrice - currentPrice) / originalPrice) * 100)
                        .round();
              }
            }

            return _buildProductCard(product, hasDiscount, discountPercent);
          },
        ),
      ),
    );
  }

  Widget _buildProductCard(Map product, bool hasDiscount, int discountPercent) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/product_detail', arguments: product);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child:
                      product['image'] != null && product['image'].isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl: product['image'][0],
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => Container(
                                  height: 180,
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  height: 180,
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                ),
                          )
                          : Container(
                            height: 180,
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.image,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                ),
                // Discount badge
                if (hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '-$discountPercent%',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                // Wishlist button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.favorite_border,
                        color: Colors.red,
                        size: 20,
                      ),
                      constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        // Add to wishlist functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã thêm vào mục yêu thích')),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

            // Product Info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    product['name'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),

                  // Price information
                  Row(
                    children: [
                      Text(
                        currencyFormatter.format(product['price'] ?? 0),
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (hasDiscount) ...[
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            currencyFormatter.format(
                              product['originalPrice'] ?? 0,
                            ),
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Rating and sold
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber),
                      SizedBox(width: 2),
                      Text(
                        '${product['rating'] ?? 5.0}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đã bán ${product['sold'] ?? 0}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Add to cart button
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Add to cart functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã thêm vào giỏ hàng')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Thêm vào giỏ',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
