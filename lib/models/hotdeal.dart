class Hotdeal {
  final int id;
  final int basePrice;
  final int salePrice;
  final int? cardDiscountRate;
  final String thumbnail;
  final String productName;
  final String itemId;
  final String externalProductId;
  final String vendorItemId;
  final bool outOfStock;
  final bool isActive;
  final String productUrl;
  final int categoryId;
  final bool isSuperHotdeal;

  Hotdeal({
    required this.id,
    required this.basePrice,
    required this.salePrice,
    this.cardDiscountRate,
    required this.thumbnail,
    required this.productName,
    required this.itemId,
    required this.externalProductId,
    required this.vendorItemId,
    required this.outOfStock,
    required this.isActive,
    required this.productUrl,
    required this.categoryId,
    required this.isSuperHotdeal,
  });

  factory Hotdeal.fromJson(Map<String, dynamic> json) {
    return Hotdeal(
      id: json['id'] ?? 0,
      basePrice: json['basePrice'] ?? 0,
      salePrice: json['salePrice'] ?? 0,
      cardDiscountRate: json['cardDiscountRate'],
      thumbnail: json['thumbnail'] ?? '',
      productName: json['productName'] ?? '',
      itemId: json['itemId'] ?? '',
      externalProductId: json['externalProductId'] ?? '',
      vendorItemId: json['vendorItemId'] ?? '',
      outOfStock: json['outOfStock'] ?? false,
      isActive: json['isActive'] ?? false,
      productUrl: json['productUrl'] ?? '',
      categoryId: json['categoryId'] ?? 0,
      isSuperHotdeal: json['isSuperHotdeal'] ?? false,
    );
  }
}