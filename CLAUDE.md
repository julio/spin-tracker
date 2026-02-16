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
- `supabaseUrl` / `supabaseAnonKey` - Supabase project credentials
- `spotifyClientId` - Spotify client ID (public; secret is in Edge Function)
- `spotifyRedirectUri` - Spotify SDK callback URI
- `discogsPersonalAccessToken` / `discogsUsername` - Discogs API credentials (bridge, per-user in Phase 2)

Supabase Edge Functions need these environment variables:
- `SPOTIFY_CLIENT_ID` / `SPOTIFY_CLIENT_SECRET` - for the spotify-token function

## Architecture

This is a Flutter app for tracking vinyl record collections. Data is stored in Supabase (remote) with SQLite as a local cache.

### Data Flow

- **Reads**: from local SQLite (fast, offline)
- **Writes**: to Supabase first, then update local SQLite on success
- **Sync**: pull full dataset from Supabase, replace local data

### Key Services

- `lib/services/data_repository.dart` - Coordinates Supabase + SQLite cache, enforces freemium tier limits
- `lib/services/supabase_data_service.dart` - Remote data layer wrapping Supabase client
- `lib/services/database_service.dart` - Local SQLite cache (singleton)
- `lib/services/auth_service.dart` - Wraps Supabase Auth (email/password, Apple Sign-In)
- `lib/services/discogs_service.dart` - Discogs API integration (singleton)
- `lib/services/spotify_service.dart` - Spotify SDK integration for playback control
- `lib/api_utils.dart` - Spotify cover art fetching via Edge Function token

### Key Files

- `lib/main.dart` - App entry point, Supabase init, auth gate, theme configuration
- `lib/vinyl_home_page.dart` - Main view with artist dropdown search, owned/wanted album lists
- `lib/auth/login_view.dart` + `lib/auth/signup_view.dart` - Auth screens

### Views

- `VinylHomePage` - Search by artist, view owned/wanted albums
- `CoverArtView` - Full-screen album cover with Spotify playback button
- `RandomAlbumView` - Pick random album from collection
- `AnniversariesView` - Albums with release anniversaries today/tomorrow
- `DiscogsCollectionView` - Browse Discogs collection with pagination
- `SyncStatusView` - Compare counts across DB / Supabase / Discogs
- `AddRecordView` - Add album with MusicBrainz release date lookup

### Supabase Schema

Tables: `profiles`, `owned_albums`, `wanted_albums` — all with RLS policies scoped to `auth.uid() = user_id`. Schema in `supabase/migrations/`.

### Edge Functions

- `supabase/functions/spotify-token/` - Spotify client credentials proxy (keeps secret server-side)

### Navigation

`BottomNav` component provides navigation between views. Views pass `ownedAlbums` list and `getAnniversaries` callback through the navigation tree.

### State Pattern

Album data is fetched once in `VinylHomePage._loadData()` and passed down to child views. No state management library - uses StatefulWidget with setState.

### Freemium Tiers

Free: 100 owned, 50 wanted albums. Premium: unlimited. Enforced in `DataRepository`.
