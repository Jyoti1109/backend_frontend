import 'package:flutter/material.dart';
import 'package:good_news/features/articles/presentation/screens/home_screen.dart';
import 'package:good_news/widgets/bottom_navigation.dart';

class ResponsiveApp extends StatelessWidget {
  const ResponsiveApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // return const MainNavigationScreen();
    return const HomeScreen();
  }
}