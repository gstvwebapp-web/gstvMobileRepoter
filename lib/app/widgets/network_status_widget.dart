import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/services/network_service.dart';

class NetworkStatusWidget extends StatelessWidget {
  final Widget child;
  final bool showStatusBar;
  
  const NetworkStatusWidget({
    super.key,
    required this.child,
    this.showStatusBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final networkService = Get.find<NetworkService>();
    return Column(
      children: [
        // Network status bar
        if (showStatusBar)
          Obx(() => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: networkService.isConnected.value ? 0 : 30,
            color: Colors.red.shade600,
            child: networkService.isConnected.value
                ? const SizedBox.shrink()
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.wifi_off,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text('No Internet Connection'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
          )),

        // Main content
        Expanded(child: child),
      ],
    );
  }
}

class NetworkStatusIndicator extends StatelessWidget {
  final bool showText;
  final double iconSize;
  
  const NetworkStatusIndicator({
    super.key,
    this.showText = true,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final networkService = Get.find<NetworkService>();
    return Obx(() {
      final bool isConnected = networkService.isConnected.value;
      final String connectionType = networkService.connectionType.value;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? _getConnectionIcon(connectionType) : Icons.wifi_off,
            color: isConnected ? Colors.green : Colors.red,
            size: iconSize,
          ),
          if (showText) ...[
            const SizedBox(width: 4),
            Text(
              isConnected ? _getConnectionText(connectionType) : 'Offline',
              style: TextStyle(
                color: isConnected ? Colors.green : Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      );
    });
  }

  IconData _getConnectionIcon(String connectionType) {
    switch (connectionType.toLowerCase()) {
      case 'wifi':
        return Icons.wifi;
      case 'mobile':
      case 'cellular':
        return Icons.signal_cellular_4_bar;
      case 'ethernet':
        return Icons.settings_ethernet;
      default:
        return Icons.signal_wifi_4_bar;
    }
  }

  String _getConnectionText(String connectionType) {
    switch (connectionType.toLowerCase()) {
      case 'wifi':
        return 'WiFi';
      case 'mobile':
      case 'cellular':
        return 'Mobile';
      case 'ethernet':
        return 'Ethernet';
      default:
        return 'Online';
    }
  }
}

class NetworkAwareWidget extends StatelessWidget {
  final Widget child;
  final Widget? offlineWidget;
  final VoidCallback? onRetry;
  
  const NetworkAwareWidget({
    super.key,
    required this.child,
    this.offlineWidget,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final networkService = Get.find<NetworkService>();
    return Obx(() {
      if (networkService.isConnected.value) {
        return child;
      } else {
        return offlineWidget ?? _buildDefaultOfflineWidget();
      }
    });
  }

  Widget _buildDefaultOfflineWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text('No Internet Connection'.tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text('Please check your connection and try again'.tr,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (onRetry != null)
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text('Retry'.tr),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Mixin for controllers to handle network-aware operations
mixin NetworkAwareMixin {
  NetworkService get _networkService => Get.find<NetworkService>();
  
  bool get isConnected => _networkService.isConnected.value;
  
  Future<T> executeWithNetworkCheck<T>(
    Future<T> Function() operation, {
    VoidCallback? onNoConnection,
  }) async {
    return await _networkService.executeWithConnectivityCheck<T>(
      operation,
      onNoConnection: onNoConnection,
    );
  }
  
  void addPendingOperation(VoidCallback operation) {
    _networkService.addPendingApiCall(operation);
  }
  
  void listenToNetworkChanges(VoidCallback onConnected, VoidCallback onDisconnected) {
    ever(_networkService.isConnected, (bool connected) {
      if (connected) {
        onConnected();
      } else {
        onDisconnected();
      }
    });
  }
}
