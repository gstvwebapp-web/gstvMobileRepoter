import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';

class NetworkService extends GetxController {
  static NetworkService get instance => Get.find<NetworkService>();
  
  // Observables
  final RxBool isConnected = true.obs;
  final RxBool isDialogShowing = false.obs;
  final RxString connectionType = 'unknown'.obs;
  
  // Private variables
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final Connectivity _connectivity = Connectivity();
  Timer? _retryTimer;
  final List<VoidCallback> _pendingApiCalls = [];
  
  // Network status tracking
  DateTime? _lastDisconnectedTime;
  
  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeNetworkService();
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    _retryTimer?.cancel();
    super.onClose();
  }

  Future<void> _initializeNetworkService() async {
    // On web, connectivity_plus doesn't work properly, so assume connected
    if (kIsWeb) {
      print('🌐 Running on web - skipping connectivity checks');
      isConnected.value = true;
      connectionType.value = 'web';
      return;
    }
    
    // Check initial connectivity
    await _checkInitialConnectivity();
    
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (error) {
        print('🌐 Connectivity stream error: $error');
      },
    );
    
    print('🌐 NetworkService initialized');
  }

  Future<void> _checkInitialConnectivity() async {
    // Skip on web
    if (kIsWeb) return;
    
    try {
      final List<ConnectivityResult> connectivityResults = await _connectivity.checkConnectivity();
      await _onConnectivityChanged(connectivityResults);
    } catch (e) {
      print('🌐 Error checking initial connectivity: $e');
      _updateConnectionStatus(false, 'none');
    }
  }

  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    print('🌐 Connectivity changed: $results');
    
    final bool hasConnection = !results.contains(ConnectivityResult.none);
    final String connectionTypeStr = results.isNotEmpty ? results.first.name : 'none';
    
    // Verify actual internet connectivity
    if (hasConnection) {
      final bool actuallyConnected = await _verifyInternetConnection();
      _updateConnectionStatus(actuallyConnected, connectionTypeStr);
    } else {
      _updateConnectionStatus(false, connectionTypeStr);
    }
  }

  Future<bool> _verifyInternetConnection() async {
    if (kIsWeb) return true;
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      print('🌐 Internet verification failed: $e');
      return false;
    }
  }

  void _updateConnectionStatus(bool connected, String type) {
    final bool wasConnected = isConnected.value;
    
    isConnected.value = connected;
    connectionType.value = type;
    
    print('🌐 Connection status: $connected ($type)');
    
    if (!wasConnected && connected) {
      // Connection restored
      _onConnectionRestored();
    } else if (wasConnected && !connected) {
      // Connection lost
      _onConnectionLost();
    }
  }

  void _onConnectionLost() {
    print('🌐 Connection lost - showing network alert');
    _lastDisconnectedTime = DateTime.now();
    _showNetworkAlert();
  }

  void _onConnectionRestored() {
    print('🌐 Connection restored - refreshing data');
    _hideNetworkAlert();
    _refreshAllData();
  }

  void _showNetworkAlert() {
    if (isDialogShowing.value) return;

    isDialogShowing.value = true;

    Get.dialog(
      PopScope(
        canPop: false, // Prevent dismissing
        child: Dialog(
          alignment: Alignment.topCenter,
          insetPadding: const EdgeInsets.only(
            top: 100, // Position from top to avoid overlap
            left: 20,
            right: 20,
            bottom: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon and title
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.wifi_off,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('No Internet Connection'.tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Content
                Text('Please check your internet connection and try again.'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF374151),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Info section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('The app will automatically refresh when connection is restored.'.tr,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _retryConnection,
                    icon: const Icon(Icons.refresh, size: 20),
                    label: Text('Retry Connection'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      name: 'NetworkAlert',
    );
  }

  void _hideNetworkAlert() {
    if (!isDialogShowing.value) return;

    isDialogShowing.value = false;

    if (Get.isDialogOpen == true) {
      if (Get.overlayContext != null) {
        Navigator.pop(Get.overlayContext!);
      } else {
        Get.overlayContext != null ? Navigator.pop(Get.overlayContext!) : Get.back();
      }
    }

    // Show success message with better positioning
    Get.snackbar('Connection Restored'.tr, 'Internet connection is back. Refreshing data...'.tr,
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.wifi, color: Colors.white, size: 20),
      ),
      backgroundColor: Colors.green.shade600,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.only(top: 60, left: 20, right: 20),
      borderRadius: 12,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      titleText: Text('Connection Restored'.tr,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      messageText: Text('Internet connection is back. Refreshing data...'.tr,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }

  Future<void> _retryConnection() async {
    print('🌐 Retrying connection...');
    await _checkInitialConnectivity();
  }

  void _refreshAllData() {
    print('🌐 Refreshing all data after connection restored');
    
    // Execute all pending API calls
    for (final callback in _pendingApiCalls) {
      try {
        callback();
      } catch (e) {
        print('🌐 Error executing pending API call: $e');
      }
    }
    _pendingApiCalls.clear();
    
    // Refresh current screen data
    _refreshCurrentScreenData();
  }

  void _refreshCurrentScreenData() {
    // Get current route and refresh appropriate controller
    final String currentRoute = Get.currentRoute;
    print('🌐 Refreshing data for route: $currentRoute');
    
    try {
      // Refresh dashboard if on dashboard
      if (currentRoute.contains('/dashboard')) {
        _refreshDashboard();
      }
      
      // Refresh create news if on create news
      if (currentRoute.contains('/create-news')) {
        _refreshCreateNews();
      }
      
      // Add more screen-specific refreshes as needed
      
    } catch (e) {
      print('🌐 Error refreshing current screen data: $e');
    }
  }

  void _refreshDashboard() {
    try {
      // Try to find and refresh dashboard controller
      if (Get.isRegistered<dynamic>(tag: 'NewslistController')) {
        final controller = Get.find<dynamic>(tag: 'NewslistController');
        if (controller.hasMethod('refreshData')) {
          controller.refreshData();
        }
      }
    } catch (e) {
      print('🌐 Error refreshing dashboard: $e');
    }
  }

  void _refreshCreateNews() {
    try {
      // Try to find and refresh create news controller
      if (Get.isRegistered<dynamic>(tag: 'CreateNewsController')) {
        final controller = Get.find<dynamic>(tag: 'CreateNewsController');
        if (controller.hasMethod('refreshData')) {
          controller.refreshData();
        }
      }
    } catch (e) {
      print('🌐 Error refreshing create news: $e');
    }
  }

  // Public methods for controllers to use
  void addPendingApiCall(VoidCallback callback) {
    if (!isConnected.value) {
      _pendingApiCalls.add(callback);
      print('🌐 Added pending API call (total: ${_pendingApiCalls.length})');
    } else {
      callback();
    }
  }

  Future<bool> checkConnectivity() async {
    // On web, always return true
    if (kIsWeb) return true;
    
    await _checkInitialConnectivity();
    return isConnected.value;
  }

  // Helper method for API calls
  Future<T> executeWithConnectivityCheck<T>(
    Future<T> Function() apiCall, {
    VoidCallback? onNoConnection,
  }) async {
    if (!isConnected.value) {
      onNoConnection?.call();
      throw Exception('No internet connection');
    }
    
    try {
      return await apiCall();
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.connectionError) {
        // Connection error during API call - recheck connectivity
        await _checkInitialConnectivity();
      }
      rethrow;
    }
  }

  // Get connection info
  String getConnectionInfo() {
    if (!isConnected.value) {
      final duration = _lastDisconnectedTime != null 
          ? DateTime.now().difference(_lastDisconnectedTime!)
          : Duration.zero;
      return 'Offline for ${_formatDuration(duration)}';
    }
    return 'Connected via ${connectionType.value}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 1) {
      return '${duration.inSeconds}s';
    } else if (duration.inHours < 1) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
  }
}

// Extension to check if object has method
extension ObjectExtension on Object {
  bool hasMethod(String methodName) {
    try {
      final mirror = this;
      return mirror.toString().contains(methodName);
    } catch (e) {
      return false;
    }
  }
}
