#!/bin/bash

# GSTV Admin Release Build Script
echo "🚀 Starting GSTV Admin Release Build Process..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    exit 1
fi

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Check for key.properties
if [ ! -f "android/key.properties" ]; then
    echo "⚠️  key.properties not found. Using debug keystore for signing."
    echo "   For production builds, create android/key.properties from the template."
fi

# Build release APK
echo "📦 Building release APK..."
flutter build apk --release

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Release APK built successfully!"
    echo "📍 APK location: build/app/outputs/flutter-apk/app-release.apk"
    
    # Show APK size
    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
    echo "📏 APK size: $APK_SIZE"
    
    # Optional: Build App Bundle for Play Store
    echo "📦 Building App Bundle for Play Store..."
    flutter build appbundle --release
    
    if [ $? -eq 0 ]; then
        echo "✅ App Bundle built successfully!"
        echo "📍 AAB location: build/app/outputs/bundle/release/app-release.aab"
        
        AAB_SIZE=$(du -h build/app/outputs/bundle/release/app-release.aab | cut -f1)
        echo "📏 AAB size: $AAB_SIZE"
    fi
    
else
    echo "❌ Build failed!"
    exit 1
fi

echo "🎉 Release build process completed!"
echo ""
echo "📋 Build Summary:"
echo "   • APK: build/app/outputs/flutter-apk/app-release.apk"
echo "   • AAB: build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "📝 Next Steps:"
echo "   1. Test the APK on physical devices"
echo "   2. Upload AAB to Google Play Console"
echo "   3. Configure proper keystore for production releases" 