#!/bin/bash

# GSTV Admin Multi-Flavor Build Script
echo "🍎 Building GSTV Admin - All Flavors"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    exit 1
fi

# Clean and prepare
echo "🧹 Cleaning and preparing..."
flutter clean
flutter pub get

# Function to build flavor
build_flavor() {
    local flavor=$1
    local build_type=$2
    
    echo "📦 Building $flavor ($build_type)..."
    
    if [ "$build_type" = "apk" ]; then
        flutter build apk --release --flavor $flavor
        if [ $? -eq 0 ]; then
            APK_PATH="build/app/outputs/flutter-apk/app-$flavor-release.apk"
            APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
            echo "✅ $flavor APK built successfully! Size: $APK_SIZE"
        else
            echo "❌ Failed to build $flavor APK"
            return 1
        fi
    elif [ "$build_type" = "appbundle" ]; then
        flutter build appbundle --release --flavor $flavor
        if [ $? -eq 0 ]; then
            AAB_PATH="build/app/outputs/bundle/${flavor}Release/app-$flavor-release.aab"
            AAB_SIZE=$(du -h "$AAB_PATH" | cut -f1)
            echo "✅ $flavor AAB built successfully! Size: $AAB_SIZE"
        else
            echo "❌ Failed to build $flavor AAB"
            return 1
        fi
    fi
}

# Build all flavors
echo ""
echo "🔨 Building Development Flavor..."
build_flavor "development" "apk"

echo ""
echo "🔨 Building Staging Flavor..."
build_flavor "staging" "apk"

echo ""
echo "🔨 Building Production Flavor..."
build_flavor "production" "apk"
build_flavor "production" "appbundle"

echo ""
echo "🎉 All builds completed!"
echo ""
echo "📋 Build Summary:"
echo "   📱 Development APK: build/app/outputs/flutter-apk/app-development-release.apk"
echo "   🧪 Staging APK: build/app/outputs/flutter-apk/app-staging-release.apk"
echo "   🚀 Production APK: build/app/outputs/flutter-apk/app-production-release.apk"
echo "   📦 Production AAB: build/app/outputs/bundle/productionRelease/app-production-release.aab"
echo ""
echo "📝 Flavor Differences:"
echo "   • Development: com.gstv.gstv_admin.dev (Debug features enabled)"
echo "   • Staging: com.gstv.gstv_admin.staging (Testing environment)"
echo "   • Production: com.gstv.gstv_admin (Live environment)" 