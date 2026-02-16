import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'services/data_repository.dart';
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
  DateTime _acquiredDate = DateTime.now();
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
      final date = await _searchMusicBrainz(artist, album);
      if (date != null && mounted) {
        setState(() {
          _releaseDate = date;
          _isSearching = false;
        });
        return;
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

  Future<DateTime?> _searchMusicBrainz(String artist, String album) async {
    final query = Uri.encodeQueryComponent('release:"$album" AND artist:"$artist"');
    final url = Uri.parse(
      'https://musicbrainz.org/ws/2/release/?query=$query&fmt=json&limit=5',
    );
    final response = await http.get(url, headers: {
      'User-Agent': 'Needl/1.0 (vinyl collection tracker)',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final releases = data['releases'] as List? ?? [];
      for (final release in releases) {
        final dateStr = release['date'] as String?;
        if (dateStr != null && dateStr.isNotEmpty) {
          final parsed = _parseDate(dateStr);
          if (parsed != null) return parsed;
        }
      }
    }
    return null;
  }

  DateTime? _parseDate(String dateStr) {
    // MusicBrainz dates can be YYYY, YYYY-MM, or YYYY-MM-DD
    final parts = dateStr.split('-');
    final year = int.tryParse(parts[0]);
    if (year == null || year < 1900) return null;
    final month = parts.length > 1 ? int.tryParse(parts[1]) ?? 1 : 1;
    final day = parts.length > 2 ? int.tryParse(parts[2]) ?? 1 : 1;
    return DateTime(year, month, day);
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

  Future<void> _pickAcquiredDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _acquiredDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _acquiredDate = picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await DataRepository().addOwnedAlbum(
        artist: _artistController.text.trim(),
        album: _albumController.text.trim(),
        releaseDate: _releaseDate != null ? _formatDate(_releaseDate!) : '',
        acquiredAt: _formatDate(_acquiredDate),
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
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickAcquiredDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Acquired',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
                  ),
                  child: Text(
                    _formatDate(_acquiredDate),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
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
