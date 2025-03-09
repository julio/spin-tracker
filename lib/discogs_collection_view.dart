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
      setState(() {
        totalCount = collectionInfo['count'] as int;
        isLoading = false;
      });
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
                    : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Records: ${totalCount ?? 0}',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
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
