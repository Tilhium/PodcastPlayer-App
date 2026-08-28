import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:podcastplayer/models/playlist_model.dart';
import 'package:podcastplayer/models/songs_model.dart';
import 'package:podcastplayer/screens/library_page.dart';
import 'package:podcastplayer/theme/app_theme.dart';
import 'package:podcastplayer/widgets/gradient_button.dart';

class CreatePlaylistPage extends StatefulWidget {
  final String name;
  final String email;
  final DateTime birthDate;
  final String profileImagePath;

  CreatePlaylistPage({
    required this.name,
    required this.email,
    required this.birthDate,
    required this.profileImagePath,
  });

  @override
  _CreatePlaylistPageState createState() => _CreatePlaylistPageState();
}

class _CreatePlaylistPageState extends State<CreatePlaylistPage> {
  final TextEditingController _playlistNameController = TextEditingController();
  final List<Song> _selectedSongs = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _playlistNameController.dispose();
    super.dispose();
  }

  void _toggleSongSelection(Song song) {
    setState(() {
      if (_selectedSongs.contains(song)) {
        _selectedSongs.remove(song);
      } else {
        _selectedSongs.add(song);
      }
    });
  }

  Future<void> _createPlaylist() async {
    final playlistName = _playlistNameController.text.trim();
    if (playlistName.isEmpty || _selectedSongs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please name the playlist and pick at least one podcast.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userPlaylistsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('playlists');

      final newPlaylist = Playlist(
        id: '',
        title: playlistName,
        coverUrl: 'assets/images/myplaylistpp.png',
        songs: List<Song>.from(_selectedSongs),
        isLiked: false,
        isUserGenerated: true,
      );

      final playlistRef = await userPlaylistsRef.add(newPlaylist.toJson());
      await playlistRef.update({'id': playlistRef.id});

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LibraryPage(
            name: widget.name,
            email: widget.email,
            birthDate: widget.birthDate,
            profileImagePath: widget.profileImagePath,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not create playlist. Try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: WhistilPalette.background,
      appBar: AppBar(
        title: const Text('Create playlist'),
      ),
      body: SafeArea(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: WhistilGradients.background,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderCard(
                  controller: _playlistNameController,
                  selectedCount: _selectedSongs.length,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _SongSelectionList(
                    songs: Song.songs,
                    selectedSongs: _selectedSongs,
                    onSongTapped: _toggleSongSelection,
                  ),
                ),
                const SizedBox(height: 24),
                GradientButton(
                  label: _isSubmitting ? 'Creating playlist…' : 'Create playlist',
                  onPressed: _isSubmitting ? () {} : _createPlaylist,
                  leading: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : null,
                ),
                const SizedBox(height: 24),
                Text(
                  'You can edit playlists later from your Library.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: WhistilPalette.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final TextEditingController controller;
  final int selectedCount;

  const _HeaderCard({
    required this.controller,
    required this.selectedCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: WhistilGradients.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: WhistilPalette.primary.withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Name your playlist', style: titleStyle),
          const SizedBox(height: 12),
          Text(
            'Pick podcasts that match the vibe you want, then hit create when you’re ready.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: WhistilPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Playlist name',
              prefixIcon: Icon(Icons.edit_outlined),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: WhistilPalette.primarySoft.withOpacity(0.55),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.queue_music,
                  size: 18,
                  color: WhistilPalette.primary.withOpacity(0.9),
                ),
                const SizedBox(width: 8),
                Text(
                  selectedCount == 0
                      ? 'No podcasts selected yet'
                      : '$selectedCount podcast${selectedCount == 1 ? '' : 's'} selected',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: WhistilPalette.textPrimary,
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

class _SongSelectionList extends StatelessWidget {
  final List<Song> songs;
  final List<Song> selectedSongs;
  final ValueChanged<Song> onSongTapped;

  const _SongSelectionList({
    required this.songs,
    required this.selectedSongs,
    required this.onSongTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Scrollbar(
        thickness: 4,
        radius: const Radius.circular(12),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final song = songs[index];
            final isSelected = selectedSongs.contains(song);
            return _SongTile(
              song: song,
              isSelected: isSelected,
              onTap: () => onSongTapped(song),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: songs.length,
        ),
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  final Song song;
  final bool isSelected;
  final VoidCallback onTap;

  const _SongTile({
    required this.song,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              gradient: WhistilGradients.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected
                    ? WhistilPalette.primary.withOpacity(0.45)
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? WhistilPalette.primary.withOpacity(0.18)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: isSelected ? 24 : 16,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    song.coverUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        song.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        song.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: WhistilPalette.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? WhistilPalette.primary.withOpacity(0.12)
                        : WhistilPalette.primarySoft.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? WhistilPalette.primary
                          : WhistilPalette.primarySoft,
                    ),
                  ),
                  child: Icon(
                    isSelected ? Icons.check_rounded : Icons.add_rounded,
                    color: isSelected
                        ? WhistilPalette.primary
                        : WhistilPalette.primaryMuted,
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
