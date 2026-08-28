import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:podcastplayer/theme/app_theme.dart';
import 'package:podcastplayer/screens/login_page.dart';
import 'package:podcastplayer/screens/play_page.dart';
import 'package:podcastplayer/screens/search_page.dart';
import 'package:podcastplayer/models/songs_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Whistil',
        theme: whistilTheme(),
        home: LoginPage(),
        getPages: [ // For page routing 
          GetPage(name: '/', page: () => LoginPage()),
          GetPage(name: '/search', page: () => const SearchPage()),
          GetPage(name: '/play', page: () => PlayPage(song: Song.songs[0])),
        ]);
  }
}
