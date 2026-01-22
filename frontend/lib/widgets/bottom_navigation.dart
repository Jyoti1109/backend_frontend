// import 'package:flutter/material.dart';
// import 'package:good_news/features/articles/presentation/screens/home_screen.dart';
// import 'package:good_news/features/articles/presentation/screens/categories_screen.dart';
// import 'package:good_news/features/social/presentation/screens/social_screen.dart';
// import 'package:good_news/features/profile/presentation/screens/profile_screen.dart';
//
// class MainNavigationScreen extends StatefulWidget {
//   const MainNavigationScreen({Key? key}) : super(key: key);
//
//   @override
//   State<MainNavigationScreen> createState() => _MainNavigationScreenState();
// }
//
// class _MainNavigationScreenState extends State<MainNavigationScreen> {
//   int _currentIndex = 0;
//
//   final List<Widget> _screens = [
//     const HomeScreen(),
//     const CategoriesScreen(),
//     const SocialScreen(),
//     //const ProfileScreen(),
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _screens[_currentIndex],
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           boxShadow: [
//             BoxShadow(
//               color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
//               blurRadius: 8,
//               offset: const Offset(0, -2),
//             ),
//           ],
//         ),
//         child: BottomNavigationBar(
//           type: BottomNavigationBarType.fixed,
//           currentIndex: _currentIndex,
//           onTap: (index) {
//             setState(() {
//               _currentIndex = index;
//             });
//             // Haptic feedback for better UX
//             // HapticFeedback.lightImpact();
//           },
//           selectedItemColor: Theme.of(context).colorScheme.primary,
//           unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
//           selectedLabelStyle: const TextStyle(
//             fontWeight: FontWeight.w600,
//             fontSize: 12,
//           ),
//           unselectedLabelStyle: const TextStyle(
//             fontWeight: FontWeight.w500,
//             fontSize: 11,
//           ),
//           items: [
//             BottomNavigationBarItem(
//               icon: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 24),
//                 child: Icon(Icons.home_outlined, size: 20),
//               ),
//               activeIcon: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 24),
//                 child: Icon(
//                   Icons.home,
//                   size: 20,
//                   color: Theme.of(context).colorScheme.primary,
//                 ),
//               ),
//               label: 'Home',
//             ),
//             BottomNavigationBarItem(
//               icon: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 24),
//                 child: Icon(Icons.category_outlined, size: 20),
//               ),
//               activeIcon: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 24),
//                 child: Icon(
//                   Icons.category,
//                   size: 20,
//                   color: Theme.of(context).colorScheme.primary,
//                 ),
//               ),
//               label: 'Categories',
//             ),
//             BottomNavigationBarItem(
//               icon: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 24),
//                 child: Icon(Icons.people_outline, size: 20),
//               ),
//               activeIcon: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 24),
//                 child: Icon(
//                   Icons.people,
//                   size: 20,
//                   color: Theme.of(context).colorScheme.primary,
//                 ),
//               ),
//               label: 'Social',
//             ),
//             BottomNavigationBarItem(
//               icon: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 24),
//                 child: Icon(Icons.person_outline, size: 20),
//               ),
//               activeIcon: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 24),
//                 child: Icon(
//                   Icons.person,
//                   size: 20,
//                   color: Theme.of(context).colorScheme.primary,
//                 ),
//               ),
//               label: 'Profile',
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }