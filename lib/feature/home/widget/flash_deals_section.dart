import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rescu/feature/home/widget/flash_sales_countdown.dart';
import 'package:rescu/service/cart_service.dart';

import '../../../app_config.dart';
import '../../../model/deal_model.dart';
import '../../../routes/routes.dart';
import '../../shared_widget/the_network_image.dart';

/// Horizontal flash-sale rail.
///
/// NOTE: the countdown is currently a static "Ends soon" label — turning it
/// into a live per-deal countdown is one of the feature tasks in PROBLEM.md.
class FlashDealsSection extends StatelessWidget {
  final List<DealModel> deals;

  const FlashDealsSection({super.key, required this.deals});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(Icons.bolt, color: Colors.red, size: 20),
              SizedBox(width: 4),
              Text('Flash sales',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: deals.length,
            itemBuilder: (context, index) {
              return _FlashRailCard(deal: deals[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _FlashRailCard extends StatefulWidget {
  final DealModel deal;
  const _FlashRailCard({required this.deal});

  @override
  State<_FlashRailCard> createState() => _FlashRailCardState();
}

class _FlashRailCardState extends State<_FlashRailCard> {
  late bool _isExpired;

  @override
  void initState() {
    super.initState();
    _checkExpired();
  }

  @override
  void didUpdateWidget(covariant _FlashRailCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deal.id != widget.deal.id ||
        oldWidget.deal.flashSaleEndsAt != widget.deal.flashSaleEndsAt) {
      _checkExpired();
    }
  }

  void _checkExpired() {
    _isExpired = widget.deal.isFlashSale &&
        widget.deal.flashSaleEndsAt != null &&
        DateTime.now().isAfter(widget.deal.flashSaleEndsAt!);
  }

  @override
  Widget build(BuildContext context) {
    final deal = widget.deal;
    return SizedBox(
      width: 200,
      child: Opacity(
        opacity: _isExpired ? 0.6 : 1.0,
        child: Card(
          color: Colors.white,
          elevation: 0.5,
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: InkWell(
            onTap: _isExpired
                ? null
                : () => Get.toNamed(
                      Routes.dealRoute(deal.id, source: 'flash_rail'),
                      arguments: deal,
                    ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TheNetworkImage(
                    url: deal.imageUrl, height: 90, width: double.infinity),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(deal.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(deal.storeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11.5, color: Colors.grey.shade600)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text('฿${deal.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppConfig.primaryGreen)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _isExpired
                                  ? Colors.grey.shade200
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FlashCountdownBadge(
                              style: TextStyle(
                                fontSize: 10,
                                color: _isExpired
                                    ? Colors.grey.shade700
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                              endsAt: deal.flashSaleEndsAt!,
                              onExpired: () {
                                if (mounted) {
                                  setState(() => _isExpired = true);
                                }
                                Get.find<CartService>()
                                    .removeIfExpired(deal.id);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
