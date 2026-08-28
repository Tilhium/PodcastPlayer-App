import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:podcastplayer/models/playlist_model.dart';
import 'package:podcastplayer/models/songs_model.dart';
import 'package:podcastplayer/screens/playlist_page.dart';
import 'package:podcastplayer/screens/play_page.dart';
import 'package:podcastplayer/screens/home_page.dart';
import 'package:podcastplayer/screens/profile_page.dart';
import 'package:podcastplayer/screens/create_playlist_page.dart';
import 'package:podcastplayer/theme/app_theme.dart';
import 'package:podcastplayer/utils/navigation_helpers.dart';
import 'package:podcastplayer/widgets/app_bottom_nav.dart';
import 'package:podcastplayer/widgets/gradient_button.dart';

class LibraryPage extends StatefulWidget {
  final String name;
  final String email;
  final DateTime birthDate;
  final String profileImagePath;

  LibraryPage({
    required this.name,
    required this.email,
    required this.birthDate,
    required this.profileImagePath,
  });

  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  late User _user;
  List<Playlist> likedPlaylists = [];
  List<Playlist> _userCreatedPlaylists = [];
  List<Song> favoriteSongs = [];
  bool _isLoadingFavoriteSongs = true;
  bool _isLoadingFavoritePlaylists = true;
  bool _isLoadingUserPlaylists = true;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;

    _loadUserPlaylists();
    _loadFavoritePodcasts();
    _loadFavoritePlaylists();
  }

  Future<void> _loadUserPlaylists() async {
    setState(() => _isLoadingUserPlaylists = true);

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(_user.uid);
      final playlistsRef = userRef.collection('playlists');
      final snapshot = await playlistsRef.get();

      setState(() {
        _userCreatedPlaylists = snapshot.docs.map((doc) {
          final data = doc.data();
          return Playlist(
            id: doc.id,
            title: data['title'] ?? '',
            songs: (data['songs'] as List<dynamic>?)
                    ?.map((song) => Song.fromJson(song as Map<String, dynamic>))
                    .toList() ??
                [],
            coverUrl: data['coverUrl'] ?? '',
            isLiked: data['isLiked'] ?? false,
            isUserGenerated: data['isUserGenerated'] ?? true,
          );
        }).toList();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingUserPlaylists = false);
      }
    }
  }

  Future<void> _loadFavoritePodcasts() async {
    setState(() => _isLoadingFavoriteSongs = true);

    try {
      final userFavoritePodcastsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .collection('favorite_podcasts');
      final snapshot = await userFavoritePodcastsRef.get();

      setState(() {
        favoriteSongs = snapshot.docs.map((doc) {
          final data = doc.data();
          return Song.fromJson(data as Map<String, dynamic>);
        }).toList();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingFavoriteSongs = false);
      }
    }
  }

  Future<void> _loadFavoritePlaylists() async {
    setState(() => _isLoadingFavoritePlaylists = true);

    try {
      final userFavoritePlaylistsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .collection('favorite_playlists');
      final snapshot = await userFavoritePlaylistsRef.get();

      setState(() {
        likedPlaylists = snapshot.docs.map((doc) {
          final data = doc.data();
          return Playlist.fromJson(data as Map<String, dynamic>);
        }).toList();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingFavoritePlaylists = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: WhistilPalette.background,
      appBar: AppBar(
        title: const Text('Your library'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: WhistilGradients.background,
          ),
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                _loadFavoritePodcasts(),
                _loadFavoritePlaylists(),
                _loadUserPlaylists(),
              ]);
            },
            color: WhistilPalette.primary,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saved podcasts',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _FavoritePodcastRail(
                          songs: favoriteSongs,
                          isLoading: _isLoadingFavoriteSongs,
                          onSongTap: (song) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlayPage(song: song),
                              ),
                            );
                          },
                          onRemove: _removeFavoritePodcast,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Favorited playlists',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _FavoritePlaylistRail(
                          playlists: likedPlaylists,
                          isLoading: _isLoadingFavoritePlaylists,
                          onPlaylistTap: (playlist) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlaylistPage(playlist: playlist),
                              ),
                            );
                          },
                          onRemove: _removeFavoritePlaylist,
                        ),
                        const SizedBox(height: 32),
                        _YourPlaylistsHeader(onCreateTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreatePlaylistPage(
                                name: widget.name,
                                email: widget.email,
                                birthDate: widget.birthDate,
                                profileImagePath: widget.profileImagePath,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  sliver: _UserPlaylistGrid(
                    playlists: _userCreatedPlaylists,
                    isLoading: _isLoadingUserPlaylists,
                    onPlaylistTap: (playlist) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlaylistPage(playlist: playlist),
                        ),
                      );
                    },
                    onDeleteTap: _deletePlaylistConfirmation,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: WhistilBottomNav(
        currentIndex: 0,
        onItemSelected: (index) {
          if (index == 0) return;

          if (index == 1) {
            slideToPage(
              context,
              HomePage(
                name: widget.name,
                email: widget.email,
                birthDate: widget.birthDate,
                profileImagePath: widget.profileImagePath,
              ),
              forward: true,
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

  void _removeFavoritePodcast(Song song) {
    setState(() {
      favoriteSongs.remove(song);
    });

    song.toggleFavorite();

    final userFavoritePodcastsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('favorite_podcasts');
    userFavoritePodcastsRef.doc(song.id).delete();
  }

  void _removeFavoritePlaylist(Playlist playlist) {
    setState(() {
      likedPlaylists.remove(playlist);
    });

    playlist.toggleLike();

    final userFavoritePlaylistsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('favorite_playlists');
    userFavoritePlaylistsRef.doc(playlist.id).delete();
  }

  void _deletePlaylistConfirmation(Playlist playlist) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Remove playlist?'),
          content: Text(
            '"${playlist.title}" will be removed from your library.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deletePlaylist(playlist);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deletePlaylist(Playlist playlist) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('playlists')
        .doc(playlist.id)
        .delete();

    setState(() {
      _userCreatedPlaylists.remove(playlist);
    });
  }
}

class _FavoritePodcastRail extends StatelessWidget {
  final List<Song> songs;
  final bool isLoading;
  final ValueChanged<Song> onSongTap;
  final ValueChanged<Song> onRemove;

  const _FavoritePodcastRail({
    required this.songs,
    required this.isLoading,
    required this.onSongTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (songs.isEmpty) {
      return _EmptyRailMessage(
        icon: Icons.favorite_border,
        title: 'No favorite podcasts yet',
        message: 'Tap the heart while listening to keep it here.',
      );
    }

    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: songs.length,
        padding: const EdgeInsets.only(right: 12),
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final song = songs[index];
          return _PodcastFavoriteCard(
            song: song,
            onTap: () => onSongTap(song),
            onRemove: () => onRemove(song),
          );
        },
      ),
    );
  }
}

class _FavoritePlaylistRail extends StatelessWidget {
  final List<Playlist> playlists;
  final bool isLoading;
  final ValueChanged<Playlist> onPlaylistTap;
  final ValueChanged<Playlist> onRemove;

  const _FavoritePlaylistRail({
    required this.playlists,
    required this.isLoading,
    required this.onPlaylistTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (playlists.isEmpty) {
      return _EmptyRailMessage(
        icon: Icons.queue_music,
        title: 'No favorite playlists yet',
        message: 'Explore playlists and tap the heart to save them.',
      );
    }

    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: playlists.length,
        padding: const EdgeInsets.only(right: 12),
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return _PlaylistFavoriteCard(
            playlist: playlist,
            onTap: () => onPlaylistTap(playlist),
            onRemove: () => onRemove(playlist),
          );
        },
      ),
    );
  }
}

class _YourPlaylistsHeader extends StatelessWidget {
  final VoidCallback onCreateTap;

  const _YourPlaylistsHeader({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            'Your playlists',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        GradientButton(
          label: 'New playlist',
          expand: false,
          leading: const Icon(Icons.add, size: 18, color: Colors.white),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
          onPressed: onCreateTap,
        ),
      ],
    );
  }
}

class _UserPlaylistGrid extends StatelessWidget {
  final List<Playlist> playlists;
  final bool isLoading;
  final ValueChanged<Playlist> onPlaylistTap;
  final ValueChanged<Playlist> onDeleteTap;

  const _UserPlaylistGrid({
    required this.playlists,
    required this.isLoading,
    required this.onPlaylistTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (playlists.isEmpty) {
      return const SliverToBoxAdapter(
        child: _EmptyLibraryMessage(),
      );
    }

    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final playlist = playlists[index];
          return _UserPlaylistCard(
            playlist: playlist,
            onTap: () => onPlaylistTap(playlist),
            onDeleteTap: () => onDeleteTap(playlist),
          );
        },
        childCount: playlists.length,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        childAspectRatio: 0.9,
      ),
    );
  }
}

class _PodcastFavoriteCard extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PodcastFavoriteCard({
    required this.song,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: WhistilGradients.card,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                song.coverUrl,
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.55),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.favorite, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    song.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

class _PlaylistFavoriteCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PlaylistFavoriteCard({
    required this.playlist,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: WhistilGradients.card,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                playlist.coverUrl,
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.55),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.favorite, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    playlist.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${playlist.songs.length} podcast${playlist.songs.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
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

class _UserPlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  final VoidCallback onDeleteTap;

  const _UserPlaylistCard({
    required this.playlist,
    required this.onTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(24);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: WhistilGradients.card,
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: WhistilPalette.primary.withOpacity(0.08),
                blurRadius: 22,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    playlist.coverUrl,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.15),
                          Colors.black.withOpacity(0.6),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: onDeleteTap,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.delete_outline, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        playlist.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${playlist.songs.length} podcast${playlist.songs.length == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyRailMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyRailMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 22,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Row(
        children: [
          Icon(icon, color: WhistilPalette.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: WhistilPalette.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLibraryMessage extends StatelessWidget {
  const _EmptyLibraryMessage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.playlist_add,
            color: WhistilPalette.textSecondary.withOpacity(0.6),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No custom playlists yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first playlist to keep episodes together.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: WhistilPalette.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}