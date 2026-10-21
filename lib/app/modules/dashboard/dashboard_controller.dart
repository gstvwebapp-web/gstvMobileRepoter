import 'package:get/get.dart';
import '../../data/services/analytics_service.dart';

class DashboardController extends GetxController {
  final AnalyticsService _analytics = AnalyticsService();

  // GA real-time
  final RxInt activeUsers30min = 0.obs;
  final RxInt activeUsers5min = 0.obs;
  final RxList<MapEntry<String, int>> trafficSources =
      <MapEntry<String, int>>[].obs;
  final RxList<MapEntry<String, int>> realtimeTopPages =
      <MapEntry<String, int>>[].obs;
  final RxList<MapEntry<String, int>> todayTopPages =
      <MapEntry<String, int>>[].obs;

  final RxBool isLoadingAnalytics = true.obs;
  final RxString analyticsError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAnalytics();
  }

  Future<void> loadAnalytics() async {
    isLoadingAnalytics.value = true;
    analyticsError.value = '';
    try {
      final data = await _analytics.fetchAll();
      activeUsers30min.value = data.activeUsers30min;
      activeUsers5min.value = data.activeUsers5min;
      trafficSources.assignAll(data.trafficSources);
      realtimeTopPages.assignAll(data.realtimeTopPages);
      todayTopPages.assignAll(data.todayTopPages);
    } catch (e) {
      analyticsError.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoadingAnalytics.value = false;
    }
  }

  @override
  Future<void> refresh() => loadAnalytics();
}
