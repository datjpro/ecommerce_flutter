class Product {
  final String id;
  final String name;
  final double price;
  final String describe;
  final List<String> image;
  final String status;
  final int views;
  final String? categoryId;
  final String? customerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.describe,
    required this.image,
    required this.status,
    required this.views,
    this.categoryId,
    this.customerId,
    this.createdAt,
    this.updatedAt,
  });

  // Hàm factory để tạo Product từ JSON (Map)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? '', // _id trong MongoDB
      name: json['name'] ?? '',
      price: (json['price'] is int)
          ? (json['price'] as int).toDouble()
          : (json['price'] ?? 0.0),
      describe: json['describe'] ?? '',
      image: json['image'] != null
          ? List<String>.from(json['image'])
          : <String>[],
      status: json['status'] ?? '',
      views: json['views'] ?? 0,
      categoryId: json['categoryId'] != null
          ? (json['categoryId'] is String
              ? json['categoryId']
              : json['categoryId']['_id'] ?? null)
          : null,
      customerId: json['customerId'] != null
          ? (json['customerId'] is String
              ? json['customerId']
              : json['customerId']['_id'] ?? null)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  // Hàm chuyển Product thành JSON (Map)
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'price': price,
      'describe': describe,
      'image': image,
      'status': status,
      'views': views,
      'categoryId': categoryId,
      'customerId': customerId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
