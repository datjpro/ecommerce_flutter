import 'package:flutter/material.dart';

class CartItem {
  final String productId;
  final String productName;
  final double productPrice;
  final String productImage;
  int quantity;

  CartItem({
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.productImage,
    this.quantity = 1,
  });
}

class AppProvider extends ChangeNotifier {
  List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => _cartItems;

  void addToCart(CartItem item) {
    final index = _cartItems.indexWhere((e) => e.productId == item.productId);
    if (index >= 0) {
      _cartItems[index].quantity += item.quantity;
    } else {
      _cartItems.add(item);
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  void increaseCartItemQuantity(String productId) {
    final index = _cartItems.indexWhere((e) => e.productId == productId);
    if (index >= 0) {
      _cartItems[index].quantity += 1;
      notifyListeners();
    }
  }

  void decreaseCartItemQuantity(String productId) {
    final index = _cartItems.indexWhere((e) => e.productId == productId);
    if (index >= 0 && _cartItems[index].quantity > 1) {
      _cartItems[index].quantity -= 1;
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}
