import 'package:flutter_dotenv/flutter_dotenv.dart'; // ✅ Already there
import 'package:flutter/material.dart';
import 'package:good_news/responsive_app.dart';
import 'package:good_news/features/authentication/presentation/screens/login_screen.dart';
import 'package:good_news/features/onboarding/presentation/screens/choose_topics_screen.dart';
import 'package:good_news/core/services/preferences_service.dart';
import 'package:good_news/core/services/theme_service.dart';
import 'package:good_news/core/themes/app_theme.dart';

import 'features/splash_screen.dart';

// 🔹 Step 1: main() function updated with dotenv.load()
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔸 .env फाइल लोड करा
  await dotenv.load(fileName: ".env");

  runApp(const GoodNewsApp());
}

class GoodNewsApp extends StatefulWidget {
  const GoodNewsApp({Key? key}) : super(key: key);

  @override
  State<GoodNewsApp> createState() => _GoodNewsAppState();
}

class _GoodNewsAppState extends State<GoodNewsApp> {
  late ThemeService _themeService;

  @override
  void initState() {
    super.initState();
    _themeService = ThemeService();
    _themeService.loadPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeService,
      builder: (context, child) {
        ThemeData lightTheme;
        ThemeData darkTheme;

        if (_themeService.themeType == AppThemeType.green) {
          lightTheme = AppTheme.greenLightTheme;
          darkTheme = AppTheme.greenDarkTheme;
        } else {
          lightTheme = AppTheme.pinkLightTheme;
          darkTheme = AppTheme.pinkDarkTheme;
        }

        return MaterialApp(
          title: 'Good News',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: _themeService.themeMode,
          home: _SplashWrapper(themeService: _themeService),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

// 👇 नवीन Splash Wrapper Widget
class _SplashWrapper extends StatelessWidget {
  final ThemeService themeService;

  const _SplashWrapper({required this.themeService});

  @override
  Widget build(BuildContext context) {
    final bgColor = themeService.isDarkMode
        ? const Color(0xFF1A1A1A)
        : Colors.white;

    final progressColor = themeService.themeType == AppThemeType.green
        ? const Color(0xFF4CAF50)
        : AppTheme.accentPink;

    return FutureBuilder<Widget>(
      future: _determineInitialScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Splash Screen दाखवा
          return SplashScreen(
            nextScreen: const LoginScreen(), // Temporary placeholder
            backgroundColor: bgColor,
            accentColor: progressColor,
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: themeService.isDarkMode ? Colors.black : Colors.white,
            body: Center(
              child: Text("Error loading app"),
            ),
          );
        }

        // जेव्हा initial screen determine झाला
        return SplashScreen(
          nextScreen: snapshot.data ?? const LoginScreen(),
          backgroundColor: bgColor,
          accentColor: progressColor,
        );
      },
    );
  }

  Future<Widget> _determineInitialScreen() async {
    try {
      final isLoggedIn = await PreferencesService.isLoggedIn();

      if (!isLoggedIn) return const LoginScreen();

      final hasCompletedOnboarding =
      await PreferencesService.isOnboardingCompleted();

      if (!hasCompletedOnboarding) return const ChooseTopicsScreen();

      return const ResponsiveApp();
    } catch (e) {
      debugPrint("🔥 Initial Screen Error: $e");
      return const LoginScreen();
    }
  }
}