class PriceChartPoint {
  final String date;
  final int price;

  PriceChartPoint({
    required this.date,
    required this.price,
  });

  factory PriceChartPoint.fromJson(Map<String, dynamic> json) {
    return PriceChartPoint(
      date: json['date'] ?? '',
      price: json['price'] ?? 0,
    );
  }
} 