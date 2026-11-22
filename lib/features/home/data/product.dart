class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.sellerName,
    required this.location,
    this.imageUrl,
    this.sellerPhone,
  });

  final int id;
  final String name;
  final String description;
  final int price;
  final String sellerName;
  final String location;
  final String? imageUrl;
  final String? sellerPhone;

  factory Product.fromJson(Map<String, dynamic> json) {
    final seller = json['seller'];
    final phoneRaw =
        (seller is Map<String, dynamic> ? seller['phone'] : null) ??
            json['seller_phone'];
    return Product(
      id: _asInt(json['id']),
      name: json['name'] as String? ?? json['title'] as String? ?? 'Barang',
      description: json['description'] as String? ?? '',
      price: _asInt(json['price']),
      sellerName: seller is Map<String, dynamic>
          ? seller['name'] as String? ?? 'Penjual'
          : json['seller_name'] as String? ?? 'Penjual',
      location: json['location'] as String? ?? json['city'] as String? ?? 'Lokasi tidak tersedia',
      imageUrl: json['image_url'] as String? ?? json['photo_url'] as String?,
      sellerPhone: phoneRaw?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'seller_name': sellerName,
        'location': location,
        'image_url': imageUrl,
        'seller_phone': sellerPhone,
      };

  static int _asInt(Object? value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
}