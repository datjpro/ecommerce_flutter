import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CategoryWidget extends StatefulWidget {
  @override
  _CategoryWidgetState createState() => _CategoryWidgetState();
}

class _CategoryWidgetState extends State<CategoryWidget> {
  List categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final response = await http.get(
      Uri.parse('http://localhost:3001/api/category/all'),
    );
    if (response.statusCode == 200) {
      setState(() {
        categories = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      // Xử lý lỗi nếu cần
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Danh mục',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            height: 300, // Tăng chiều cao cho phần danh mục
            child:
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : GridView.builder(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.8, // Item rộng hơn
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final item = categories[index];
                        return Container(
                          width: 110, // Tăng width
                          margin: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 36, // Icon to hơn
                                backgroundColor: Colors.blue.withOpacity(0.2),
                                backgroundImage:
                                    item['image'] != null &&
                                            item['image'].toString().isNotEmpty
                                        ? NetworkImage(item['image'])
                                        : null,
                                child:
                                    item['image'] == null ||
                                            item['image'].toString().isEmpty
                                        ? Icon(
                                          Icons.category,
                                          color: Colors.blue,
                                          size: 32, // Icon to hơn
                                        )
                                        : null,
                              ),
                              SizedBox(height: 10),
                              Text(
                                item['name'] ?? '',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
