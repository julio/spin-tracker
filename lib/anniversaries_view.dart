import 'package:flutter/material.dart';
import 'api_utils.dart';
import 'components/bottom_nav.dart';

class AnniversariesView extends StatefulWidget {
  final List<Map<String, String>> anniversaries;

  const AnniversariesView({super.key, required this.anniversaries});

  @override
  AnniversariesViewState createState() => AnniversariesViewState();
}

class AnniversariesViewState extends State<AnniversariesView> {
  late List<Future<String?>> coverFutures;

  @override
  void initState() {
    super.initState();
    coverFutures =
        widget.anniversaries
            .map(
              (entry) =>
                  ApiUtils.fetchCoverArt(entry['artist']!, entry['album']!),
            )
            .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anniversaries Today & Tomorrow'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child:
                widget.anniversaries.isEmpty
                    ? const Center(
                      child: Text('No anniversaries today or tomorrow'),
                    )
                    : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                            childAspectRatio:
                                0.65, // Adjusted for larger cover + extra text
                          ),
                      itemCount: widget.anniversaries.length,
                      itemBuilder: (context, index) {
                        final entry = widget.anniversaries[index];
                        return FutureBuilder<String?>(
                          future: coverFutures[index],
                          builder: (context, snapshot) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (snapshot.connectionState ==
                                        ConnectionState.waiting ||
                                    !snapshot.hasData)
                                  const CircularProgressIndicator()
                                else if (snapshot.hasError ||
                                    snapshot.data == null)
                                  const Icon(Icons.error, size: 120)
                                else
                                  Image.network(
                                    snapshot.data!,
                                    height: 120,
                                    width: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.error, size: 120),
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  entry['album']!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  entry['artist']!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  entry['release']!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
          ),
          const BottomNav(),
        ],
      ),
    );
  }
}
