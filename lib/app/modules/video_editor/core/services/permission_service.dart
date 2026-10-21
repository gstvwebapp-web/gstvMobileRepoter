import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'logger_service.dart';

/// Result of a permission check/request, exposed as a simple enum so the
/// UI layer doesn't need to know about `permission_handler`'s
/// [PermissionStatus] directly.
enum AppPermissionState { granted, denied, permanentlyDenied, restricted }

/// The distinct permission "kinds" the app cares about. Each maps to a
/// different underlying [Permission] depending on platform *and*, on
/// Android, the OS version — see [_androidMediaPermissions].
enum AppPermissionKind { camera, microphone, gallery, storage }

/// Centralises every permission check the app performs.
///
/// Android's photo/video permission model changed across 13, 14 and 15:
/// - Android <= 12: broad `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE`.
/// - Android 13+: granular `READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO` /
///   `READ_MEDIA_AUDIO`.
/// - Android 14+: adds the "partial access" grant
///   (`READ_MEDIA_VISUAL_USER_SELECTED`), which `permission_handler`
///   surfaces as [PermissionStatus.limited].
/// - Android 15: no further permission model change relevant here, but we
///   keep the SDK-version branch structured so a future bump is a single
///   `if` addition.
///
/// This service resolves all of that into the four simple [AppPermissionKind]
/// values consumed by the permissions screen.
class PermissionService {
  PermissionService._internal();
  static final PermissionService instance = PermissionService._internal();

  int? _androidSdkInt;

  Future<int> _resolveAndroidSdkInt() async {
    if (_androidSdkInt != null) return _androidSdkInt!;
    final info = await DeviceInfoPlugin().androidInfo;
    _androidSdkInt = info.version.sdkInt;
    return _androidSdkInt!;
  }

  Future<List<Permission>> _permissionsFor(AppPermissionKind kind) async {
    if (Platform.isIOS) {
      switch (kind) {
        case AppPermissionKind.camera:
          return [Permission.camera];
        case AppPermissionKind.microphone:
          return [Permission.microphone];
        case AppPermissionKind.gallery:
        case AppPermissionKind.storage:
          return [Permission.photos];
      }
    }

    // Android
    final sdkInt = await _resolveAndroidSdkInt();
    switch (kind) {
      case AppPermissionKind.camera:
        return [Permission.camera];
      case AppPermissionKind.microphone:
        return [Permission.microphone];
      case AppPermissionKind.gallery:
        if (sdkInt >= 33) {
          // Android 13+ (includes 14, 15): granular media permissions.
          return [Permission.videos, Permission.photos];
        }
        return [Permission.storage];
      case AppPermissionKind.storage:
        if (sdkInt >= 33) {
          // Writing exported files goes through MediaStore / SAF on 13+;
          // no broad storage permission is needed or requestable.
          return [];
        }
        return [Permission.storage];
    }
  }

  Future<AppPermissionState> check(AppPermissionKind kind) async {
    final permissions = await _permissionsFor(kind);
    if (permissions.isEmpty) return AppPermissionState.granted;

    for (final permission in permissions) {
      final status = await permission.status;
      final mapped = _mapStatus(status);
      if (mapped != AppPermissionState.granted) return mapped;
    }
    return AppPermissionState.granted;
  }

  Future<AppPermissionState> request(AppPermissionKind kind) async {
    final permissions = await _permissionsFor(kind);
    if (permissions.isEmpty) return AppPermissionState.granted;

    final statuses = await permissions.request();
    LoggerService.instance.i('Permission request ($kind): $statuses');

    AppPermissionState worst = AppPermissionState.granted;
    for (final status in statuses.values) {
      final mapped = _mapStatus(status);
      if (mapped == AppPermissionState.permanentlyDenied) {
        return AppPermissionState.permanentlyDenied;
      }
      if (mapped != AppPermissionState.granted) worst = mapped;
    }
    return worst;
  }

  AppPermissionState _mapStatus(PermissionStatus status) {
    if (status.isGranted || status.isLimited) {
      return AppPermissionState.granted;
    }
    if (status.isPermanentlyDenied) {
      return AppPermissionState.permanentlyDenied;
    }
    if (status.isRestricted) {
      return AppPermissionState.restricted;
    }
    return AppPermissionState.denied;
  }

  Future<bool> openSystemSettings() => openAppSettings();
}
