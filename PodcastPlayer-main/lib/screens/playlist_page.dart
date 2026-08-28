import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:podcastplayer/models/playlist_model.dart';
import 'package:podcastplayer/models/songs_model.dart';
import 'package:podcastplayer/screens/play_page.dart';
import 'package:podcastplayer/theme/app_theme.dart';

class PlaylistPage extends StatefulWidget {
  PlaylistPage({required this.playlist});

  final Playlist playlist;

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  late final User _user;
  late final bool _isUserPlaylist;
  late List<Song> _songs;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _hasChanges = false;
  bool _isUploadingCover = false;
  final ImagePicker _imagePicker = ImagePicker();

  bool get _canEditPlaylist => _isUserPlaylist && widget.playlist.id.isNotEmpty;
  bool get _canChangeCover => _canEditPlaylist && _isEditing && !_isUploadingCover;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
    _isUserPlaylist = widget.playlist.isUserGenerated;
    _songs = List<Song>.from(widget.playlist.songs);
    _checkPlaylistLike();
    for (final song in _songs) {
      _checkSongLike(song);
    }
  }

  Future<void> _checkSongLike(Song song) async {
    final userFavoritePodcastsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('favorite_podcasts');

    final favoriteSnapshot = await userFavoritePodcastsRef.doc(song.id).get();
    if (!mounted) return;

    setState(() {
      song.isFavorite = favoriteSnapshot.exists;
    });
  }

  Future<void> _checkPlaylistLike() async {
    final userFavoritePlaylistsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('favorite_playlists');

    final favoriteSnapshot =
        await userFavoritePlaylistsRef.doc(widget.playlist.id).get();
    if (!mounted) return;

    setState(() {
      widget.playlist.isLiked = favoriteSnapshot.exists;
    });
  }

  Future<void> _toggleFavorite(Song song) async {
    final userFavoritePodcastsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('favorite_podcasts');

    final isFavorite = song.isFavorite;
    setState(() {
      song.isFavorite = !song.isFavorite;
    });

    try {
      if (isFavorite) {
        await userFavoritePodcastsRef.doc(song.id).delete();
      } else {
        await userFavoritePodcastsRef.doc(song.id).set(song.toJson());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        song.isFavorite = isFavorite;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update favorites.')),
      );
    }
  }

  Future<void> _togglePlaylistLike() async {
    final userFavoritePlaylistsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('favorite_playlists');

    final isLiked = widget.playlist.isLiked;
    setState(() {
      widget.playlist.isLiked = !widget.playlist.isLiked;
    });

    try {
      if (isLiked) {
        await userFavoritePlaylistsRef.doc(widget.playlist.id).delete();
      } else {
        await userFavoritePlaylistsRef
            .doc(widget.playlist.id)
            .set(widget.playlist.toJson());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          widget.playlist.isLiked = isLiked;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update favorite playlists.')),
      );
    }
  }

  Future<void> _toggleEditing() async {
    if (!_canEditPlaylist) return;

    if (_isEditing && _hasChanges) {
      final shouldDiscard = await _confirmDiscardChanges();
      if (!shouldDiscard) return;
      setState(() {
        _songs = List<Song>.from(widget.playlist.songs);
        _hasChanges = false;
        _isEditing = false;
      });
      return;
    }

    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _songs = List<Song>.from(widget.playlist.songs);
        _hasChanges = false;
      }
    });
  }

  Future<bool> _confirmDiscardChanges() async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Discard changes?'),
              content: const Text(
                'You have unsaved changes. Do you want to discard them?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Keep editing'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Discard'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _handleReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    setState(() {
      final song = _songs.removeAt(oldIndex);
      _songs.insert(newIndex, song);
      _hasChanges = true;
    });
  }

  void _removeSong(int index) {
    setState(() {
      _songs.removeAt(index);
      _hasChanges = true;
    });
  }

  Future<void> _saveChanges() async {
    if (!_canEditPlaylist || !_hasChanges) return;

    setState(() {
      _isSaving = true;
    });

    final playlistsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('playlists');

    try {
      await playlistsRef.doc(widget.playlist.id).update({
        'songs': _songs.map((song) => song.toJson()).toList(),
      });

      if (!mounted) return;
      setState(() {
        widget.playlist.songs
          ..clear()
          ..addAll(_songs);
        _hasChanges = false;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playlist updated')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update playlist.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _openSong(Song song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayPage(song: song),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WhistilPalette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: WhistilPalette.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.playlist.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.playlist.isLiked
                  ? Icons.favorite
                  : Icons.favorite_border,
            ),
            color: widget.playlist.isLiked
                ? Color.fromARGB(222, 150, 85, 196)
                : WhistilPalette.textSecondary,
            onPressed: _togglePlaylistLike,
          ),
          if (_canEditPlaylist)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              color: WhistilPalette.textPrimary,
              onPressed: _toggleEditing,
              tooltip: _isEditing ? 'Cancel editing' : 'Edit playlist',
            ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            if (_isEditing)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: _buildEditingBanner(context),
                ),
              ),
            _buildSongSliver(context),
            if (_isEditing)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: _buildSaveButtonContent(context),
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: WhistilGradients.card,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: WhistilPalette.primary.withOpacity(0.08),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildCoverImage(widget.playlist.coverUrl),
                    if (_canChangeCover)
                      Material(
                        color: Colors.black.withOpacity(_isUploadingCover ? 0.45 : 0.25),
                        child: InkWell(
                          onTap: _changeCoverImage,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.camera_alt, color: Colors.white),
                                const SizedBox(height: 6),
                                Text(
                                  _isUploadingCover ? 'Loading...' : 'Change picture',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (_isUploadingCover)
                      const Center(
                        child: SizedBox(
                          height: 32,
                          width: 32,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditingBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: WhistilPalette.primarySoft.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: WhistilPalette.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Drag the handle to reorder podcasts, or remove ones you no longer want.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: WhistilPalette.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongSliver(BuildContext context) {
    if (_songs.isEmpty) {
      return _buildEmptySliver(context);
    }

    if (_isEditing) {
      return _buildEditableSliverList();
    }

    return _buildReadOnlySliverList();
  }

  SliverPadding _buildReadOnlySliverList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final song = _songs[index];
            return Padding(
              padding: EdgeInsets.only(bottom: index == _songs.length - 1 ? 0 : 12),
              child: GestureDetector(
                onTap: () => _openSong(song),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 22,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(
                          song.coverUrl,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              song.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              song.description,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: WhistilPalette.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: Icon(
                          song.isFavorite ? Icons.favorite : Icons.favorite_border,
                        ),
                        color: song.isFavorite
                            ? WhistilPalette.primary
                            : WhistilPalette.textSecondary,
                        onPressed: () => _toggleFavorite(song),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: _songs.length,
        ),
      ),
    );
  }

  SliverPadding _buildEditableSliverList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      sliver: SliverReorderableList(
        itemCount: _songs.length,
        onReorder: _handleReorder,
        itemBuilder: (context, index) {
          final song = _songs[index];
          return Container(
            key: ValueKey(song.id),
            margin: EdgeInsets.only(bottom: index == _songs.length - 1 ? 0 : 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: const Icon(
                      Icons.drag_indicator,
                      color: WhistilPalette.textSecondary,
                    ),
                  ),
                ),
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
                    children: [
                      Text(
                        song.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: WhistilPalette.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: WhistilPalette.textSecondary,
                  onPressed: () => _removeSong(index),
                  tooltip: 'Remove from playlist',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptySliver(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.playlist_play,
                color: WhistilPalette.textSecondary.withOpacity(0.6),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _isUserPlaylist
                    ? 'This playlist is feeling lonely.'
                    : 'No podcasts in this playlist yet.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isUserPlaylist
                    ? 'Add podcasts from the player to start filling it up.'
                    : 'Check back later for curated selections.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: WhistilPalette.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButtonContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: WhistilGradients.button,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: WhistilPalette.primary.withOpacity(0.18),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: !_hasChanges || _isSaving ? null : () => _saveChanges(),
            style: ElevatedButton.styleFrom(
              foregroundColor: WhistilPalette.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save changes'),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _hasChanges
              ? 'Tap save to keep your new order.'
              : 'Make adjustments to enable saving.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: WhistilPalette.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _changeCoverImage() async {
    if (!_canChangeCover || widget.playlist.id.isEmpty) return;

    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) {
      return;
    }

    setState(() {
      _isUploadingCover = true;
    });

    try {
      final file = File(pickedFile.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('playlist_covers')
          .child(_user.uid)
          .child('${widget.playlist.id}.jpg');

      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .collection('playlists')
          .doc(widget.playlist.id)
          .update({'coverUrl': downloadUrl});

      if (!mounted) return;
      setState(() {
        widget.playlist.coverUrl = downloadUrl;
        _isUploadingCover = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playlist cover updated')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingCover = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update cover image.')),
      );
    }
  }

  Widget _buildCoverImage(String url) {
    if (url.isEmpty) {
      return Image.asset(
        'assets/images/myplaylistpp.png',
        fit: BoxFit.cover,
      );
    }

    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/myplaylistpp.png',
          fit: BoxFit.cover,
        ),
      );
    }

    return Image.asset(
      url,
      fit: BoxFit.cover,
    );
  }
}