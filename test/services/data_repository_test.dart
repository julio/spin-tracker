import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:needl/services/data_repository.dart';
import 'package:needl/services/supabase_data_service.dart';
import 'package:needl/services/snapshot_service.dart';
import 'package:needl/services/auth_service.dart';

class MockSupabaseDataService extends Mock implements SupabaseDataService {}

class MockSnapshotService extends Mock implements SnapshotService {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  late DataRepository repo;
  late MockSupabaseDataService mockRemote;
  late MockSnapshotService mockSnapshot;
  late MockAuthService mockAuth;

  final sampleOwned = [
    {
      'artist': 'Radiohead',
      'album': 'OK Computer',
      'release': '1997-06-16',
      'discogs_id': '',
      'discogs_instance_id': '',
      'acquired_at': '',
    },
  ];
  final sampleWanted = [
    {'artist': 'Radiohead', 'album': 'Kid A'},
  ];

  setUp(() {
    mockRemote = MockSupabaseDataService();
    mockSnapshot = MockSnapshotService();
    mockAuth = MockAuthService();
    repo = DataRepository.forTesting(
      remote: mockRemote,
      snapshot: mockSnapshot,
      auth: mockAuth,
    );

    // Default stubs
    when(() => mockRemote.getAllOwnedAlbums())
        .thenAnswer((_) async => sampleOwned);
    when(() => mockRemote.getAllWantedAlbums())
        .thenAnswer((_) async => sampleWanted);
    when(() => mockSnapshot.save(
            owned: any(named: 'owned'), wanted: any(named: 'wanted')))
        .thenAnswer((_) async {});
    when(() => mockSnapshot.deleteOldDatabase()).thenAnswer((_) async {});
    when(() => mockSnapshot.clear()).thenAnswer((_) async {});
  });

  group('loadData', () {
    test('loads from Supabase and saves snapshot', () async {
      await repo.loadData();

      expect(repo.isLoaded, isTrue);
      expect(repo.isOffline, isFalse);
      expect(await repo.getAllOwnedAlbums(), sampleOwned);
      expect(await repo.getAllWantedAlbums(), sampleWanted);
      verify(() => mockSnapshot.save(
          owned: sampleOwned, wanted: sampleWanted)).called(1);
      verify(() => mockSnapshot.deleteOldDatabase()).called(1);
    });

    test('falls back to snapshot when Supabase fails', () async {
      when(() => mockRemote.getAllOwnedAlbums())
          .thenThrow(Exception('Network error'));
      when(() => mockSnapshot.load()).thenAnswer((_) async =>
          (owned: sampleOwned, wanted: sampleWanted));

      await repo.loadData();

      expect(repo.isLoaded, isTrue);
      expect(repo.isOffline, isTrue);
      expect(await repo.getAllOwnedAlbums(), sampleOwned);
      expect(await repo.getAllWantedAlbums(), sampleWanted);
    });

    test('sets isLoaded false when both Supabase and snapshot fail', () async {
      when(() => mockRemote.getAllOwnedAlbums())
          .thenThrow(Exception('Network error'));
      when(() => mockSnapshot.load()).thenAnswer((_) async => null);

      await repo.loadData();

      expect(repo.isLoaded, isFalse);
      expect(repo.isOffline, isTrue);
    });
  });

  group('in-memory cache reads', () {
    test('returns empty lists before loadData', () async {
      expect(await repo.getAllOwnedAlbums(), isEmpty);
      expect(await repo.getAllWantedAlbums(), isEmpty);
      expect(await repo.getOwnedCount(), 0);
      expect(await repo.getWantedCount(), 0);
    });

    test('returns correct counts after loading', () async {
      await repo.loadData();
      expect(await repo.getOwnedCount(), 1);
      expect(await repo.getWantedCount(), 1);
    });
  });

  group('tier', () {
    test('fetches and caches tier from AuthService', () async {
      when(() => mockAuth.getTier()).thenAnswer((_) async => 'premium');

      final t1 = await repo.tier;
      final t2 = await repo.tier;

      expect(t1, 'premium');
      expect(t2, 'premium');
      // Should only call getTier once due to caching
      verify(() => mockAuth.getTier()).called(1);
    });

    test('clearTierCache forces re-fetch', () async {
      when(() => mockAuth.getTier()).thenAnswer((_) async => 'free');

      await repo.tier;
      repo.clearTierCache();
      await repo.tier;

      verify(() => mockAuth.getTier()).called(2);
    });
  });

  group('addOwnedAlbum', () {
    test('succeeds for premium user', () async {
      when(() => mockAuth.getTier()).thenAnswer((_) async => 'premium');
      when(() => mockRemote.addOwnedAlbum(
            artist: any(named: 'artist'),
            album: any(named: 'album'),
            releaseDate: any(named: 'releaseDate'),
            acquiredAt: any(named: 'acquiredAt'),
            discogsId: any(named: 'discogsId'),
            discogsInstanceId: any(named: 'discogsInstanceId'),
          )).thenAnswer((_) async {});

      await repo.addOwnedAlbum(
        artist: 'Test',
        album: 'Album',
        releaseDate: '2024-01-01',
      );

      verify(() => mockRemote.addOwnedAlbum(
            artist: 'Test',
            album: 'Album',
            releaseDate: '2024-01-01',
            acquiredAt: '',
            discogsId: null,
            discogsInstanceId: null,
          )).called(1);
    });

    test('succeeds for free user under limit', () async {
      when(() => mockAuth.getTier()).thenAnswer((_) async => 'free');
      when(() => mockRemote.getOwnedCount()).thenAnswer((_) async => 50);
      when(() => mockRemote.addOwnedAlbum(
            artist: any(named: 'artist'),
            album: any(named: 'album'),
            releaseDate: any(named: 'releaseDate'),
            acquiredAt: any(named: 'acquiredAt'),
            discogsId: any(named: 'discogsId'),
            discogsInstanceId: any(named: 'discogsInstanceId'),
          )).thenAnswer((_) async {});

      await repo.addOwnedAlbum(
        artist: 'Test',
        album: 'Album',
        releaseDate: '2024-01-01',
      );

      verify(() => mockRemote.addOwnedAlbum(
            artist: any(named: 'artist'),
            album: any(named: 'album'),
            releaseDate: any(named: 'releaseDate'),
            acquiredAt: any(named: 'acquiredAt'),
            discogsId: any(named: 'discogsId'),
            discogsInstanceId: any(named: 'discogsInstanceId'),
          )).called(1);
    });

    test('throws when free user at owned limit', () async {
      when(() => mockAuth.getTier()).thenAnswer((_) async => 'free');
      when(() => mockRemote.getOwnedCount()).thenAnswer((_) async => 100);

      expect(
        () => repo.addOwnedAlbum(
          artist: 'Test',
          album: 'Album',
          releaseDate: '2024-01-01',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Free tier limit'),
        )),
      );
    });

    test('refreshes cache after successful add', () async {
      when(() => mockAuth.getTier()).thenAnswer((_) async => 'premium');
      when(() => mockRemote.addOwnedAlbum(
            artist: any(named: 'artist'),
            album: any(named: 'album'),
            releaseDate: any(named: 'releaseDate'),
            acquiredAt: any(named: 'acquiredAt'),
            discogsId: any(named: 'discogsId'),
            discogsInstanceId: any(named: 'discogsInstanceId'),
          )).thenAnswer((_) async {});

      await repo.addOwnedAlbum(
        artist: 'Test',
        album: 'Album',
        releaseDate: '2024-01-01',
      );

      // getAllOwnedAlbums called twice: once in add's _fetchFromRemote
      verify(() => mockRemote.getAllOwnedAlbums()).called(1);
      verify(() => mockRemote.getAllWantedAlbums()).called(1);
    });
  });

  group('addWantedAlbum', () {
    test('succeeds for premium user', () async {
      when(() => mockAuth.getTier()).thenAnswer((_) async => 'premium');
      when(() => mockRemote.addWantedAlbum(
            artist: any(named: 'artist'),
            album: any(named: 'album'),
          )).thenAnswer((_) async {});

      await repo.addWantedAlbum(artist: 'Test', album: 'Album');

      verify(() => mockRemote.addWantedAlbum(
          artist: 'Test', album: 'Album')).called(1);
    });

    test('throws when free user at wanted limit', () async {
      when(() => mockAuth.getTier()).thenAnswer((_) async => 'free');
      when(() => mockRemote.getWantedCount()).thenAnswer((_) async => 50);

      expect(
        () => repo.addWantedAlbum(artist: 'Test', album: 'Album'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Free tier limit'),
        )),
      );
    });

    test('succeeds for free user under limit', () async {
      when(() => mockAuth.getTier()).thenAnswer((_) async => 'free');
      when(() => mockRemote.getWantedCount()).thenAnswer((_) async => 10);
      when(() => mockRemote.addWantedAlbum(
            artist: any(named: 'artist'),
            album: any(named: 'album'),
          )).thenAnswer((_) async {});

      await repo.addWantedAlbum(artist: 'Test', album: 'Album');

      verify(() => mockRemote.addWantedAlbum(
          artist: any(named: 'artist'),
          album: any(named: 'album'))).called(1);
    });
  });

  group('deleteOwnedAlbum', () {
    test('deletes from remote and refreshes cache', () async {
      when(() => mockRemote.deleteOwnedAlbum(
            artist: any(named: 'artist'),
            album: any(named: 'album'),
            releaseDate: any(named: 'releaseDate'),
          )).thenAnswer((_) async {});

      await repo.deleteOwnedAlbum(
        artist: 'Test',
        album: 'Album',
        releaseDate: '2024-01-01',
      );

      verify(() => mockRemote.deleteOwnedAlbum(
            artist: 'Test',
            album: 'Album',
            releaseDate: '2024-01-01',
          )).called(1);
      verify(() => mockRemote.getAllOwnedAlbums()).called(1);
    });
  });

  group('deleteWantedAlbum', () {
    test('deletes from remote and refreshes cache', () async {
      when(() => mockRemote.deleteWantedAlbum(
            artist: any(named: 'artist'),
            album: any(named: 'album'),
          )).thenAnswer((_) async {});

      await repo.deleteWantedAlbum(artist: 'Test', album: 'Album');

      verify(() => mockRemote.deleteWantedAlbum(
          artist: 'Test', album: 'Album')).called(1);
      verify(() => mockRemote.getAllOwnedAlbums()).called(1);
    });
  });

  group('updateDiscogsId', () {
    test('updates remote and refreshes cache', () async {
      when(() => mockRemote.updateDiscogsId(
            artist: any(named: 'artist'),
            album: any(named: 'album'),
            releaseDate: any(named: 'releaseDate'),
            discogsId: any(named: 'discogsId'),
            discogsInstanceId: any(named: 'discogsInstanceId'),
          )).thenAnswer((_) async {});

      await repo.updateDiscogsId(
        artist: 'Test',
        album: 'Album',
        releaseDate: '2024-01-01',
        discogsId: 123,
        discogsInstanceId: 456,
      );

      verify(() => mockRemote.updateDiscogsId(
            artist: 'Test',
            album: 'Album',
            releaseDate: '2024-01-01',
            discogsId: 123,
            discogsInstanceId: 456,
          )).called(1);
    });
  });

  group('syncFromRemote', () {
    test('refreshes cache and clears offline flag', () async {
      // First put repo in offline mode
      when(() => mockRemote.getAllOwnedAlbums())
          .thenThrow(Exception('Network error'));
      when(() => mockSnapshot.load()).thenAnswer((_) async =>
          (owned: sampleOwned, wanted: sampleWanted));
      await repo.loadData();
      expect(repo.isOffline, isTrue);

      // Now sync succeeds
      when(() => mockRemote.getAllOwnedAlbums())
          .thenAnswer((_) async => sampleOwned);

      await repo.syncFromRemote();

      expect(repo.isOffline, isFalse);
      expect(repo.isLoaded, isTrue);
    });
  });

  group('remote passthrough methods', () {
    test('getRemoteOwnedCount delegates to remote', () async {
      when(() => mockRemote.getOwnedCount()).thenAnswer((_) async => 42);
      expect(await repo.getRemoteOwnedCount(), 42);
    });

    test('getRemoteWantedCount delegates to remote', () async {
      when(() => mockRemote.getWantedCount()).thenAnswer((_) async => 7);
      expect(await repo.getRemoteWantedCount(), 7);
    });

    test('getRemoteOwnedAlbums delegates to remote', () async {
      expect(await repo.getRemoteOwnedAlbums(), sampleOwned);
    });

    test('getRemoteWantedAlbums delegates to remote', () async {
      expect(await repo.getRemoteWantedAlbums(), sampleWanted);
    });
  });

  group('clearAll', () {
    test('resets all state', () async {
      await repo.loadData();
      expect(await repo.getOwnedCount(), 1);

      repo.clearAll();

      expect(await repo.getOwnedCount(), 0);
      expect(await repo.getWantedCount(), 0);
      expect(repo.isLoaded, isFalse);
      expect(repo.isOffline, isFalse);
      verify(() => mockSnapshot.clear()).called(1);
    });
  });
}
