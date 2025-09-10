class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageURL;
  final String category;
  final int stock;
  final List<String> tags;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageURL,
    required this.category,
    required this.stock,
    required this.tags,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      imageURL: map['imageURL'] ?? '',
      category: map['category'] ?? '',
      stock: map['stock']?.toInt() ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageURL': imageURL,
      'category': category,
      'stock': stock,
      'tags': tags,
    };
  }
}
