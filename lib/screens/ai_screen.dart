import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
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

  final String _apiKey =
      'xai-3euSc4v3T9XtD3CBkKyUZfd01KnqdTMAzDavHx7kM6PpPs6821x23SrI28U0KtbIgiLwiqLjLkYSk5wU';

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  // Đọc sản phẩm từ file assets
  Future<void> fetchProducts() async {
    setState(() {
      _loadingProducts = true;
    });
    try {
      final response = await http.get(
        Uri.parse('http://localhost:4003/api/product/all'),
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

  // Tạo messages chuẩn OpenAI API
  List<Map<String, dynamic>> _buildMessages(String userPrompt) {
    final productInfo = products
        .map(
          (p) =>
              '- ${p['name'] ?? ''} (${p['price'] ?? ''}): ${p['describe'] ?? ''}', // Sửa 'desc' thành 'describe'
        )
        .join('\n');
    return [
      {
        "role": "system",
        "content":
            "Bạn là trợ lý AI Grok cho cửa hàng online. Dưới đây là danh sách sản phẩm hiện có:\n$productInfo\n"
            "Khi người dùng hỏi, hãy gợi ý các sản phẩm phù hợp nhất với nhu cầu, sở thích hoặc từ khóa mà họ đưa ra. "
            "Nếu không tìm thấy sản phẩm phù hợp, hãy lịch sự thông báo và gợi ý các sản phẩm nổi bật khác.",
      },
      ..._messages.map((m) => {"role": m['role'], "content": m['content']}),
      {"role": "user", "content": userPrompt},
    ];
  }

  Future<String> sendMessageToGrok(
    List<Map<String, dynamic>> messages,
    String apiKey,
  ) async {
    final response = await http.post(
      Uri.parse('https://api.x.ai/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'grok-3-beta',
        'messages': messages,
        'stream': false,
        'temperature': 0.7,
        'max_tokens': 512,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices']?[0]?['message']?['content'] ??
          'Không có phản hồi.';
    } else {
      throw Exception(
        'Không thể nhận phản hồi: ${response.statusCode} - ${response.body}',
      );
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
      final messages = _buildMessages(prompt);
      final reply = await sendMessageToGrok(messages, _apiKey);
      setState(() {
        _messages.add({'role': 'assistant', 'content': reply});
      });
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
        subtitle: Text(p['desc']?.toString() ?? ''),
        trailing: Text(p['price']?.toString() ?? ''),
      ),
    );
  }

  Widget _buildMessage(Map<String, String> msg) {
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
      appBar: AppBar(title: const Text('Chat AI về sản phẩm')),
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
                      labelText: 'Nhập câu hỏi về sản phẩm...',
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
                          : const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
