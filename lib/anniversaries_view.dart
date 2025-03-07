import 'package:flutter/material.dart';

class AnniversariesView extends StatelessWidget {
  final List<Map<String, String>> anniversaries;

  const AnniversariesView({super.key, required this.anniversaries});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anniversaries Today & Tomorrow')),
      body: Column(
        children: [
          Expanded(
            child:
                anniversaries.isEmpty
                    ? const Center(
                      child: Text('No anniversaries today or tomorrow'),
                    )
                    : ListView.builder(
                      itemCount: anniversaries.length,
                      itemBuilder: (_, index) {
                        final entry = anniversaries[index];
                        return ListTile(
                          title: Text(entry['album']!),
                          subtitle: Text(
                            '${entry['artist']} - ${entry['release']}',
                          ),
                          trailing: Text(entry['isToday']!),
                        );
                      },
                    ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.cake),
                onPressed: () {
                  // Already here, no-op
                },
                tooltip: 'Anniversaries',
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Search',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
