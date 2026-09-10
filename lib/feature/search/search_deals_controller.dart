import 'dart:async';

import 'package:get/get.dart';

import '../../model/deal_model.dart';
import '../../repository/deal_repo.dart';
import '../../util/log_service.dart';

class SearchDealsController extends GetxController {
  final DealRepo dealRepo;

  SearchDealsController({required this.dealRepo});

  final results = <DealModel>[].obs;
  final isLoading = false.obs;
  final hasSearched = false.obs;

  Timer? _debounceTimer;
  int _searchToken = 0;

  static const Duration debounceDuration = Duration(milliseconds: 350);

  void onQueryChanged(String query) {
    _debounceTimer?.cancel();

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _searchToken++;
      results.clear();
      hasSearched.value = false;
      isLoading.value = false;
      return;
    }

    _debounceTimer = Timer(debounceDuration, () {
      _search(trimmed);
    });
  }

  Future<void> _search(String query) async {
    final currentToken = ++_searchToken;
    isLoading.value = true;
    hasSearched.value = true;

    try {
      final found = await dealRepo.search(query);
      // Discard stale responses if a newer query was initiated
      if (currentToken != _searchToken) {
        LogService.log('search: discarded stale result for "$query"');
        return;
      }
      results.assignAll(found);
    } catch (e) {
      if (currentToken == _searchToken) {
        LogService.error('search failed', e);
      }
    } finally {
      if (currentToken == _searchToken) {
        isLoading.value = false;
      }
    }
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }
}

