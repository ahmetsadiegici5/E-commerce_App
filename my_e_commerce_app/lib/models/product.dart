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

  factory Product.fromMap(Map<String, dynamic> map, {String? id}) {
    return Product(
      id: id ?? map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageURL: _cleanUrl(map['imageURL'] ?? ''),
      category: map['category'] ?? '',
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  // Bazı kayıtlarda URL tırnak içinde saklanmış
  static String _cleanUrl(String url) {
    if (url.length > 1 && url.startsWith('"') && url.endsWith('"')) {
      return url.substring(1, url.length - 1);
    }
    return url;
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
