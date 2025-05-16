import 'package:flutter/material.dart';

class TaskbarWidget extends StatefulWidget {
  final bool showBack;
  final VoidCallback? onBack;
  final Color backgroundColor;
  final double elevation;
  final List<Map<String, dynamic>> cartItems;
  final ValueChanged<String>? onSearch;
  final ValueChanged<String>? onSubmitted;
  final String? initialSearchText;

  const TaskbarWidget({
    Key? key,
    this.showBack = false,
    this.onBack,
    this.backgroundColor = Colors.orange,
    this.elevation = 4.0,
    this.cartItems = const [
      {'id': 1, 'quantity': 2},
      {'id': 2, 'quantity': 1},
    ],
    this.onSearch,
    this.onSubmitted,
    this.initialSearchText,
  }) : super(key: key);

  @override
  State<TaskbarWidget> createState() => _TaskbarWidgetState();
}

class _TaskbarWidgetState extends State<TaskbarWidget> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchText);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalCartItems = widget.cartItems.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int),
    );

    return Material(
      elevation: widget.elevation,
      color: widget.backgroundColor,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (widget.showBack)
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: widget.onBack ?? () => Navigator.pop(context),
                splashRadius: 24,
              )
            else
              const SizedBox(width: 48),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm sản phẩm, thương hiệu và tên shop',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                if (widget.onSearch != null) {
                                  widget.onSearch!('');
                                }
                              },
                            )
                            : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                  onChanged: widget.onSearch,
                  textInputAction: TextInputAction.search,
                  onSubmitted: widget.onSubmitted,
                ),
              ),
            ),

            SizedBox(
              width: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                    onPressed: () => Navigator.pushNamed(context, '/cart'),
                    splashRadius: 24,
                  ),
                  if (totalCartItems > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          totalCartItems > 99 ? '99+' : '$totalCartItems',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
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
