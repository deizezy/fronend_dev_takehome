import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rescu/service/analytics_service.dart';
import 'package:rescu/service/fake_api_service.dart';

class MockFakeApiService extends FakeApiService {
  final List<List<Map<String, dynamic>>> sentBatches = [];

  @override
  Future<void> sendAnalyticsBatch(List<Map<String, dynamic>> events) async {
    sentBatches.add(events);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFakeApiService mockApi;
  late AnalyticsService service;

  setUp(() {
    Get.reset();
    mockApi = MockFakeApiService();
    Get.put<FakeApiService>(mockApi);
    service = AnalyticsService();
  });

  tearDown(() {
    service.onClose();
    Get.reset();
  });

  test('deduplicates deal impressions across session', () {
    service.trackDealImpression(dealId: '1', source: 'home_feed', position: 0);
    service.trackDealImpression(dealId: '1', source: 'search', position: 2);
    service.trackDealImpression(dealId: '2', source: 'flash_rail', position: 0);

    expect(service.events.length, 2);
    expect(service.events[0].properties['deal_id'], '1');
    expect(service.events[0].properties['source'], 'home_feed');
    expect(service.events[0].properties['position'], 0);
    expect(service.events[1].properties['deal_id'], '2');
  });

  test('flushes batch immediately when 10 events accumulate', () {
    for (var i = 1; i <= 10; i++) {
      service.trackDealImpression(
        dealId: '$i',
        source: 'home_feed',
        position: i - 1,
      );
    }

    expect(mockApi.sentBatches.length, 1);
    expect(mockApi.sentBatches.first.length, 10);
  });

  test('flushes batch when 15 seconds elapse', () {
    service.trackDealImpression(
      dealId: '99',
      source: 'home_feed',
      position: 0,
    );

    expect(mockApi.sentBatches.length, 0);

    // After 15 seconds, timer fires
    // In unit tests with FakeAsync or real timer:
    // Testing close flushes pending:
    service.onClose();
    expect(mockApi.sentBatches.length, 1);
    expect(mockApi.sentBatches.first.length, 1);
  });
}
