import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dealit_app/models/hotdeal.dart';
import 'package:dealit_app/screens/hotdeal_detail_screen.dart';

class HotdealCard extends StatelessWidget {
  final Hotdeal hotdeal;

  const HotdealCard({super.key, required this.hotdeal});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HotdealDetailScreen(hotdealId: hotdeal.id),
            ),
          );
        },
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThumbnail(),
                Expanded(
                  child: _buildProductInfo(),
                ),
              ],
            ),
            if (hotdeal.isSuperHotdeal) _buildSuperHotdealBadge(),
            if (!hotdeal.isActive) _buildExpiredOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (hotdeal.thumbnail.isEmpty) return const SizedBox.shrink();
    
    final fullImageUrl = hotdeal.thumbnail.startsWith('http') 
        ? hotdeal.thumbnail 
        : 'https://cdn.dealit.shop${hotdeal.thumbnail}';
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: AspectRatio(
        aspectRatio: 1,
        child: CachedNetworkImage(
          imageUrl: fullImageUrl,
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
    );
  }

  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              hotdeal.productName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '현재가 ${hotdeal.salePrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 4),
          if (hotdeal.cardDiscountRate != null && hotdeal.cardDiscountRate! > 0)
            Text(
              '최대 ${hotdeal.cardDiscountRate}% 카드할인',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blue,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuperHotdealBadge() {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          '슈퍼핫딜',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildExpiredOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            '핫딜마감',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}