# GSTV Admin - Release Build Guide

This document provides comprehensive instructions for creating release builds of the GSTV Admin app.

## 📋 Prerequisites

- Flutter SDK installed and configured
- Android SDK with API level 34
- Xcode (for iOS builds)
- Proper signing certificates

## 🔧 Configuration

### Android Signing Configuration

#### For Development/Testing

The app is currently configured to use debug keystore for initial testing:

- Keystore: `android/app/debug.keystore`
- Alias: `androiddebugkey`
- Password: `android`

#### For Production

1. Generate a production keystore:

```bash
keytool -genkey -v -keystore gstv-admin-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias gstv-admin-key
```

2. Create `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=gstv-admin-key
storeFile=../keystores/gstv-admin-keystore.jks
```

3. Update `android/app/build.gradle.kts` to use the production keystore.

## 🚀 Building Release Versions

### Quick Build Scripts

#### Single Release Build

```bash
./build_release.sh
```

This builds both APK and App Bundle for production.

#### All Flavors Build

```bash
./build_flavors.sh
```

This builds all flavors (development, staging, production).

### Manual Build Commands

#### APK Build

```bash
# Development
flutter build apk --release --flavor development

# Staging
flutter build apk --release --flavor staging

# Production
flutter build apk --release --flavor production
```

#### App Bundle Build (for Play Store)

```bash
flutter build appbundle --release --flavor production
```

#### iOS Build

```bash
flutter build ios --release
```

## 📱 App Flavors

The app is configured with three flavors:

### Development (`com.gstv.gstv_admin.dev`)

- For internal development testing
- Debug features enabled
- Version suffix: `-dev`

### Staging (`com.gstv.gstv_admin.staging`)

- For QA and pre-production testing
- Points to staging API endpoints
- Version suffix: `-staging`

### Production (`com.gstv.gstv_admin`)

- For live production release
- Points to production API endpoints
- No version suffix

## 🔒 Permissions

The app requests the following permissions:

### Android

- `INTERNET` - API calls and networking
- `ACCESS_NETWORK_STATE` - Check connectivity status
- `ACCESS_WIFI_STATE` - WiFi status monitoring
- `READ_EXTERNAL_STORAGE` - File and media access
- `WRITE_EXTERNAL_STORAGE` - File operations (API ≤ 28)
- `READ_MEDIA_IMAGES` - Image access (API ≥ 33)
- `READ_MEDIA_VIDEO` - Video access (API ≥ 33)
- `READ_MEDIA_AUDIO` - Audio access (API ≥ 33)
- `CAMERA` - Camera access for photo capture
- `WAKE_LOCK` - Keep device awake during operations
- `MANAGE_EXTERNAL_STORAGE` - Full storage access (if needed)

### iOS

- `NSCameraUsageDescription` - Camera access
- `NSPhotoLibraryUsageDescription` - Photo library access
- `NSPhotoLibraryAddUsageDescription` - Save photos to library
- `NSMicrophoneUsageDescription` - Microphone for video recording
- `NSDocumentsFolderUsageDescription` - Documents folder access
- `NSDownloadsFolderUsageDescription` - Downloads folder access

## 🛡️ Security Features

### Android

- ProGuard enabled for code obfuscation
- Resource shrinking enabled
- Network security configuration
- File provider for secure file sharing

### iOS

- App Transport Security configured
- File sharing enabled
- Background modes configured

## 📦 Output Locations

After building, find your release files at:

### APK Files

```
build/app/outputs/flutter-apk/
├── app-development-release.apk
├── app-staging-release.apk
└── app-production-release.apk
```

### App Bundle Files

```
build/app/outputs/bundle/
└── productionRelease/
    └── app-production-release.aab
```

### iOS Files

```
build/ios/ipa/
└── Runner.ipa
```

## 🧪 Testing Release Builds

### Android Testing

1. Install APK on physical devices
2. Test all app functionalities
3. Verify permissions work correctly
4. Test network connectivity
5. Test file upload/download features

### iOS Testing

1. Install through TestFlight or direct installation
2. Test on multiple iOS versions
3. Verify all permissions prompts appear
4. Test background functionality

## 📊 Build Optimization

The release builds include:

- Code obfuscation via ProGuard
- Resource shrinking
- APK size optimization
- Dead code elimination
- Asset compression

## 🚀 Deployment

### Google Play Store

1. Upload the `.aab` file (recommended)
2. Configure app signing by Google Play
3. Set up internal testing track first
4. Gradually rollout to production

### Apple App Store

1. Archive the iOS app in Xcode
2. Upload through Xcode or Application Loader
3. Submit for App Store review
4. Configure TestFlight for beta testing

## 🔍 Troubleshooting

### Common Issues

#### Build Failures

- Clean project: `flutter clean`
- Get dependencies: `flutter pub get`
- Check Flutter doctor: `flutter doctor`

#### Signing Issues

- Verify keystore path and credentials
- Ensure keystore file exists
- Check key.properties configuration

#### Permission Issues

- Verify all required permissions are declared
- Test runtime permissions on Android 6+
- Check iOS Info.plist descriptions

### Debug Commands

```bash
# Check build configuration
flutter build apk --release --verbose

# Analyze APK size
flutter build apk --analyze-size

# Check signing information
keytool -list -v -keystore android/app/debug.keystore
```

## 📞 Support

For build-related issues:

1. Check Flutter documentation
2. Review build logs for specific errors
3. Verify all dependencies are compatible
4. Ensure proper signing configuration

## 🔄 Version Management

Update version in `pubspec.yaml`:

```yaml
version: 1.0.0+1 # version+build_number
```

Build with specific version:

```bash
flutter build apk --build-name=1.0.1 --build-number=2
```
