import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  final Color backgroundColor;
  final Color accentColor;

  const SplashScreen({
    Key? key,
    required this.nextScreen,
    required this.backgroundColor,
    required this.accentColor,
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Minimum 2.5 seconds splash दाखवा
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // Next screen वर जा
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => widget.nextScreen),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie Animation
            Lottie.asset(
              'assets/splash_animation.json', // तुमच्या JSON file चे नाव
              width: 300,
              height: 300,
              fit: BoxFit.contain,
              controller: _controller,
              onLoaded: (composition) {
                _controller
                  ..duration = composition.duration
                  ..repeat(); // Loop animation
              },
            ),
            const SizedBox(height: 24),
            // App Name
            Text(
              'JOY SCROLL',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: widget.accentColor,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stay Positive, Stay Informed',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}