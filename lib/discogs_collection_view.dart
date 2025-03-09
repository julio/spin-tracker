import 'package:flutter/material.dart';
import 'services/discogs_service.dart';
import 'components/bottom_nav.dart';

class DiscogsCollectionView extends StatefulWidget {
  final List<Map<String, String>> Function() getAnniversaries;
  final List<Map<String, String>> ownedAlbums;

  const DiscogsCollectionView({
    super.key,
    required this.getAnniversaries,
    required this.ownedAlbums,
  });

  @override
  DiscogsCollectionViewState createState() => DiscogsCollectionViewState();
}

class DiscogsCollectionViewState extends State<DiscogsCollectionView> {
  final _discogsService = DiscogsService();
  bool isLoading = true;
  String? error;
  int? totalCount;
  List<Map<String, dynamic>> releases = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final collectionInfo = await _discogsService.getCollectionInfo();
      final collectionReleases = await _discogsService.getCollectionReleases();

      setState(() {
        totalCount = collectionInfo['count'] as int;
        releases = collectionReleases;
        isLoading = false;
      });

      // Load thumbnails after displaying the initial data
      for (var release in releases) {
        await _discogsService.loadReleaseThumbnail(release);
        // Update the UI when each thumbnail is loaded
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discogs Collection'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : error != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading collection:\n$error',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                    : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Total Records: ${totalCount ?? 0}',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: releases.length,
                            itemBuilder: (context, index) {
                              final release = releases[index];
                              final basicInformation =
                                  release['basic_information']
                                      as Map<String, dynamic>;
                              final dateAdded = release['date_added'] as String;

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      if (basicInformation['thumb'] != null &&
                                          basicInformation['thumb']
                                              .toString()
                                              .isNotEmpty)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4.0,
                                          ),
                                          child: Image.network(
                                            basicInformation['thumb'] as String,
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.album,
                                                      size: 80,
                                                    ),
                                          ),
                                        )
                                      else
                                        const Icon(Icons.album, size: 80),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              basicInformation['title']
                                                  as String,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              (basicInformation['artists']
                                                      as List)
                                                  .map(
                                                    (a) =>
                                                        (a as Map)['name']
                                                            as String,
                                                  )
                                                  .join(', '),
                                              style: const TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Added: ${dateAdded.substring(0, 10)}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
          ),
          BottomNav(
            isOnSearchView: false,
            getAnniversaries: widget.getAnniversaries,
            ownedAlbums: widget.ownedAlbums,
          ),
        ],
      ),
    );
  }
}
