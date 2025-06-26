import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:couphago_frontend/models/hotdeal.dart';
import 'package:couphago_frontend/screens/hotdeal_detail_screen.dart';

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
                _buildProductInfo(),
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
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: AspectRatio(
        aspectRatio: 1,
        child: CachedNetworkImage(
          imageUrl: hotdeal.thumbnail,
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
          Text(
            hotdeal.productName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            '현재가 ${hotdeal.salePrice.toStringAsFixed(0)}원',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          if (hotdeal.cardDiscountRate > 0) ...[
            const SizedBox(height: 4),
            Text(
              '최대 ${hotdeal.cardDiscountRate}% 카드할인',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blue,
              ),
            ),
          ],
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