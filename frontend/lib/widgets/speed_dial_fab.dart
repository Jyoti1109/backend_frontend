import 'package:flutter/material.dart';
import 'package:good_news/core/constants/theme_tokens.dart';

class SpeedDialFAB extends StatefulWidget {
  final List<SpeedDialAction> actions;

  const SpeedDialFAB({
    Key? key,
    required this.actions,
  }) : super(key: key);

  @override
  State<SpeedDialFAB> createState() => _SpeedDialFABState();
}

class _SpeedDialFABState extends State<SpeedDialFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _collapse() {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
        _controller.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Backdrop to detect outside taps
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _collapse,
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),

        // Speed dial actions
        ...widget.actions.asMap().entries.map((entry) {
          final index = entry.key;
          final action = entry.value;
          return AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              final offset = (index + 1) * 70.0 * _expandAnimation.value;
              return Positioned(
                bottom: 16 + offset,
                right: 16,
                child: Transform.scale(
                  scale: _expandAnimation.value,
                  child: Opacity(
                    opacity: _expandAnimation.value,
                    child: _buildSpeedDialItem(action),
                  ),
                ),
              );
            },
          );
        }).toList(),

        // Main FAB with tooltip
        Positioned(
          bottom: 16,
          right: 16,
          child: Tooltip(
            message: _isExpanded ? 'Close menu' : 'Quick actions',
            child: FloatingActionButton(
              onPressed: _toggle,
              backgroundColor: ThemeTokens.primaryGreen,
              child: AnimatedRotation(
                turns: _isExpanded ? 0.125 : 0,
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  _isExpanded ? Icons.close : Icons.add,
                  color: Colors.white,
                  semanticLabel:
                  _isExpanded ? 'Close menu' : 'Open actions menu',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedDialItem(SpeedDialAction action) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label with responsive sizing
        Container(
          constraints: BoxConstraints(
            maxWidth: isSmallScreen ? screenWidth * 0.4 : 200,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12,
            vertical: isSmallScreen ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            action.label,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: isSmallScreen ? 8 : 12),

        // Mini FAB with tooltip and unique heroTag
        Tooltip(
          message: action.label,
          child: SizedBox(
            width: 40,
            height: 40,
            child: FloatingActionButton(
              heroTag: action.heroTag ?? UniqueKey(), // ✅ Fix
              onPressed: () {
                _collapse();
                action.onPressed();
              },
              backgroundColor: ThemeTokens.primaryGreen,
              mini: true,
              child: Icon(
                action.icon,
                color: Colors.white,
                size: 20,
                semanticLabel: action.semanticLabel ?? action.label,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SpeedDialAction {
  final IconData icon;
  final String label;
  final String? semanticLabel;
  final VoidCallback onPressed;
  final Object? heroTag; // ✅ Added to fix heroTag error

  const SpeedDialAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
    this.heroTag,
  });
}
