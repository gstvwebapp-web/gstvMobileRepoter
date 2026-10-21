import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';

const _propertyId = '317253838';
const _scopes = ['https://www.googleapis.com/auth/analytics.readonly'];
const _baseUrl =
    'https://analyticsdata.googleapis.com/v1beta/properties/$_propertyId';

class AnalyticsData {
  final int activeUsers30min;
  final int activeUsers5min;
  final List<MapEntry<String, int>> trafficSources;
  final List<MapEntry<String, int>> realtimeTopPages;
  final List<MapEntry<String, int>> todayTopPages;

  const AnalyticsData({
    required this.activeUsers30min,
    required this.activeUsers5min,
    required this.trafficSources,
    required this.realtimeTopPages,
    required this.todayTopPages,
  });
}

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  AutoRefreshingAuthClient? _client;

  Future<AutoRefreshingAuthClient> _getClient() async {
    if (_client != null) return _client!;
    final jsonStr =
        await rootBundle.loadString('assets/google-analytics.json');
    final credentials =
        ServiceAccountCredentials.fromJson(json.decode(jsonStr));
    _client = await clientViaServiceAccount(credentials, _scopes);
    return _client!;
  }

  Future<AnalyticsData> fetchAll() async {
    final client = await _getClient();

    final results = await Future.wait([
      _realtimeUsers(client, 29),  // 30 min window
      _realtimeUsers(client, 4),   // 5 min window
      _trafficSources(client),
      _realtimeTopPages(client),
      _todayTopPages(client),
    ]);

    return AnalyticsData(
      activeUsers30min: results[0] as int,
      activeUsers5min: results[1] as int,
      trafficSources: results[2] as List<MapEntry<String, int>>,
      realtimeTopPages: results[3] as List<MapEntry<String, int>>,
      todayTopPages: results[4] as List<MapEntry<String, int>>,
    );
  }

  // ── Real-time active users ─────────────────────────────────────────────
  // minuteRanges: startMinutesAgo must be > endMinutesAgo
  // endMinutesAgo defaults to 0 when omitted — omit it to avoid 400
  Future<int> _realtimeUsers(
      AutoRefreshingAuthClient client, int startMinutesAgo) async {
    final body = {
      'metrics': [
        {'name': 'activeUsers'}
      ],
      'minuteRanges': [
        {'name': 'range', 'startMinutesAgo': startMinutesAgo}
      ],
    };
    final resp = await _post(client, ':runRealtimeReport', body);
    final rows = resp['rows'] as List? ?? [];
    if (rows.isEmpty) return 0;
    return int.tryParse(
            (rows[0]['metricValues'] as List?)?.firstOrNull?['value'] ?? '0') ??
        0;
  }

  // ── Traffic sources (today) ────────────────────────────────────────────
  Future<List<MapEntry<String, int>>> _trafficSources(
      AutoRefreshingAuthClient client) async {
    final body = {
      'dateRanges': [
        {'startDate': '1daysAgo', 'endDate': 'today'}
      ],
      'dimensions': [
        {'name': 'firstUserSource'}
        // {'name': 'sessionSource'}

      ],
      'metrics': [
        // {'name': 'screenPageViews'}
        {'name': 'activeUsers'}
      ],
      // 'orderBys': [
      //   {
      //     'metric': {'metricName': 'screenPageViews'},
      //     'desc': true
      //   }
      // ],
      'limit': 10,
    };
    final resp = await _post(client, ':runReport', body);
    return _parseRows(resp);
  }

  // ── Real-time top pages (last 30 min) ──────────────────────────────────
  Future<List<MapEntry<String, int>>> _realtimeTopPages(
      AutoRefreshingAuthClient client) async {
    final body = {
      'dimensions': [
        {'name': 'unifiedScreenName'}
      ],
      'metrics': [
        {'name': 'screenPageViews'}
      ],
      'minuteRanges': [
        {'name': 'last30min', 'startMinutesAgo': 29}
      ],
      'orderBys': [
        {
          'metric': {'metricName': 'screenPageViews'},
          'desc': true
        }
      ],
      'limit': 10,
    };
    final resp = await _post(client, ':runRealtimeReport', body);
    return _parseRows(resp);
  }

  // ── Today top pages ────────────────────────────────────────────────────
  Future<List<MapEntry<String, int>>> _todayTopPages(
      AutoRefreshingAuthClient client) async {
    final body = {
      'dateRanges': [
        {'startDate': 'today', 'endDate': 'today'}
      ],
      'dimensions': [
        {'name': 'pageTitle'}
      ],
      'metrics': [
        {'name': 'screenPageViews'}
      ],
      'orderBys': [
        {
          'metric': {'metricName': 'screenPageViews'},
          'desc': true
        }
      ],
      'limit': 10,
    };
    final resp = await _post(client, ':runReport', body);
    return _parseRows(resp);
  }

  // ── Helpers ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _post(
      AutoRefreshingAuthClient client, String endpoint, Map body) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    if (response.statusCode != 200) {
      // Include full body in error so we can see the exact GA4 error message
      throw Exception('GA4 $endpoint ${response.statusCode}: ${response.body}');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  List<MapEntry<String, int>> _parseRows(Map<String, dynamic> resp) {
    final rows = resp['rows'] as List? ?? [];
    return rows.map<MapEntry<String, int>>((row) {
      final dim =
          (row['dimensionValues'] as List?)?.firstOrNull?['value'] ?? '';
      final val = int.tryParse(
              (row['metricValues'] as List?)?.firstOrNull?['value'] ?? '0') ??
          0;
      return MapEntry(dim, val);
    }).toList();
  }
}
