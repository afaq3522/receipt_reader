/// Represents an order containing multiple items and the associated costs.
///
/// The [Order] class contains a list of [Item] objects, the subtotal for the
/// items, applicable tax, and the final total cost.
///
/// Example:
/// ```dart
/// Order order = Order(
///   invoiceNumber: vh524245426
///   paymentMethod: CASH
///   items: [
///     Item(name: 'Pizza', quantity: 1, price: 10.0, category: 'Food')
///   ],
///   subtotal: 10.0,
///   tax: 1.5,
///   total: 11.5
/// );
/// ```
class Order {
  /// This is the method used to make the transaction and always in upper case
  String? paymentMethod;

  ///invoice number, this is the unique number of the transaction
  String? invoiceNumber;

  ///The date of the transaction
  String? date;

  /// The list of items in the order.
  List<Item>? items;

  /// The subtotal amount before tax.
  double? subtotal;

  /// The amount of tax applied to the order.
  double? tax;

  /// The final total amount after tax.
  double? total;

  ///find the vendorName of receipt
  String? vendorName;

  /// Creates a new [Order] object with the given [items], [subtotal], [tax], and [total].
  Order({
    required this.date,
    required this.invoiceNumber,
    required this.paymentMethod,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
     this.vendorName
  });

  /// Converts a JSON object into an [Order] object.
  ///
  /// Expects the following JSON format:
  /// ```json
  /// {
  ///   "items": [
  ///     {
  ///       "name": "Item Name",
  ///       "quantity": 2,
  ///       "price": 10.5,
  ///       "category": "food"
  ///     }
  ///   ],
  ///   "subtotal": 21.0,
  ///   "tax": 2.1,
  ///   "total": 23.1
  /// }
  /// ```
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      date: json['date'],
      invoiceNumber: json['invoice_number'],
      paymentMethod: json['payment_method'].toString().toUpperCase(),
      items: (json['items'] as List<dynamic>)
          .map((itemJson) => Item.fromJson(itemJson))
          .toList(),
      subtotal: json['subtotal'].toDouble(),
      tax: json['tax'].toDouble(),
      total: json['total'].toDouble(),
      vendorName: json['vendor_name'],
    );
  }

  /// Converts this [Order] object into a JSON object.
  ///
  /// The resulting JSON will follow the same format as required by [Order.fromJson].
  Map<String, dynamic> toJson() {
    return {
      'items': items?.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'invoice_number': invoiceNumber,
      'date': date,
      'vendor_name': vendorName,
      'payment_method': paymentMethod?.toUpperCase(),
    };
  }

  /// Returns a copy of this [Order] object with the given fields replaced by new values.
  ///
  /// This can be useful when you want to create a modified version of an existing
  /// order without changing the original object.
  Order copyWith({
    List<Item>? items,
    double? subtotal,
    double? tax,
    double? total,
    String? invoiceNumber,
    String? vendorName,
    String? date,
    String? paymentMethod,
  }) {
    return Order(
      date: date ?? this.date,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      vendorName: vendorName ?? this.vendorName,
    );
  }

  @override
  String toString() {
    return 'Order(items: $items, subtotal: $subtotal, tax: $tax, total: $total, invoiceNumber: $invoiceNumber, date: $date, paymentMethod: $paymentMethod)';
  }
}

/// Represents an individual item in an order.
///
/// The [Item] class contains the name, quantity, price, and category for
/// each item in an order.
class Item {
  /// The name of the item.
  String name;

  /// The quantity of the item in the order.
  int quantity;

  /// The price per unit of the item.
  double price;

  /// The category to which the item belongs.
  String category;

  /// Creates a new [Item] object with the given [name], [quantity], [price], and [category].
  Item({
    required this.name,
    required this.quantity,
    required this.price,
    required this.category,
  });

  /// Converts a JSON object into an [Item] object.
  ///
  /// Expects the following JSON format:
  /// ```json
  /// {
  ///   "name": "Pizza",
  ///   "quantity": 2,
  ///   "price": 10.5,
  ///   "category": "food"
  /// }
  /// ```
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      name: json['name'],
      quantity: json['quantity'].toInt(),
      price: (json['price'].runtimeType != String)
          ? json['price'].toDouble()
          : 0, // Ensures correct parsing for non-string price fields
      category: json['category'].toString().toLowerCase(),
    );
  }

  /// Converts this [Item] object into a JSON object.
  ///
  /// The resulting JSON will follow the same format as required by [Item.fromJson].
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'category': category.toLowerCase(),
    };
  }

  /// Returns a copy of this [Item] object with the given fields replaced by new values.
  ///
  /// This can be useful when you want to create a modified version of an existing
  /// item without changing the original object.
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
