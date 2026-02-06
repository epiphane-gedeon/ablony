class ProductDetails {
  final String title;
  final double price;
  final String? image;
  final String? sellerId;

  const ProductDetails({
    required this.title,
    required this.price,
    this.image,
    this.sellerId,
  });

  factory ProductDetails.fromFirestore(Map<String, dynamic> data) {
    return ProductDetails(
      title: data['title'] as String,
      price: (data['price'] as num).toDouble(),
      image: data['image'] as String?,
      sellerId: data['sellerId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'price': price,
      if (image != null) 'image': image,
      if (sellerId != null) 'sellerId': sellerId,
    };
  }
}
