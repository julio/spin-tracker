# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Run Commands

```bash
# Install dependencies
flutter pub get

# Run the app (on connected device or simulator)
flutter run

# Run on specific device
flutter run -d [device_id]

# Build release version
flutter run --release

# Analyze code for issues
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart
```

## Configuration

Create `lib/config.dart` from `lib/config.dart.default` and populate:
- `spreadsheetId` - Google Sheets ID for vinyl collection data
- `spotifyClientId` / `spotifyClientSecret` - Spotify API credentials for cover art
- `discogsPersonalAccessToken` / `discogsUsername` - Discogs API credentials

Google Sheets credentials JSON goes in `assets/`.

## Architecture

This is a Flutter app for tracking vinyl record collections. Data is stored in Google Sheets with two tabs:
- **Owned**: columns "Artist", "Album", "Release" (date in YYYY-MM-DD format)
- **Wanted**: columns "Artist", "Album", "Check" (value "no" means still wanted)

### Key Files

- `lib/main.dart` - App entry point, theme configuration (light/dark), `SpinTrackerApp` root widget
- `lib/vinyl_home_page.dart` - Main view with artist dropdown search, owned/wanted album lists. Initializes Google Sheets API and fetches all data
- `lib/api_utils.dart` - Static helper for Spotify API (cover art fetching via client credentials flow)
- `lib/services/spotify_service.dart` - Spotify SDK integration for playback control
- `lib/services/discogs_service.dart` - Discogs API integration (singleton pattern)

### Views

- `VinylHomePage` - Search by artist, view owned/wanted albums
- `CoverArtView` - Full-screen album cover with Spotify playback button
- `RandomAlbumView` - Pick random album from collection
- `AnniversariesView` - Albums with release anniversaries today/tomorrow
- `DiscogsCollectionView` - Browse Discogs collection with pagination

### Navigation

`BottomNav` component provides navigation between views. Views pass `ownedAlbums` list and `getAnniversaries` callback through the navigation tree.

### State Pattern

Album data is fetched once in `VinylHomePage._fetchData()` and passed down to child views. No state management library - uses StatefulWidget with setState.
