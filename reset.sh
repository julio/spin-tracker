#!/bin/bash

# Reset and rebuild Flutter project for iOS simulator

echo "Starting full reset and rebuild..."

# Navigate to project root (assuming script is run from project directory)
cd "$(dirname "$0")" || { echo "Failed to navigate to script directory"; exit 1; }

# Clean Flutter project
echo "Cleaning Flutter project..."
flutter clean || { echo "Flutter clean failed"; exit 1; }

# Remove iOS build artifacts
echo "Removing iOS build artifacts..."
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData

# Reinstall Flutter dependencies
echo "Reinstalling Flutter dependencies..."
flutter pub get || { echo "Flutter pub get failed"; exit 1; }

# Rebuild iOS Pods
echo "Rebuilding iOS Pods..."
cd ios || { echo "Failed to navigate to ios directory"; exit 1; }
pod deintegrate
pod cache clean --all
pod install --verbose || { echo "Pod install failed"; exit 1; }
cd .. || { echo "Failed to return to project root"; exit 1; }

# Verify Flutter environment
echo "Verifying Flutter environment..."
flutter doctor -v

echo "Reset and rebuild complete. Ready to run on simulator."
echo "To run: flutter run -d \"iPhone SE (3rd generation)\""
