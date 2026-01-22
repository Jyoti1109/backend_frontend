import 'package:flutter/material.dart';
import 'package:good_news/core/services/theme_service.dart';

class AnimatedPostButton extends StatefulWidget {
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback? onPressed;
  final String text;

  const AnimatedPostButton({
    Key? key,
    required this.isEnabled,
    required this.isLoading,
    required this.onPressed,
    this.text = 'Post',
  }) : super(key: key);

  @override
  State<AnimatedPostButton> createState() => _AnimatedPostButtonState();
}

class _AnimatedPostButtonState extends State<AnimatedPostButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(AnimatedPostButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isEnabled != oldWidget.isEnabled) {
      if (widget.isEnabled && !ThemeService().reduceMotion) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isEnabled && !widget.isLoading) {
      _scaleController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();
    
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * 
                 (widget.isEnabled && !themeService.reduceMotion 
                     ? _pulseAnimation.value 
                     : 1.0),
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: AnimatedContainer(
              duration: themeService.getAnimationDuration(
                const Duration(milliseconds: 200)
              ),
              width: widget.isLoading ? 56 : double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: widget.isEnabled
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(
                  widget.isLoading ? 28 : 12
                ),
                boxShadow: widget.isEnabled
                    ? [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.isEnabled && !widget.isLoading 
                      ? widget.onPressed 
                      : null,
                  borderRadius: BorderRadius.circular(
                    widget.isLoading ? 28 : 12
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: themeService.getAnimationDuration(
                        const Duration(milliseconds: 200)
                      ),
                      child: widget.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.text,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16 * themeService.fontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}