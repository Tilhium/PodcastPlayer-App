import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:podcastplayer/models/songs_model.dart';
import 'package:podcastplayer/screens/play_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:podcastplayer/theme/app_theme.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<_RecentSearchEntry> recentSearches = [];
  final TextEditingController _searchController = TextEditingController();
  List<Song> _filteredSongs = [];
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecentSearches() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recent_searches')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      if (!mounted) return;
      setState(() {
        recentSearches = snapshot.docs
            .map((doc) {
              final data = doc.data();

              final songId = data['song_id'] as String?;
              final title = data['title'] as String?;
              final subtitle = data['subtitle'] as String?;
              final coverUrl = data['cover_url'] as String?;

              if (songId != null && title != null) {
                return _RecentSearchEntry(
                  documentId: doc.id,
                  songId: songId,
                  title: title,
                  subtitle: subtitle ?? '',
                  coverUrl: coverUrl ?? '',
                );
              }

              final rawQuery = (data['search_query'] as String?)?.trim();
              if (rawQuery == null || rawQuery.isEmpty) {
                return null;
              }

              final matchedSong = Song.songs.firstWhereOrNull(
                (song) => song.title.toLowerCase() == rawQuery.toLowerCase(),
              );

              if (matchedSong != null) {
                return _RecentSearchEntry.fromSong(
                  matchedSong,
                  documentId: doc.id,
                );
              }

              return _RecentSearchEntry(
                documentId: doc.id,
                songId: rawQuery,
                title: rawQuery,
                subtitle: '',
                coverUrl: '',
              );
            })
            .whereNotNull()
            .toList();
      });
    } catch (e) {
      debugPrint('Failed to load recent searches: $e');
    }
  }

  Future<void> _addRecentSong(Song song) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final entry = _RecentSearchEntry.fromSong(song);

    setState(() {
      final updated = <_RecentSearchEntry>[entry];
      updated.addAll(recentSearches.where((item) => item.songId != entry.songId));
      recentSearches = updated.take(10).toList();
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recent_searches')
          .doc(entry.songId)
          .set({
        'song_id': entry.songId,
        'title': entry.title,
        'subtitle': entry.subtitle,
        'cover_url': entry.coverUrl,
        'timestamp': DateTime.now(),
      });
    } catch (e) {
      debugPrint('Failed to store recent search: $e');
    }
  }

  Future<void> removeRecentSearch(_RecentSearchEntry entry) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      recentSearches.removeWhere((item) => item.songId == entry.songId);
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recent_searches')
          .doc(entry.documentId)
          .delete();
    } catch (e) {
      debugPrint('Failed to remove recent search: $e');
    }
  }

  Future<void> clearRecentSearches() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      recentSearches = [];
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recent_searches')
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Failed to clear recent searches: $e');
    }
  }

  void _handleSearch(String rawValue) async {
    final value = rawValue.trim();
    if (value.isEmpty) return;
    _onQueryChanged(value);

    final matchedSong = _filteredSongs.isNotEmpty ? _filteredSongs.first : null;

    if (matchedSong != null) {
      await _openSong(matchedSong);
    } else {
      _showNotFound();
    }
  }

  Future<void> _openSong(Song song) async {
    await _addRecentSong(song);

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayPage(song: song),
      ),
    );
  }

  void _onQueryChanged(String value) {
    final trimmed = value.trim();
    final query = trimmed.toLowerCase();
    setState(() {
      _currentQuery = trimmed;
      if (query.isEmpty) {
        _filteredSongs = [];
      } else {
        final matches = Song.songs
            .where((song) => song.title.toLowerCase().contains(query))
            .toList();
        matches.sort((a, b) {
          final aTitle = a.title.toLowerCase();
          final bTitle = b.title.toLowerCase();
          final aStarts = aTitle.startsWith(query);
          final bStarts = bTitle.startsWith(query);
          if (aStarts != bStarts) {
            return aStarts ? -1 : 1;
          }
          return aTitle.compareTo(bTitle);
        });
        _filteredSongs = matches;
      }
    });
  }

  void _showNotFound() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Not found'),
          content: const Text('We couldn\'t match that search to a podcast.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasQuery = _currentQuery.isNotEmpty;
    final hasRecent = recentSearches.isNotEmpty;
    return Scaffold(
      backgroundColor: WhistilPalette.background,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                color: WhistilPalette.textPrimary,
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Find a podcast episode',
              style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: WhistilPalette.textPrimary,
                  ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: WhistilGradients.card,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: WhistilPalette.primary.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: _handleSearch,
                onChanged: (value) {
                  _onQueryChanged(value);
                },
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Try "Motivation"',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: hasQuery
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _onQueryChanged('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (hasQuery)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: _filteredSongs.isNotEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _filteredSongs
                            .map(
                              (song) => _SearchResultTile(
                                song: song,
                                onTap: () => _openSong(song),
                              ),
                            )
                            .toList(),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'No matches found.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                                color: WhistilPalette.textSecondary,
                              ),
                        ),
                      ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Recent searches',
                              style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: WhistilPalette.textPrimary,
                                  ),
                            ),
                          ),
                          if (hasRecent)
                            TextButton(
                              onPressed: clearRecentSearches,
                              child: const Text('Clear all'),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (hasRecent)
                      ...recentSearches.map((entry) {
                        final matchedSong = entry.resolveSong();
                        return _RecentSearchTile(
                          entry: entry,
                          song: matchedSong,
                          onRemove: () => removeRecentSearch(entry),
                          onTap: () {
                            if (matchedSong != null) {
                              _openSong(matchedSong);
                            } else {
                              _handleSearch(entry.title);
                            }
                          },
                        );
                      }).toList()
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'No search history yet.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                                color: WhistilPalette.textSecondary,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.song,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                song.coverUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: WhistilPalette.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                          color: WhistilPalette.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: WhistilPalette.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: WhistilPalette.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentSearchTile extends StatelessWidget {
  final _RecentSearchEntry entry;
  final Song? song;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _RecentSearchTile({
    required this.entry,
    required this.song,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: entry.coverUrl.isEmpty
                    ? WhistilPalette.primarySoft.withOpacity(0.35)
                    : null,
                image: entry.coverUrl.isNotEmpty
                    ? DecorationImage(
                        image: AssetImage(entry.coverUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: entry.coverUrl.isEmpty
                  ? const Icon(Icons.history_rounded, color: Colors.white70)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: WhistilPalette.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (entry.subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        entry.subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: WhistilPalette.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              color: WhistilPalette.textSecondary,
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentSearchEntry {
  const _RecentSearchEntry({
    required this.documentId,
    required this.songId,
    required this.title,
    required this.subtitle,
    required this.coverUrl,
  });

  final String documentId;
  final String songId;
  final String title;
  final String subtitle;
  final String coverUrl;

  factory _RecentSearchEntry.fromSong(Song song, {String? documentId}) {
    return _RecentSearchEntry(
      documentId: documentId ?? song.id,
      songId: song.id,
      title: song.title,
      subtitle: song.description,
      coverUrl: song.coverUrl,
    );
  }

  Song? resolveSong() {
    return Song.songs.firstWhereOrNull((candidate) {
      if (candidate.id == songId) return true;
      if (candidate.title.toLowerCase() == title.toLowerCase()) return true;
      return false;
    });
  }
}
