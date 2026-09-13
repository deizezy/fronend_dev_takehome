import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rescu/feature/home/widget/flash_sales_countdown.dart';
import 'package:rescu/service/cart_service.dart';

import '../../app_config.dart';
import '../../model/deal_model.dart';
import '../../routes/routes.dart';
import 'the_network_image.dart';

/// Deal card used in the home feed and search results.
class DealCard extends StatefulWidget {
  final DealModel deal;
  final String source;

  const DealCard({super.key, required this.deal, this.source = 'home'});

  @override
  State<DealCard> createState() => _DealCardState();
}

class _DealCardState extends State<DealCard> {
  late bool _isExpired;
  @override
  void initState() {
    super.initState();
    _checkExpired();
  }

  @override
  void didUpdateWidget(covariant DealCard oldWidget) {
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
    return Opacity(
      opacity: _isExpired ? 0.6 : 1.0,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        elevation: 0.5,
      child: InkWell(
        onTap: _isExpired
            ? null
            : () => Get.toNamed(
                  Routes.dealRoute(widget.deal.id, source: widget.source),
                  arguments: widget.deal,
                ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                TheNetworkImage(
                    url: widget.deal.imageUrl,
                    height: 160,
                    width: double.infinity),
                if (widget.deal.isFlashSale)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isExpired
                            ? Colors.grey.shade700
                            : Colors.red.shade600,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isExpired ? Icons.timer_off_outlined : Icons.bolt,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          FlashCountdownBadge(
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            endsAt: widget.deal.flashSaleEndsAt!,
                            onExpired: () {
                              if (mounted) {
                                setState(() => _isExpired = true);
                              }
                              Get.find<CartService>()
                                  .removeIfExpired(widget.deal.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${widget.deal.quantityLeft} left',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.deal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(widget.deal.storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12.5, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule,
                          size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text('Pick up ${widget.deal.pickupWindow.label}',
                          style: TextStyle(
                              fontSize: 12.5, color: Colors.grey.shade700)),
                      const Spacer(),
                      if (widget.deal.rating != null) ...[
                        const Icon(Icons.star_rounded,
                            size: 15, color: Colors.amber),
                        Text(widget.deal.rating!.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12.5)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('฿${widget.deal.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppConfig.primaryGreen)),
                      const SizedBox(width: 6),
                      Text('฿${widget.deal.originalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppConfig.primaryGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('-${widget.deal.discountPercent}%',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppConfig.primaryGreen)),
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
  );
}
}
