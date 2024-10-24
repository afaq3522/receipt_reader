class Order {
  List<Item> items;
  double subtotal;
  double tax;
  double total;

  Order({
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
  });

  // Convert JSON to Order object
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      items: (json['items'] as List<dynamic>)
          .map((itemJson) => Item.fromJson(itemJson))
          .toList(),
      subtotal: json['subtotal'].toDouble(),
      tax: json['tax'].toDouble(),
      total: json['total'].toDouble(),
    );
  }

  // Convert Order object to JSON
  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
    };
  }

  // Create a copy with optional parameters to replace fields
  Order copyWith({
    List<Item>? items,
    double? subtotal,
    double? tax,
    double? total,
  }) {
    return Order(
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
    );
  }

  @override
  String toString() {
    return 'Order(items: $items, subtotal: $subtotal, tax: $tax, total: $total)';
  }
}

class Item {
  String name;
  int quantity;
  double price;
  String category;

  Item(
      {required this.name,
      required this.quantity,
      required this.price,
      required this.category});

  // Convert JSON to Item object
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
        name: json['name'],
        quantity: json['quantity'].toInt(),
        price: json['price'].toDouble(),
        category: json['category'].toString().toLowerCase());
  }

  // Convert Item object to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'category': category.toLowerCase()
    };
  }

  // Create a copy with optional parameters to replace fields
  Item copyWith({
    String? name,
    int? quantity,
    double? price,
    String? category,
  }) {
    return Item(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      category: (category ?? this.category).toLowerCase(),
    );
  }

  @override
  String toString() {
    return 'Item(name: $name, quantity: $quantity, price: $price, category: $category)';
  }
}
