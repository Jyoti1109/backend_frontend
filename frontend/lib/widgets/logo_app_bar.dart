import 'package:flutter/material.dart';
import 'package:good_news/core/constants/theme_tokens.dart';

class LogoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final PreferredSizeWidget? bottom;

  const LogoAppBar({
    Key? key,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.bottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? ThemeTokens.darkBackground,
      foregroundColor: foregroundColor ?? Colors.white,
      elevation: 0,
      leading: _buildLogo(),
      leadingWidth: 180,
      actions: actions,
      bottom: bottom,
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: ThemeTokens.primaryGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.article_outlined,
              color: ThemeTokens.primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Good News',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'Positive stories daily',
                  style: TextStyle(
                    color: ThemeTokens.primaryGreen.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
  );
}

class LogoWatermark extends StatelessWidget {
  final Widget child;
  final double opacity;
  final double size;

  const LogoWatermark({
    Key? key,
    required this.child,
    this.opacity = 0.1,
    this.size = 120,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Center(
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: size,
                height: size,
                decoration: const BoxDecoration(
                  color: ThemeTokens.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: size * 0.6,
                  semanticLabel: 'Good News logo watermark',
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}