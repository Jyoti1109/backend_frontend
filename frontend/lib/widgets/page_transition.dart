import 'package:flutter/material.dart';
import 'package:good_news/core/services/theme_service.dart';

class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final Offset beginOffset;

  FadeSlidePageRoute({
    required this.child,
    this.beginOffset = const Offset(1.0, 0.0),
  }) : super(
          transitionDuration: ThemeService().getAnimationDuration(
            const Duration(milliseconds: 300)
          ),
          reverseTransitionDuration: ThemeService().getAnimationDuration(
            const Duration(milliseconds: 300)
          ),
          pageBuilder: (context, animation, secondaryAnimation) => child,
        );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (ThemeService().reduceMotion) {
      return child;
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: beginOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}

class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  ScalePageRoute({required this.child})
      : super(
          transitionDuration: ThemeService().getAnimationDuration(
            const Duration(milliseconds: 250)
          ),
          reverseTransitionDuration: ThemeService().getAnimationDuration(
            const Duration(milliseconds: 250)
          ),
          pageBuilder: (context, animation, secondaryAnimation) => child,
        );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (ThemeService().reduceMotion) {
      return child;
    }

    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}