import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'services/database_service.dart';
import 'discogs_search_sheet.dart';

class AddRecordView extends StatefulWidget {
  const AddRecordView({super.key});

  @override
  AddRecordViewState createState() => AddRecordViewState();
}

class AddRecordViewState extends State<AddRecordView> {
  final _formKey = GlobalKey<FormState>();
  final _artistController = TextEditingController();
  final _albumController = TextEditingController();
  DateTime? _releaseDate;
  bool _isSaving = false;
  bool _isSearching = false;

  @override
  void dispose() {
    _artistController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  Future<void> _findReleaseDate() async {
    final artist = _artistController.text.trim();
    final album = _albumController.text.trim();

    if (artist.isEmpty || album.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter artist and album first')),
      );
      return;
    }

    setState(() => _isSearching = true);

    try {
      final query = Uri.encodeQueryComponent('$artist $album release date');
      final url = Uri.parse('https://html.duckduckgo.com/html/?q=$query');
      final response = await http.get(url, headers: {
        'User-Agent':
            'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
      });

      if (response.statusCode == 200) {
        final date = _parseDateFromHtml(response.body);
        if (date != null && mounted) {
          setState(() {
            _releaseDate = date;
            _isSearching = false;
          });
          return;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find release date')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find release date')),
      );
    }

    if (mounted) setState(() => _isSearching = false);
  }

  DateTime? _parseDateFromHtml(String html) {
    final text = html.replaceAll(RegExp(r'<[^>]*>'), ' ');

    const months = {
      'january': 1, 'february': 2, 'march': 3, 'april': 4,
      'may': 5, 'june': 6, 'july': 7, 'august': 8,
      'september': 9, 'october': 10, 'november': 11, 'december': 12,
    };

    // Date pattern handling ordinals (1st, 2nd, 3rd, 4th, etc.)
    const monthNames =
        r'January|February|March|April|May|June|July|August|September|October|November|December';
    final mdyPattern =
        '($monthNames)\\s+(\\d{1,2})(?:st|nd|rd|th)?,?\\s+(\\d{4})';
    final dmyPattern =
        '(\\d{1,2})(?:st|nd|rd|th)?\\s+($monthNames),?\\s+(\\d{4})';

    DateTime? tryParseMdy(Match m) {
      final month = months[m.group(1)!.toLowerCase()]!;
      final day = int.parse(m.group(2)!);
      final year = int.parse(m.group(3)!);
      if (day >= 1 && day <= 31 && year >= 1900) return DateTime(year, month, day);
      return null;
    }

    DateTime? tryParseDmy(Match m) {
      final day = int.parse(m.group(1)!);
      final month = months[m.group(2)!.toLowerCase()]!;
      final year = int.parse(m.group(3)!);
      if (day >= 1 && day <= 31 && year >= 1900) return DateTime(year, month, day);
      return null;
    }

    // 1) Look for "release date : <date>" context
    final contextMatch = RegExp(
      'release\\s*date\\s*:?\\s*$mdyPattern',
      caseSensitive: false,
    ).firstMatch(text);
    if (contextMatch != null) {
      final d = tryParseMdy(contextMatch);
      if (d != null) return d;
    }

    // 2) Look for "released (on) <date>" context
    final releasedMatch = RegExp(
      'released\\s+(?:on\\s+)?$mdyPattern',
      caseSensitive: false,
    ).firstMatch(text);
    if (releasedMatch != null) {
      final d = tryParseMdy(releasedMatch);
      if (d != null) return d;
    }

    // 3) Same context patterns but DD Month YYYY
    final contextDmy = RegExp(
      'release\\s*date\\s*:?\\s*$dmyPattern',
      caseSensitive: false,
    ).firstMatch(text);
    if (contextDmy != null) {
      final d = tryParseDmy(contextDmy);
      if (d != null) return d;
    }

    final releasedDmy = RegExp(
      'released\\s+(?:on\\s+)?$dmyPattern',
      caseSensitive: false,
    ).firstMatch(text);
    if (releasedDmy != null) {
      final d = tryParseDmy(releasedDmy);
      if (d != null) return d;
    }

    // 4) Fallback: first Month DD, YYYY in the text
    final fallback = RegExp(mdyPattern, caseSensitive: false).firstMatch(text);
    if (fallback != null) {
      final d = tryParseMdy(fallback);
      if (d != null) return d;
    }

    // 5) Fallback: first DD Month YYYY in the text
    final fallbackDmy = RegExp(dmyPattern, caseSensitive: false).firstMatch(text);
    if (fallbackDmy != null) {
      final d = tryParseDmy(fallbackDmy);
      if (d != null) return d;
    }

    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _releaseDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _releaseDate = picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await DatabaseService().addOwnedAlbum(
        artist: _artistController.text.trim(),
        album: _albumController.text.trim(),
        releaseDate: _releaseDate != null ? _formatDate(_releaseDate!) : '',
      );
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showDiscogsSheet();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving record: $e')),
      );
      setState(() => _isSaving = false);
    }
  }

  void _showDiscogsSheet() {
    showDiscogsSearchSheet(
      context,
      artist: _artistController.text.trim(),
      album: _albumController.text.trim(),
      releaseDate: _releaseDate != null ? _formatDate(_releaseDate!) : '',
    ).then((_) {
      if (mounted) Navigator.pop(context, true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Record'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _artistController,
                decoration: InputDecoration(
                  labelText: 'Artist',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Artist is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _albumController,
                decoration: InputDecoration(
                  labelText: 'Album',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Album is required' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Release Date',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
                  ),
                  child: Text(
                    _releaseDate != null ? _formatDate(_releaseDate!) : 'Tap to select',
                    style: TextStyle(
                      color: _releaseDate != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _isSearching ? null : _findReleaseDate,
                  icon: _isSearching
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search_rounded, size: 18),
                  label: Text(_isSearching ? 'Searching...' : 'Find Release Date'),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
