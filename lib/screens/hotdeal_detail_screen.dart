import 'package:flutter/material.dart';
import 'package:couphago_frontend/models/hotdeal.dart';
import 'package:couphago_frontend/services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HotdealDetailScreen extends StatefulWidget {
  final int hotdealId;
  const HotdealDetailScreen({super.key, required this.hotdealId});

  @override
  State<HotdealDetailScreen> createState() => _HotdealDetailScreenState();
}

class _HotdealDetailScreenState extends State<HotdealDetailScreen> {
  Hotdeal? hotdeal;
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
        hotdeal = result;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = true;
        loading = false;
      });
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
        body: const Center(child: Text('상세 정보를 불러올 수 없습니다.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(hotdeal!.productName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (hotdeal!.thumbnail.isNotEmpty)
            CachedNetworkImage(
              imageUrl: hotdeal!.thumbnail,
              height: 200,
              fit: BoxFit.cover,
            ),
          const SizedBox(height: 16),
          Text(
            hotdeal!.productName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('현재가: ${hotdeal!.salePrice}원', style: const TextStyle(fontSize: 18, color: Colors.red)),
          if (hotdeal!.cardDiscountRate > 0)
            Text('최대 ${hotdeal!.cardDiscountRate}% 카드할인', style: const TextStyle(color: Colors.blue)),
          const SizedBox(height: 16),
          Text('상품 ID: ${hotdeal!.itemId}'),
          Text('카테고리 ID: ${hotdeal!.categoryId}'),
          // 필요에 따라 더 많은 정보 추가
        ],
      ),
    );
  }
}