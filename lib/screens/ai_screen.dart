import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  bool _loadingProducts = true;
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  // Đọc sản phẩm từ API
  Future<void> fetchProducts() async {
    setState(() {
      _loadingProducts = true;
    });
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:4003/api/product/all'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        products = List<Map<String, dynamic>>.from(data['products']);
      } else {
        products = [];
      }
    } catch (e) {
      products = [];
    }
    setState(() {
      _loadingProducts = false;
    });
  }

  Future<List<Map<String, String>>> parseProductsFromAnswer(
    String answer,
  ) async {
    final List<Map<String, String>> products = [];
    final regex = RegExp(
      r'-{9,} SẢN PHẨM \d+ -{9,}\nMã: (.+)\nTên: (.+)\nGiá: (.+)\nTình trạng: (.+)\nDanh mục: (.+)\nNgười bán: (.+)',
      multiLine: true,
    );
    for (final match in regex.allMatches(answer)) {
      products.add({
        'id': match.group(1) ?? '',
        'name': match.group(2) ?? '',
        'price': match.group(3) ?? '',
        'status': match.group(4) ?? '',
        'category': match.group(5) ?? '',
        'seller': match.group(6) ?? '',
      });
    }
    return products;
  }

  Future<String> sendMessageToFlaskAPI(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': userMessage}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['answer'] ?? 'Không có phản hồi.';
      } else {
        return 'Không thể kết nối với dịch vụ tìm kiếm. Mã lỗi: ${response.statusCode}';
      }
    } catch (e) {
      return 'Lỗi kết nối: ${e.toString()}';
    }
  }

  Future<void> _sendMessage() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': prompt});
      _isLoading = true;
    });

    try {
      final reply = await sendMessageToFlaskAPI(prompt);
      final productList = await parseProductsFromAnswer(reply);
      if (productList.isNotEmpty) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': reply,
            'type': 'products',
          });
          _messages.addAll(
            productList.map(
              (p) => {
                'role': 'product',
                'name': p['name'] ?? '',
                'price': p['price'] ?? '',
                'status': p['status'] ?? '',
                'category': p['category'] ?? '',
                'seller': p['seller'] ?? '',
              },
            ),
          );
        });
      } else {
        setState(() {
          _messages.add({'role': 'assistant', 'content': reply});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'Lỗi: ${e.toString()}'});
      });
    } finally {
      setState(() {
        _isLoading = false;
        _controller.clear();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildProductCard(Map<String, dynamic> p) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(p['name']?.toString() ?? ''),
        subtitle: Text(p['describe']?.toString() ?? ''),
        trailing: Text(p['price']?.toString() ?? ''),
      ),
    );
  }

  Widget _buildMessage(Map<String, String> msg) {
    if (msg['role'] == 'product') {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          title: Text(msg['name'] ?? ''),
          subtitle: Text(
            'Giá: ${msg['price']}\nTình trạng: ${msg['status']}\nDanh mục: ${msg['category']}\nNgười bán: ${msg['seller']}',
          ),
        ),
      );
    }
    final isUser = msg['role'] == 'user';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(msg['content'] ?? ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tìm kiếm sản phẩm')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, idx) => _buildMessage(_messages[idx]),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Nhập tên sản phẩm cần tìm...',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.search),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
