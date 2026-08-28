class Song {
  final String id;
  final String title;
  final String description;
  final String url;
  final String coverUrl;
  final String link;
  final List<String> playlists;
  bool isFavorite;

  Song({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.coverUrl,
    required this.link,
    required this.playlists,
    this.isFavorite = false,
  });

  void toggleFavorite() {
    isFavorite = !isFavorite;
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      coverUrl: json['coverUrl'] ?? '',
      link: json['link'] ?? '',
      playlists: List<String>.from(json['playlists'] ?? []),
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'url': url,
      'coverUrl': coverUrl,
      'link': link,
      'playlists': playlists,
      'isFavorite': isFavorite,
    };
  }

  static List<Song> songs = [
    Song(
      id: '1',
      title: 'Motivation',
      description: 'Jocko Willink',
      url: 'assets/music/fail.mp3',
      coverUrl: 'assets/images/motivation.png',
      link: 'https://whistil.com/motivation-jocko-willink',
      playlists: ['General', 'Waste'],
    ),
    Song(
      id: '2',
      title: 'Danger of Silence',
      description: 'Clint Smith',
      url: 'assets/music/danger.mp3',
      coverUrl: 'assets/images/danger.png',
      link: 'https://whistil.com/danger-of-silence-clint-smith',
      playlists: ['General', 'Waste', 'Environment'],
    ),
    Song(
      id: '3',
      title: 'Dont Waste Time',
      description: 'Jim Kwik',
      url: 'assets/music/waste.mp3',
      coverUrl: 'assets/images/waste.png',
      link: 'https://whistil.com/dont-wast-time-jim-kwik',
      playlists: ['Dream', 'General', 'Personal'],
    ),
    Song(
      id: '4',
      title: 'Follow Dreams',
      description: 'Neil and Beth',
      url: 'assets/music/dream.mp3',
      coverUrl: 'assets/images/dream.png',
      link: 'https://whistil.com/follow-dreams-neil-and-beth',
      playlists: ['Dream', 'General'],
    ),
    Song(
      id: '5',
      title: '5 Minute Rule',
      description: 'Matt DAvella',
      url: 'assets/music/5minute.mp3',
      coverUrl: 'assets/images/5minute.png',
      link: 'https://whistil.com/follow-5minute-5minute',
      playlists: ['Dream', 'General'],
    ),
    Song(
      id: '6',
      title: 'Keep Your Goals',
      description: 'Derek Sivers',
      url: 'assets/music/keepgoals.mp3',
      coverUrl: 'assets/images/tedx.png',
      link: 'https://whistil.com/follow-keepgoals-derek-sivers',
      playlists: ['Dream', 'General', 'Personal'],
    ),
    Song(
      id: '7',
      title: 'Try Something New',
      description: 'Matt Cutts',
      url: 'assets/music/try.mp3',
      coverUrl: 'assets/images/tedx1.png',
      link: 'https://whistil.com/follow-try-something',
      playlists: ['Lookup', 'General'],
    ),
    Song(
      id: '8',
      title: 'Self İmprovement',
      description: 'Brendan Clark',
      url: 'assets/music/self.mp3',
      coverUrl: 'assets/images/self.png',
      link: 'https://whistil.com/follow-self-self',
      playlists: ['Dream', 'General', 'Personal'],
    ),
    Song(
      id: '9',
      title: 'The Importance of Books',
      description: 'Luke Bakic',
      url: 'assets/music/book.mp3',
      coverUrl: 'assets/images/book.png',
      link: 'https://whistil.com/follow-book-book',
      playlists: ['Lookup', 'General', 'Personal'],
    ),
    Song(
      id: '10',
      title: 'Overcome Fears',
      description: 'Danish Dhamani',
      url: 'assets/music/fear.mp3',
      coverUrl: 'assets/images/fear.png',
      link: 'https://whistil.com/follow-overcome-fears-danish-dhamani',
      playlists: ['Lookup', 'General'],
    ),
    Song(
      id: '11',
      title: 'Food and Mood',
      description: 'BBC ENGLİSH',
      url: 'assets/music/food.mp3',
      coverUrl: 'assets/images/food.png',
      link: 'https://whistil.com/follow-foodandmood-bbc',
      playlists: ['Lookup', 'General'],
    ),
    Song(
      id: '12',
      title: 'Social Media and Teenage',
      description: 'BBC ENGLİSH',
      url: 'assets/music/social.mp3',
      coverUrl: 'assets/images/social.png',
      link: 'https://whistil.com/follow-socialmedia-teenagers-bbc',
      playlists: ['Lookup', 'General'],
    ),
    Song(
      id: '13',
      title: 'Stundent and Mental health',
      description: 'Hailey Hardcastle',
      url: 'assets/music/mental.mp3',
      coverUrl: 'assets/images/mental.png',
      link: 'https://whistil.com/follow-studentmental-hailey-hardcastle',
      playlists: ['Lookup', 'General'],
    ),
    Song(
      id: '14',
      title: 'Future of Work',
      description: 'BBC ENGLİSH',
      url: 'assets/music/future.mp3',
      coverUrl: 'assets/images/future.png',
      link: 'https://whistil.com/follow-future-of-work-bbc',
      playlists: ['Lookup', 'General', 'Environment'],
    ),
    Song(
      id: '15',
      title: 'Live without Plastic',
      description: 'BBC ENGLİSH',
      url: 'assets/music/plastic.mp3',
      coverUrl: 'assets/images/plastic.png',
      link: 'https://whistil.com/follow-live-without-plastic-bbc',
      playlists: ['Lookup', 'General', 'Environment'],
    ),
  ];
}
