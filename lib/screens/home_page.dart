import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:podcastplayer/models/playlist_model.dart';
import 'package:podcastplayer/models/songs_model.dart';
import 'package:podcastplayer/screens/library_page.dart';
import 'package:podcastplayer/screens/play_page.dart';
import 'package:podcastplayer/screens/playlist_page.dart';
import 'package:podcastplayer/screens/profile_page.dart';
import 'package:podcastplayer/screens/search_page.dart';
import 'package:podcastplayer/theme/app_theme.dart';
import 'package:podcastplayer/utils/navigation_helpers.dart';
import 'package:podcastplayer/widgets/app_bottom_nav.dart';

class HomePage extends StatefulWidget {
  final String name;
  final String email;
  final DateTime birthDate;
  final String profileImagePath;

  const HomePage({
    super.key,
    required this.name,
    required this.email,
    required this.birthDate,
    required this.profileImagePath,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Playlist> _userPlaylists = [];
  bool _isLoadingUserPlaylists = false;

  @override
  void initState() {
    super.initState();
    _loadUserPlaylists();
  }

  Future<void> _loadUserPlaylists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoadingUserPlaylists = true);

    try {
      final playlistsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('playlists');
      final snapshot = await playlistsRef.get();

      final fetched = snapshot.docs.map((doc) {
        final data = doc.data();
        final rawSongs = data['songs'] as List<dynamic>? ?? [];
        final cover = (data['coverUrl'] as String?) ?? '';
        return Playlist(
          id: doc.id,
          title: data['title'] ?? '',
          songs: rawSongs
              .map((song) => Song.fromJson(song as Map<String, dynamic>))
              .toList(),
          coverUrl:
              cover.isEmpty ? 'assets/images/tumbnail1.jpeg' : cover,
          isLiked: data['isLiked'] ?? false,
          isUserGenerated: data['isUserGenerated'] ?? true,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _userPlaylists
          ..clear()
          ..addAll(fetched);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load your playlists.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingUserPlaylists = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final songs = Song.songs;
    final playlists = Playlist.playlists;
    final featuredPlaylists = playlists.take(6).toList();

    return Scaffold(
      backgroundColor: WhistilPalette.background,
      extendBody: true,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: _HeroHeader(
                  onSearchTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SearchPage()),
                    );
                  },
                ),
              ),
            ),
            if (songs.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
                  child: const _SectionHeader(
                    title: 'Podcasts',
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 240,
                child: ListView.builder(
                  padding: const EdgeInsets.only(left: 24, right: 8),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return _PodcastCard(
                      song: song,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayPage(song: song),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            if (featuredPlaylists.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
                  child: const _SectionHeader(
                    title: 'Playlists',
                  ),
                ),
              ),
            if (featuredPlaylists.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(left: 24, right: 8),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: featuredPlaylists.length,
                    itemBuilder: (context, index) {
                      final playlist = featuredPlaylists[index];
                      return _PlaylistCard(
                        playlist: playlist,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlaylistPage(playlist: playlist),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
                child: const _SectionHeader(
                  title: 'Your playlists',
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 120),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: _isLoadingUserPlaylists
                      ? const Center(child: CircularProgressIndicator())
                      : _userPlaylists.isEmpty
                          ? Center(
                              child: Text(
                                'Create playlists from your Library to see them here.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: WhistilPalette.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.only(left: 24, right: 8),
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: _userPlaylists.length,
                              itemBuilder: (context, index) {
                                final playlist = _userPlaylists[index];
                                return _PlaylistCard(
                                  playlist: playlist,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PlaylistPage(
                                          playlist: playlist,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: WhistilBottomNav(
        currentIndex: 1,
        onItemSelected: (index) {
          if (index == 1) return;
          if (index == 0) {
            slideToPage(
              context,
              LibraryPage(
                name: widget.name,
                email: widget.email,
                birthDate: widget.birthDate,
                profileImagePath: widget.profileImagePath,
              ),
              forward: false,
            );
          } else if (index == 2) {
            slideToPage(
              context,
              ProfilePage(
                name: widget.name,
                email: widget.email,
                birthDate: widget.birthDate,
                profileImagePath: widget.profileImagePath,
              ),
              forward: true,
            );
          }
        },
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final VoidCallback onSearchTap;

  const _HeroHeader({
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            WhistilPalette.backgroundAccent.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: WhistilPalette.primary.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onSearchTap,
        child: AbsorbPointer(
          child: TextField(
            readOnly: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Search podcasts',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: WhistilPalette.textPrimary,
                ),
          ),
        ),
      ],
    );
  }
}

class _PodcastCard extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;

  const _PodcastCard({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(song.coverUrl, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      song.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;

  const _PlaylistCard({required this.playlist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: WhistilPalette.primary.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                playlist.coverUrl,
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      playlist.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

