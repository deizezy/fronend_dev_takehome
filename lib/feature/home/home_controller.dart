import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../model/deal_model.dart';
import '../../repository/deal_repo.dart';
import '../../util/log_service.dart';

class HomeController extends GetxController {
  final DealRepo dealRepo;

  HomeController({required this.dealRepo});

  final deals = <DealModel>[].obs;
  final flashDeals = <DealModel>[].obs;
  final isLoading = true.obs;
  final todayOnly = false.obs;
  final scrollOffset = 0.0.obs;

  final scrollController = ScrollController();
  final refreshController = RefreshController();

  int _page = 1;
  int _totalPages = 1;
  bool _isFetchingMore = false;
  int _refreshCycle = 0;

  bool get hasMore => _page < _totalPages;

  List<DealModel> get visibleDeals => todayOnly.value
      ? deals.where((d) => d.pickupWindow.isToday).toList()
      : deals.toList();

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    _initialLoad();
  }

  void _onScroll() {
    scrollOffset.value = scrollController.offset;
  }

  Future<void> _initialLoad() async {
    isLoading.value = true;
    try {
      await Future.wait([refreshDeals(), _loadFlashDeals()]);
    } catch (e) {
      LogService.error('initial load failed', e);
    }
    isLoading.value = false;
  }

  Future<void> _loadFlashDeals() async {
    flashDeals.assignAll(await dealRepo.fetchFlashDeals());
  }

  Future<void> refreshDeals() async {
    final cycle = ++_refreshCycle;
    _isFetchingMore = false;
    _page = 1;
    try {
      final res = await dealRepo.fetchDeals(page: 1);

      if (cycle != _refreshCycle) return;
      _totalPages = res.totalPages;
      deals.assignAll(res.items);
      refreshController.refreshCompleted();
      refreshController.resetNoData();
    } catch (e) {
      LogService.error('refreshDeals failed', e);
      refreshController.refreshFailed();
    }
  }

  Future<void> loadMore() async {
    if (_isFetchingMore) return;
    if (!hasMore) {
      refreshController.loadNoData();
      return;
    }

    final cycle = _refreshCycle;
    _isFetchingMore = true;
    final nextPage = _page + 1;
    try {
      final res = await dealRepo.fetchDeals(page: nextPage);

      if (cycle != _refreshCycle) return;

      _page = nextPage;
      _totalPages = res.totalPages;

      final existingIds = deals.map((d) => d.id).toSet();
      final newItems = res.items.where((d) => !existingIds.contains(d.id));
      deals.addAll(newItems);

      refreshController.loadComplete();
    } catch (e) {
      LogService.error('loadMore failed', e);
      refreshController.loadFailed();
    } finally {
      if (cycle == _refreshCycle) {
        _isFetchingMore = false;
      }
    }
  }

  void scrollToTop() {
    scrollController.animateTo(0,
        duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
  }

  @override
  void onClose() {
    scrollController.dispose();
    refreshController.dispose();
    super.onClose();
  }
}
