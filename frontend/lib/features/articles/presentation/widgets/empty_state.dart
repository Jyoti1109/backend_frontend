import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? assetImage;

  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.assetImage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (assetImage != null)
            Image.asset(
              assetImage!,
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            )
          else if (icon != null)
            Icon(
              icon!,
              size: 80,
              color: Colors.grey[400],
            )
          else
            const Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey,
            ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}