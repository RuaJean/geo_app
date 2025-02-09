import 'package:flutter/material.dart';
import '../presentation/pages/landing_page.dart';
import '../presentation/pages/home_page.dart';
import '../presentation/widgets/videos_list_page.dart';

class AppRoutes {
  static const initialRoute = '/';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      '/': (context) => const MainPage(),
      '/record': (context) => const HomePage(),
      '/videos': (context) => const VideosListPage(),
    };
  }
}
