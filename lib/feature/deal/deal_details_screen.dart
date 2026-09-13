import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rescu/feature/home/widget/flash_sales_countdown.dart';
import 'package:rescu/service/cart_service.dart';

import '../../app_config.dart';
import '../shared_widget/the_network_image.dart';
import 'deal_details_controller.dart';

class DealDetailsScreen extends GetView<DealDetailsController> {
  const DealDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value || controller.deal.value == null) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      final deal = controller.deal.value!;
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background:
                    TheNetworkImage(url: deal.imageUrl, fit: BoxFit.cover),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deal.name,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(deal.storeName,
                        style: TextStyle(
                            fontSize: 15, color: Colors.grey.shade700)),
                    Text(deal.storeAddress,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text('฿${deal.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppConfig.primaryGreen)),
                        const SizedBox(width: 8),
                        Text('฿${deal.originalPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                                decoration: TextDecoration.lineThrough)),
                        const Spacer(),
                        Obx(() => Chip(
                              avatar: const Icon(Icons.inventory_2_outlined,
                                  size: 16),
                              label: Text(
                                  '${controller.quantityLeft ?? '-'} left'),
                            )),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (deal.isFlashSale) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt, color: Colors.red, size: 18),
                            const SizedBox(width: 6),
                            const Text(
                              'Flash Sale ends in: ',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                            FlashCountdownBadge(
                              endsAt: deal.flashSaleEndsAt!,
                              style: TextStyle(
                                  color: Colors.red.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                              onExpired: () {
                                controller.isExpired.value = true;
                                Get.find<CartService>()
                                    .removeIfExpired(deal.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text('What you get',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(deal.description,
                        style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.grey.shade800)),
                    if (deal.tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: deal.tags
                            .map((t) => Chip(
                                  label: Text(t),
                                  visualDensity: VisualDensity.compact,
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomSheet: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          color: Colors.white,
          child: SizedBox(
            width: double.infinity,
            child: Obx(() {
              final expired = controller.isExpired.value;
              return FilledButton.icon(
                onPressed: expired ? null : controller.addToCart,
                icon: Icon(expired
                    ? Icons.timer_off_outlined
                    : Icons.add_shopping_cart),
                label: Text(expired ? 'Flash sale expired' : 'Add to bag'),
                style: expired
                    ? FilledButton.styleFrom(
                        backgroundColor: Colors.grey.shade400)
                    : null,
              );
            }),
          ),
        ),
      );
    });
  }
}
