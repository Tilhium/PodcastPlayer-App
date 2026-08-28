import 'package:podcastplayer/models/songs_model.dart';

class Playlist {
  String id;
  final String title;
  final List<Song> songs;
  String coverUrl;
  bool isLiked;
  final bool isUserGenerated;

  Playlist({
    required this.id,
    required this.title,
    required this.songs,
    required this.coverUrl,
    this.isLiked = false,
    this.isUserGenerated = false,
  });

  void toggleLike() {
    isLiked = !isLiked;
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      songs: (json['songs'] as List<dynamic>)
          .map((e) => Song.fromJson(e as Map<String, dynamic>))
          .toList(),
      coverUrl: json['coverUrl'] ?? '',
      isLiked: json['isLiked'] ?? false,
      isUserGenerated: json['isUserGenerated'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'songs': songs.map((song) => song.toJson()).toList(),
      'coverUrl': coverUrl,
      'isLiked': isLiked,
      'isUserGenerated': isUserGenerated,
    };
  }

  static List<Playlist> playlists = [
    Playlist(
      id: '1',
      title: 'General',
      songs: Song.songs
          .where((song) => song.playlists.contains('General'))
          .toList(),
      coverUrl: 'assets/images/tumbnail1.jpeg',
      isUserGenerated: false,
    ),
    Playlist(
      id: '2',
      title: 'Dream',
      songs:
          Song.songs.where((song) => song.playlists.contains('Dream')).toList(),
      coverUrl: 'assets/images/tumbnail2.jpeg',
      isUserGenerated: false,
    ),
    Playlist(
      id: '3',
      title: 'Waste',
      songs:
          Song.songs.where((song) => song.playlists.contains('Waste')).toList(),
      coverUrl: 'assets/images/tumbnail3.jpeg',
      isUserGenerated: false,
    ),
    Playlist(
      id: '4',
      title: 'Look Up',
      songs: Song.songs
          .where((song) => song.playlists.contains('Lookup'))
          .toList(),
      coverUrl: 'assets/images/tumbnail4.jpeg',
      isUserGenerated: false,
    ),
    Playlist(
      id: '5',
      title: 'Personal',
      songs: Song.songs
          .where((song) => song.playlists.contains('Personal'))
          .toList(),
      coverUrl: 'assets/images/tumbnail5.jpeg',
      isUserGenerated: false,
    ),
    Playlist(
      id: '6',
      title: 'Environment',
      songs: Song.songs
          .where((song) => song.playlists.contains('Environment'))
          .toList(),
      coverUrl: 'assets/images/tumbnail6.jpeg',
      isUserGenerated: false,
    ),
  ];
}
