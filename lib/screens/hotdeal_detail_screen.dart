import 'package:flutter/material.dart';
import 'package:dealit_app/models/hotdeal.dart';
import 'package:dealit_app/services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dealit_app/models/price_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';

class HotdealDetailScreen extends StatefulWidget {
  final int hotdealId;
  const HotdealDetailScreen({super.key, required this.hotdealId});

  @override
  State<HotdealDetailScreen> createState() => _HotdealDetailScreenState();
}

class _HotdealDetailScreenState extends State<HotdealDetailScreen> {
  Hotdeal? hotdeal;
  List<PriceChartPoint> priceChart = [];
  bool loading = true;
  bool error = false;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      loading = true;
      error = false;
    });
    try {
      final result = await ApiService.fetchHotdeal(widget.hotdealId);
      setState(() {
        hotdeal = result['hotdeal'];
        priceChart = result['priceChart'];
        loading = false;
      });
    } catch (e) {
      print('Error fetching hotdeal detail: $e');
      setState(() {
        error = true;
        loading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (error || hotdeal == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('상세 정보를 불러올 수 없습니다.'),
              const SizedBox(height: 16),
              Text('핫딜 ID: ${widget.hotdealId}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchDetail,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('상품 상세'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (hotdeal!.thumbnail.isNotEmpty)
                Container(
                  width: double.infinity,
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: hotdeal!.thumbnail.startsWith('http') 
                          ? hotdeal!.thumbnail 
                          : 'https://cdn.dealit.shop${hotdeal!.thumbnail}',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                ),
              _buildProductSection(),
              const SizedBox(height: 32),
              if (priceChart.isNotEmpty) _buildPriceChart(),
            ],
          ),
          if (!hotdeal!.isActive) _buildExpiredOverlay(),
        ],
      ),
    );
  }

  Widget _buildProductSection() {
    return InkWell(
      onTap: () => _launchUrl(hotdeal!.productUrl),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotdeal!.productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '현재가 ${hotdeal!.salePrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} 원',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (hotdeal!.cardDiscountRate != null && hotdeal!.cardDiscountRate! > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '최대 ${hotdeal!.cardDiscountRate}% 카드할인',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    '· 쿠팡에서 실제 가격을 확인 후 구매해 주세요.',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  const Text(
                    '· 이 게시글은 쿠팡 파트너스 활동의 일환으로, 이에 따른 일정액의 수수료를 제공받습니다.',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  const Text(
                    '· 발생한 수익은 가격 추적 서비스 운영을 위해 사용됩니다.',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 300,
          child: _buildLineChart(),
        ),
      ],
    );
  }

  Widget _buildLineChart() {
    if (priceChart.length < 2) {
      return const Center(child: Text('차트를 표시할 수 있는 데이터가 부족합니다.'));
    }
    
    // fl_chart용 데이터 변환
    final chartData = priceChart.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.price.toDouble());
    }).toList();
    
    // 최소/최대 가격 계산
    final prices = priceChart.map((point) => point.price).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: (maxPrice - minPrice) / 4,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              interval: (maxPrice - minPrice) / 4,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: chartData,
            isCurved: false,
            color: const Color(0xFF4F46E5), // indigo.6
            barWidth: 2,
            dotData: FlDotData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(enabled: false),
      ),
    );
  }

  Widget _buildExpiredOverlay() {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: const Center(
          child: Text(
            '핫딜마감',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}