import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart' as rxdart;
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:podcastplayer/models/songs_model.dart';
import 'package:podcastplayer/theme/app_theme.dart';
import 'package:podcastplayer/widgets/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlayPage extends StatefulWidget {
  const PlayPage({Key? key, required this.song}) : super(key: key);

  final Song song;

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _CreatePlaylistDialogWidget extends StatefulWidget {
  const _CreatePlaylistDialogWidget({
    super.key,
    required this.playlistsRef,
    required this.song,
  });

  final CollectionReference playlistsRef;
  final Song song;

  @override
  State<_CreatePlaylistDialogWidget> createState() => _CreatePlaylistDialogWidgetState();
}

class _CreatePlaylistDialogWidgetState extends State<_CreatePlaylistDialogWidget> {
  late final TextEditingController _playlistNameController;

  @override
  void initState() {
    super.initState();
    _playlistNameController = TextEditingController();
  }

  @override
  void dispose() {
    _playlistNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _playlistNameController.text.trim().isNotEmpty;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Create new playlist',
        style: TextStyle(
          color: WhistilPalette.primaryMuted,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: TextField(
        controller: _playlistNameController,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Playlist name'),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: TextStyle(color: WhistilPalette.textSecondary),
          ),
        ),
        TextButton(
          onPressed: isValid
              ? () async {
                  final newPlaylist = {
                    'title': _playlistNameController.text.trim(),
                    'coverUrl': 'assets/images/myplaylistpp.png',
                    'songs': [widget.song.toJson()],
                    'isLiked': false,
                    'isUserGenerated': true,
                  };
                  await widget.playlistsRef.add(newPlaylist);
                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
                }
              : null,
          style: TextButton.styleFrom(
            backgroundColor: isValid ? WhistilPalette.primaryMuted : Colors.white,
            foregroundColor: isValid ? Colors.white : WhistilPalette.textSecondary,
          ),
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _PlayPageState extends State<PlayPage> {
  late AudioPlayer audioPlayer;
  late Stream<SeekBarData> _seekBarDataStream;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    _seekBarDataStream = _createSeekBarDataStream();
    _checkFavorite();

    audioPlayer.setAudioSource(
      ConcatenatingAudioSource(
        children: [
          AudioSource.uri(
            Uri.parse('asset:///${widget.song.url}'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  Stream<SeekBarData> _createSeekBarDataStream() {
    return rxdart.Rx.combineLatest2<Duration, Duration?, SeekBarData>(
      audioPlayer.positionStream,
      audioPlayer.durationStream,
      (
        Duration position,
        Duration? duration,
      ) {
        return SeekBarData(
          position,
          duration ?? Duration.zero,
        );
      },
    );
  }

  Future<void> _addToPlaylist(BuildContext context) async {
    final rootContext = context;
    final user = FirebaseAuth.instance.currentUser!;
    final playlistsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('playlists');

    final playlistsSnapshot = await playlistsRef.get();
    final playlistsDocs = playlistsSnapshot.docs;

    if (playlistsDocs.isEmpty) {
      showDialog(
        context: rootContext,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              'No playlists yet',
              style: TextStyle(
                color: WhistilPalette.primaryMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'Create a playlist to save this podcast for later.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: WhistilPalette.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Not now'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await _showCreatePlaylistDialog(rootContext, playlistsRef);
                },
                style: TextButton.styleFrom(
                  backgroundColor: WhistilPalette.background,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Create playlist'),
              ),
            ],
          );
        },
      );
      return;
    }

    final selectedPlaylistIds = <String>{};

    final result = await showDialog<Object?>(
      context: rootContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogStateContext, setState) {
            final maxDialogHeight = MediaQuery.of(rootContext).size.height * 0.55;
            const itemHeight = 88.0;
            const footerHeight = 76.0;
            final desiredHeight = (playlistsDocs.length * itemHeight) + footerHeight;
            final dialogHeight = math.min(maxDialogHeight, desiredHeight);
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
              contentPadding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select playlists',
                    style: TextStyle(
                      color: WhistilPalette.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Add this podcast to one or more collections.',
                    style: TextStyle(
                      color: WhistilPalette.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: dialogHeight,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        physics: const BouncingScrollPhysics(),
                        itemCount: playlistsDocs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final playlistDoc = playlistsDocs[index];
                          final title = '${playlistDoc['title']}';
                          final isSelected = selectedPlaylistIds.contains(playlistDoc.id);
                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedPlaylistIds.remove(playlistDoc.id);
                                } else {
                                  selectedPlaylistIds.add(playlistDoc.id);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: [
                                          WhistilPalette.primarySoft.withOpacity(0.9),
                                          WhistilPalette.primaryMuted.withOpacity(0.9),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: isSelected ? null : Colors.white,
                                border: Border.all(
                                  color: isSelected
                                      ? WhistilPalette.primaryMuted.withOpacity(0.7)
                                      : WhistilPalette.outline,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: WhistilPalette.primaryMuted.withOpacity(0.25),
                                          blurRadius: 18,
                                          offset: const Offset(0, 12),
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 14,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.2)
                                          : WhistilPalette.primarySoft.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.playlist_play,
                                      color: isSelected
                                          ? Colors.white
                                          : WhistilPalette.primaryMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : WhistilPalette.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 220),
                                    child: isSelected
                                        ? const Icon(Icons.check_circle_rounded,
                                            key: ValueKey(true), color: Colors.white)
                                        : Icon(Icons.radio_button_unchecked,
                                            key: const ValueKey(false),
                                            color: WhistilPalette.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext, 'create');
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('New playlist'),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: WhistilPalette.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: selectedPlaylistIds.isEmpty
                      ? null
                      : () {
                          Navigator.pop(dialogContext, Set<String>.from(selectedPlaylistIds));
                        },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    backgroundColor: selectedPlaylistIds.isNotEmpty
                        ? WhistilPalette.primaryMuted
                        : Colors.white,
                    foregroundColor: selectedPlaylistIds.isNotEmpty
                        ? Colors.white
                        : WhistilPalette.textSecondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text('Add podcasts'),
                ),
              ],
            );
          },
        );
      },
    );

if (result == 'create') {
      final created = await _showCreatePlaylistDialog(rootContext, playlistsRef);
      
      if (created == true && mounted) {
        ScaffoldMessenger.of(rootContext).showSnackBar(
          const SnackBar(content: Text('Playlist created')),
        );
      }

      if (mounted) {
        _addToPlaylist(context);
      }
      return;
    }

    if (result is! Set<String> || result.isEmpty) {
      return;
    }

    for (final playlistId in result) {
      final playlistRef = playlistsRef.doc(playlistId);
      final docSnapshot = await playlistRef.get();
      final data = Map<String, dynamic>.from(docSnapshot.data() as Map);
      final existingSongs = (data['songs'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final alreadyAdded = existingSongs.any((song) => song['id'] == widget.song.id);
      if (!alreadyAdded) {
        existingSongs.add(widget.song.toJson());
        await playlistRef.update({'songs': existingSongs});
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(rootContext).showSnackBar(
        const SnackBar(content: Text('Added to playlist')),
      );
    }
  }

  Future<bool> _showCreatePlaylistDialog(
    BuildContext context,
    CollectionReference playlistsRef,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return _CreatePlaylistDialogWidget(
          playlistsRef: playlistsRef,
          song: widget.song,
        );
      },
    );

    return result ?? false;
  }

  void _checkFavorite() async {
    final user = FirebaseAuth.instance.currentUser!;
    final userFavoritePodcastsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorite_podcasts');

    final favoriteSnapshot =
        await userFavoritePodcastsRef.doc(widget.song.id).get();

    setState(() {
      widget.song.isFavorite = favoriteSnapshot.exists;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: _CircleGlassButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _CircleGlassButton(
              icon: Icons.playlist_add,
              onTap: () => _addToPlaylist(context),
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            widget.song.coverUrl,
            fit: BoxFit.cover,
          ),
          const _BackgroundFilter(),
          _MusicPlayer(
            song: widget.song,
            seekBarDataStream: _seekBarDataStream,
            audioPlayer: audioPlayer,
          ),
        ],
      ),
    );
  }
}

class _MusicPlayer extends StatefulWidget {
  const _MusicPlayer({
    Key? key,
    required this.song,
    required this.seekBarDataStream,
    required this.audioPlayer,
  }) : super(key: key);

  final Song song;
  final Stream<SeekBarData> seekBarDataStream;
  final AudioPlayer audioPlayer;

  @override
  _MusicPlayerState createState() => _MusicPlayerState();
}

class _MusicPlayerState extends State<_MusicPlayer> {
  late User _user;

@override
void initState() {
  super.initState();
  _user = FirebaseAuth.instance.currentUser!;
}

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 30.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.song.title,
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: 10),
          Text(
            widget.song.description,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Colors.white),
          ),
          SizedBox(height: 30),
          StreamBuilder<SeekBarData>(
            stream: widget.seekBarDataStream,
            builder: (context, snapshot) {
              final positionData = snapshot.data;
              return SeekBar(
                position: positionData?.position ?? Duration.zero,
                duration: positionData?.duration ?? Duration.zero,
                onChangeEnd: widget.audioPlayer.seek,
              );
            },
          ),
          PlayerButtons(audioPlayer: widget.audioPlayer),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CircleGlassButton(
                icon: widget.song.isFavorite
                    ? Icons.favorite
                    : Icons.favorite_border,
                isActive: widget.song.isFavorite,
                onTap: () => _toggleFavorite(widget.song),
              ),
              _CircleGlassButton(
                icon: Icons.share,
                onTap: () => _showShareSheet(context, widget.song),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showShareSheet(BuildContext context, Song song) {
    final rootContext = context;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ShareOptionsSheet(
          song: song,
          onShare: () async {
            await Share.share(song.link, subject: song.title);
          },
          onCopy: () {
            Clipboard.setData(ClipboardData(text: song.link));
            Navigator.pop(sheetContext);
            ScaffoldMessenger.of(rootContext).showSnackBar(
              const SnackBar(content: Text('Link copied to clipboard')),
            );
          },
        );
      },
    );
  }

void _toggleFavorite(Song song) async {
  final userFavoritePodcastsRef = FirebaseFirestore.instance
      .collection('users')
      .doc(_user.uid)
      .collection('favorite_podcasts');

  if (song.isFavorite) {
    await userFavoritePodcastsRef.doc(song.id).delete();
  } else {
    await userFavoritePodcastsRef.doc(song.id).set(song.toJson());
  }
  
  setState(() {
    song.toggleFavorite();
  });
}
}

class _BackgroundFilter extends StatelessWidget {
  const _BackgroundFilter({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.4),
            Colors.white.withOpacity(0.0),
          ],
          stops: const [
            0.0,
            0.18,
            0.5,
          ],
        ).createShader(rect);
      },
      blendMode: BlendMode.dstOut,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              WhistilPalette.primarySoft.withOpacity(0.75),
              Color.fromARGB(255, 167, 127, 200),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
      ),
    );
  }
}

class _CircleGlassButton extends StatelessWidget {
  const _CircleGlassButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final Color background = isActive
        ? WhistilPalette.primaryMuted.withOpacity(0.85)
        : Colors.white.withOpacity(0.14);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: WhistilPalette.primaryMuted.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.all(14),
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class _ShareOptionsSheet extends StatelessWidget {
  const _ShareOptionsSheet({
    required this.song,
    required this.onShare,
    required this.onCopy,
  });

  final Song song;
  final Future<void> Function() onShare;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 25,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share "${song.title}"',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: WhistilPalette.textPrimary,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              song.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: WhistilPalette.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await onShare();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: WhistilGradients.button,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.ios_share_rounded, color: WhistilPalette.textPrimary),
                          SizedBox(width: 8),
                          Text(
                            'Share',
                            style: TextStyle(color: WhistilPalette.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCopy,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: WhistilPalette.primaryMuted.withOpacity(0.5)),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Copy link'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
