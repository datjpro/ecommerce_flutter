import 'package:flutter/material.dart';

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
