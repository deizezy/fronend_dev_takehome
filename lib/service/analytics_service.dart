import 'dart:async';

import 'package:get/get.dart';
import 'package:rescu/service/fake_api_service.dart';

import '../util/log_service.dart';

class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> properties;
  final DateTime at;

  AnalyticsEvent(this.name, this.properties) : at = DateTime.now();

  Map<String, dynamic> toJson() => {
        'name': name,
        'properties': properties,
        'at': at.toIso8601String(),
      };
}

/// In-memory analytics sink. Events are visible on the debug screen
/// (overflow menu on Home -> "Analytics debug") and in the console.
///
/// The "Impression tracking" feature task builds on top of this service.
class AnalyticsService extends GetxService {
  final events = <AnalyticsEvent>[].obs;

  final Set<String> _impressedDealIds = {};

  final List<Map<String, dynamic>> _pendingBatch = [];
  Timer? _flushTimer;

  bool hasImpressed(String dealId) => _impressedDealIds.contains(dealId);

  void logEvent(String name, [Map<String, dynamic> properties = const {}]) {
    final event = AnalyticsEvent(name, properties);
    events.add(event);
    LogService.log('analytics: $name $properties');
  }

  void trackDealImpression({
    required String dealId,
    required String source,
    required int position,
  }) {
    if (_impressedDealIds.contains(dealId)) return;
    _impressedDealIds.add(dealId);

    logEvent('deal_impression', {
      'deal_id': dealId,
      'source': source,
      'position': position,
    });

    _pendingBatch.add(events.last.toJson());

    if (_pendingBatch.length >= 10) {
      _flushBatch();
    } else if (_pendingBatch.length == 1) {
      _flushTimer = Timer(const Duration(seconds: 15), _flushBatch);
    }
  }

  void _flushBatch() {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_pendingBatch.isEmpty) return;

    final batchToSend = List<Map<String, dynamic>>.from(_pendingBatch);
    _pendingBatch.clear();

    if (Get.isRegistered<FakeApiService>()) {
      Get.find<FakeApiService>().sendAnalyticsBatch(batchToSend);
    }
  }

  @override
  void onClose() {
    _flushBatch();
    super.onClose();
  }
}
