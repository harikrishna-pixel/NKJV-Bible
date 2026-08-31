class ProductDetails {
  ProductDetails({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rawPrice,
    required this.currencyCode,
    this.currencySymbol = '',
  });

  final String id;
  final String title;
  final String description;
  final String price;
  final double rawPrice;
  final String currencyCode;
  final String currencySymbol;

  // Convert object to JSON map
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'price': price,
        'rawPrice': rawPrice,
        'currencyCode': currencyCode,
        'currencySymbol': currencySymbol,
      };

  // Create object from JSON map
  factory ProductDetails.fromJson(Map<String, dynamic> json) {
    return ProductDetails(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      price: json['price'],
      rawPrice: (json['rawPrice'] as num).toDouble(),
      currencyCode: json['currencyCode'],
      currencySymbol: json['currencySymbol'] ?? '',
    );
  }
}
