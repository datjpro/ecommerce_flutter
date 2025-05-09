import 'package:ecommerce_flutter/widgets/bottom_widhet.dart';
import 'package:ecommerce_flutter/widgets/taskbar_widget.dart';
import 'package:flutter/material.dart';
import '../widgets/slide_widget.dart';
import '../widgets/category_widget.dart';
import '../widgets/shop_mall_widget.dart';
import '../widgets/top_search_widget.dart';
import '../widgets/product_widget.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onScrollToTop;
  const HomeScreen({this.onScrollToTop, Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  void scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        controller: _scrollController,
        children: [
          TaskbarWidget(),
          SlideWidget(),
          CategoryWidget(),
          ShopMallWidget(),
          TopSearchWidget(),
          ProductWidget(),
        ],
      ),
      bottomNavigationBar: BottomWidget(onHomeTap: scrollToTop),
    );
  }
}
