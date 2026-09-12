import 'package:get/get.dart';

import '../../model/deal_model.dart';
import '../../repository/deal_repo.dart';
import '../../service/analytics_service.dart';
import '../../service/cart_service.dart';
import '../../util/log_service.dart';

class DealDetailsController extends GetxController {
  final DealRepo dealRepo;
  final CartService cartService;
  final AnalyticsService analytics;

  DealDetailsController({
    required this.dealRepo,
    required this.cartService,
    required this.analytics,
  });

  final deal = Rxn<DealModel>();
  final isLoading = false.obs;

  final _quantityLeft = RxnInt();
  int? get quantityLeft => _quantityLeft.value;

  Worker? _cartWorker;

  @override
  void onInit() {
    super.onInit();

    // 1. ตรวจสอบว่ามีข้อมูลส่งมาจากหน้าก่อนหน้าหรือไม่
    if (Get.arguments is DealModel) {
      _setupDeal(Get.arguments as DealModel);
    } else {
      // 2. ถ้าไม่มี (มาจาก Deep Link) ให้อ่าน id จาก URL parameter
      final idStr = Get.parameters['id'];
      final id = int.tryParse(idStr ?? '');
      if (id != null) {
        _loadDealById(id);
      }
    }
  }

  @override
  void onClose() {
    _cartWorker?.dispose();
    super.onClose();
  }

  void _setupDeal(DealModel loadedDeal) {
    deal.value = loadedDeal;
    _quantityLeft.value = loadedDeal.quantityLeft;
    analytics.logEvent('deal_details_view', {
      'deal_id': loadedDeal.id,
      'source': Get.parameters['source'] ?? 'unknown',
    });
    _cartWorker?.dispose();
    _cartWorker = ever(cartService.itemCount, (_) => _recheckAvailability());
  }

  Future<void> _loadDealById(int id) async {
    isLoading.value = true;
    try {
      final fetched = await dealRepo.fetchById(id);
      _setupDeal(fetched);
    } catch (e) {
      LogService.error('failed to load deal from deep link', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _recheckAvailability() async {
    final currentDeal = deal.value;
    if (currentDeal == null) return;
    LogService.log('re-checking availability for deal ${currentDeal.id}');
    final fresh = await dealRepo.fetchById(currentDeal.id);
    _quantityLeft.value = fresh.quantityLeft;
  }

  void addToCart() {
    final currentDeal = deal.value;
    if (currentDeal == null) return;
    cartService.add(currentDeal);
    Get.snackbar(
      'Added to bag',
      '${currentDeal.name} — pick up ${currentDeal.pickupWindow.label}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}
