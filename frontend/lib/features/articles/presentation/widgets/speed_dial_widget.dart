import 'package:flutter/material.dart';

/// Data class for speed dial action items
class SpeedDialAction {
  final double bottom;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const SpeedDialAction({
    required this.bottom,
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

/// Widget for displaying a speed dial FAB with multiple actions
class SpeedDialWidget extends StatelessWidget {
  final bool isOpen;
  final Animation<double> rotationAnimation;
  final VoidCallback onToggle;
  final List<SpeedDialAction> actions;

  const SpeedDialWidget({
    Key? key,
    required this.isOpen,
    required this.rotationAnimation,
    required this.onToggle,
    required this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // Overlay background when open
        if (isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: onToggle,
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),

        // Speed dial action buttons
        ...actions.map((action) => _buildSpeedDialAction(
          context: context,
          colorScheme: colorScheme,
          action: action,
        )),

        // Main FAB
        Positioned(
          bottom: 100,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'main_fab',
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 6,
            onPressed: onToggle,
            child: AnimatedBuilder(
              animation: rotationAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: rotationAnimation.value * 3.14159 * 2,
                  child: Icon(isOpen ? Icons.close : Icons.add),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedDialAction({
    required BuildContext context,
    required ColorScheme colorScheme,
    required SpeedDialAction action,
  }) {
    return Positioned(
      bottom: action.bottom,
      right: 16,
      child: AnimatedOpacity(
        opacity: isOpen ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                action.label,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Action button
            FloatingActionButton(
              heroTag: 'fab_${action.label}',
              mini: true,
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              onPressed: action.onTap,
              child: Icon(action.icon, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}