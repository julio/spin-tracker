# Spin Tracker

A Flutter application to manage and track your vinyl record collection. Keep track of owned albums and maintain a wishlist, with album cover art integration via Spotify's API.

## Features

- View and manage your vinyl collection
- Track wanted albums with list/ranking information
- Search through your collection by artist
- View album cover art (powered by Spotify)
- Track album anniversaries
- Dark mode interface
- Integration with Google Sheets for data storage

## Setup

1. Prerequisites:
   - Flutter SDK (^3.7.0)
   - Dart SDK
   - Google Cloud project with Sheets API enabled
   - Spotify Developer account for cover art integration
   - Xcode (for iOS development)
   - Android Studio (for Android development)

2. Configuration:
   - Place your Google Sheets credentials in `assets/vinylcollection-451818-1e41b0728e29.json`
   - Create a `lib/config.dart` file with your configuration:
     ```dart
     const spreadsheetId = 'YOUR_SPREADSHEET_ID';
     const spotifyClientId = 'YOUR_SPOTIFY_CLIENT_ID';
     const spotifyClientSecret = 'YOUR_SPOTIFY_CLIENT_SECRET';
     ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Start a simulator/emulator:

   For iOS:
   ```bash
   # List available simulators
   xcrun simctl list devices

   # Start a specific simulator (replace [DEVICE_ID] with your preferred device)
   open -a Simulator --args -CurrentDeviceUDID [DEVICE_ID]

   # Or simply start the default iOS simulator
   open -a Simulator
   ```

   For Android:
   ```bash
   # List available emulators
   flutter emulators

   # Start an emulator (replace [emulator_id] with your preferred device)
   flutter emulators --launch [emulator_id]
   ```

5. Run the app:
   ```bash
   # Run on the active device/simulator
   flutter run

   # Or specify a target device if multiple are connected
   flutter run -d [device_id]
   ```

## Deploying to Physical Devices

### iOS Device
1. Connect your iPhone via USB cable
2. Trust the computer on your iPhone if prompted
3. Open Xcode and register your device:
   - Open `ios/Runner.xcworkspace`
   - Select your device from the device dropdown
   - Sign in with your Apple ID if needed
   - Configure code signing and provisioning profiles
4. Deploy from command line:
   ```bash
   # List connected devices
   flutter devices

   # Deploy to your iPhone
   flutter run --release
   ```

### Android Device
1. Enable Developer Options on your Android device:
   - Go to Settings > About Phone
   - Tap "Build Number" seven times
   - Go back to Settings > Developer Options
   - Enable "USB Debugging"
2. Connect your Android device via USB cable
3. Accept the USB debugging prompt on your device
4. Deploy from command line:
   ```bash
   # List connected devices
   flutter devices

   # Deploy to your Android device
   flutter run --release
   ```

Note: For both platforms, you can also use `flutter install` to install a release build without running it immediately.

## Google Sheets Structure

The app expects a sheet with two tabs:

### Owned Tab
- Required columns: "Artist", "Album", "Release"
- Tab name: "Owned"

### Wanted Tab
- Required columns: "Artist", "Album", "Check"
- Tab name: "Wanted"
- "Check" column should contain "no" for albums still wanted

## Dependencies

- googleapis: ^13.2.0
- http: ^1.2.2
- dropdown_search: ^5.0.6
- googleapis_auth: ^1.6.0
- logging: ^1.2.0

## Music Playback Integration

To add music playback functionality, you would need to:

1. Add the Spotify SDK dependencies:
   ```yaml
   dependencies:
     spotify_sdk: ^2.3.1  # For playback control
     spotify_web_api: ^1.2.0  # For track information
   ```

2. Configure Spotify in your app:
   - Add to your config.dart:
     ```dart
     const spotifyRedirectUri = 'your-app-scheme://callback';
     ```
   - Update iOS Info.plist:
     ```xml
     <key>CFBundleURLTypes</key>
     <array>
       <dict>
         <key>CFBundleURLSchemes</key>
         <array>
           <string>your-app-scheme</string>
         </array>
       </dict>
     </array>
     ```
   - Update Android AndroidManifest.xml:
     ```xml
     <activity>
       <intent-filter>
         <action android:name="android.intent.action.VIEW" />
         <category android:name="android.intent.category.DEFAULT" />
         <category android:name="android.intent.category.BROWSABLE" />
         <data android:scheme="your-app-scheme" />
       </intent-filter>
     </activity>
     ```

3. Implementation Steps:
   - Connect to Spotify when app launches
   - Add playback buttons to album entries
   - Handle authentication flow
   - Implement play/pause/skip functionality

Note: Users will need the Spotify app installed and a Premium account for full playback functionality. Free accounts can only play 30-second previews.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
