import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardController(), permanent: true);
    final fmt = NumberFormat('#,##0');

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: controller.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Real-time user banners ──────────────────────────────────
            Obx(() => Row(
              children: [
                _UserBanner(
                  label: 'Total User\n30 minutes'.tr,
                  value: controller.isLoadingAnalytics.value
                      ? '...'
                      : fmt.format(controller.activeUsers30min.value),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8603C), Color(0xFFE8603C)],
                  ),
                ),
                const SizedBox(width: 10),
                _UserBanner(
                  label: 'Total User\n5 minutes'.tr,
                  value: controller.isLoadingAnalytics.value
                      ? '...'
                      : fmt.format(controller.activeUsers5min.value),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                  ),
                ),
              ],
            )),

            const SizedBox(height: 16),

            // ── Analytics error ─────────────────────────────────────────
            Obx(() => controller.analyticsError.value.isNotEmpty
                ? _ErrorBanner(message: controller.analyticsError.value,
                    onRetry: controller.loadAnalytics)
                : const SizedBox.shrink()),

            // ── Traffic Sources ─────────────────────────────────────────
            Obx(() => _SectionCard(
              title: 'Traffic Sources'.tr,
              isLoading: controller.isLoadingAnalytics.value,
              child: _TableWidget(
                headers: const ['Source', 'Views'],
                rows: controller.trafficSources
                    .map((e) => [e.key, fmt.format(e.value)])
                    .toList(),
                flex: const [3, 1],
                alignRight: const [false, true],
              ),
            )),

            const SizedBox(height: 12),

            // ── Real-time top pages ─────────────────────────────────────
            Obx(() => _SectionCard(
              title: 'Real-Time Page Views (Last 30 Min · Top 10)'.tr,
              isLoading: controller.isLoadingAnalytics.value,
              child: _TableWidget(
                headers: const ['Page Title', 'Views'],
                rows: controller.realtimeTopPages
                    .map((e) => [e.key, fmt.format(e.value)])
                    .toList(),
                flex: const [4, 1],
                alignRight: const [false, true],
              ),
            )),

            const SizedBox(height: 12),

            // ── Today top pages ─────────────────────────────────────────
            Obx(() => _SectionCard(
              title: 'Real-Time Page Views (Today · Top 10)'.tr,
              isLoading: controller.isLoadingAnalytics.value,
              child: _TableWidget(
                headers: const ['Page Title', 'Views'],
                rows: controller.todayTopPages
                    .map((e) => [e.key, fmt.format(e.value)])
                    .toList(),
                flex: const [4, 1],
                alignRight: const [false, true],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ── User Banner ────────────────────────────────────────────────────────────

class _UserBanner extends StatelessWidget {
  final String label;
  final String value;
  final LinearGradient gradient;

  const _UserBanner({
    required this.label,
    required this.value,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Card ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final bool isLoading;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A202C),
              ),
            ),
          ),
          const Divider(height: 1),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            child,
        ],
      ),
    );
  }
}

// ── Table Widget ───────────────────────────────────────────────────────────

class _TableWidget extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final List<int> flex;
  final List<bool> alignRight;

  const _TableWidget({
    required this.headers,
    required this.rows,
    required this.flex,
    required this.alignRight,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text('No data available'.tr,
              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ),
      );
    }

    return Column(
      children: [
        // Header row
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: List.generate(headers.length, (i) {
              return Expanded(
                flex: flex[i],
                child: Text(
                  headers[i],
                  textAlign:
                      alignRight[i] ? TextAlign.right : TextAlign.left,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF718096),
                    letterSpacing: 0.3,
                  ),
                ),
              );
            }),
          ),
        ),
        const Divider(height: 1),
        // Data rows
        ...rows.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          return Container(
            color: i.isEven ? Colors.white : const Color(0xFFFAFAFA),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              children: List.generate(row.length, (j) {
                return Expanded(
                  flex: flex[j],
                  child: Text(
                    row[j],
                    textAlign:
                        alignRight[j] ? TextAlign.right : TextAlign.left,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: j == 0
                          ? const Color(0xFF2D3748)
                          : const Color(0xFF4A5568),
                      fontWeight: j == row.length - 1
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }
}

// ── Error Banner ───────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Analytics: $message',
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('Retry'.tr, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
