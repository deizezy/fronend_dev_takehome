import 'package:flutter_test/flutter_test.dart';
import 'package:rescu/feature/search/search_deals_controller.dart';
import 'package:rescu/model/deal_model.dart';
import 'package:rescu/model/paged_response_model.dart';
import 'package:rescu/repository/deal_repo.dart';
import 'package:rescu/service/fake_api_service.dart';

class MockDealRepo extends DealRepo {
  MockDealRepo() : super(api: FakeApiService());

  Future<List<DealModel>> Function(String query)? onSearch;

  @override
  Future<List<DealModel>> search(String query) async {
    if (onSearch != null) {
      return onSearch!(query);
    }
    return [];
  }

  @override
  Future<PagedResponseModel<DealModel>> fetchDeals({int page = 1}) async =>
      PagedResponseModel(items: [], page: 1, totalPages: 1);

  @override
  Future<List<DealModel>> fetchFlashDeals() async => [];

  @override
  Future<DealModel> fetchById(int id) async => throw UnimplementedError();
}

DealModel createFakeDeal(int id, String name) {
  return DealModel.fromJson({
    'id': id,
    'name': name,
    'description': '',
    'imageUrl': '',
    'originalPrice': 100,
    'price': 50,
    'currencyCode': 'THB',
    'quantityLeft': 1,
    'storeId': 1,
    'storeName': 'Test Store',
    'storeAddress': 'Test Address',
    'lat': 0.0,
    'lng': 0.0,
    'rating': null,
    'tags': [],
    'pickupWindow': {
      'start': '2026-01-01T10:00:00.000Z',
      'end': '2026-01-01T12:00:00.000Z',
    },
    'flashSaleEndsAt': null,
  });
}

void main() {
  test('SearchDealsController debounces rapid input', () async {
    final repo = MockDealRepo();
    int searchCalls = 0;
    repo.onSearch = (q) async {
      searchCalls++;
      return [createFakeDeal(1, q)];
    };

    final controller = SearchDealsController(dealRepo: repo);

    // Rapid typing
    controller.onQueryChanged('s');
    controller.onQueryChanged('su');
    controller.onQueryChanged('sus');
    controller.onQueryChanged('sushi');

    // Before debounce duration expires, no search should have fired
    await Future.delayed(const Duration(milliseconds: 100));
    expect(searchCalls, 0);

    // After debounce duration expires
    await Future.delayed(const Duration(milliseconds: 400));
    expect(searchCalls, 1);
    expect(controller.results.first.name, 'sushi');

    controller.onClose();
  });

  test('SearchDealsController discards stale out-of-order responses (race condition)', () async {
    final repo = MockDealRepo();

    // Simulate "su" taking 300ms and "sushi" taking 50ms
    repo.onSearch = (q) async {
      if (q == 'su') {
        await Future.delayed(const Duration(milliseconds: 300));
        return [createFakeDeal(1, 'su result')];
      } else if (q == 'sushi') {
        await Future.delayed(const Duration(milliseconds: 50));
        return [createFakeDeal(2, 'sushi result')];
      }
      return [];
    };

    final controller = SearchDealsController(dealRepo: repo);

    // Type "su" and let debounce trigger it
    controller.onQueryChanged('su');
    await Future.delayed(const Duration(milliseconds: 400)); // triggers search for 'su'

    // Now type 'sushi' and let debounce trigger it
    controller.onQueryChanged('sushi');
    await Future.delayed(const Duration(milliseconds: 400)); // triggers search for 'sushi'

    // At this point: 'sushi' completes in 50ms. 'su' completes later.
    await Future.delayed(const Duration(milliseconds: 200));

    // Results must be 'sushi result', NOT overwritten by 'su result'
    expect(controller.results.length, 1);
    expect(controller.results.first.name, 'sushi result');

    controller.onClose();
  });
}
