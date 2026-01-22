import 'package:flutter/material.dart';

class MenuList extends StatelessWidget {
  final List<MenuItem> items;

  const MenuList({
    Key? key,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) => _buildMenuItem(context, item)).toList(),
    );
  }

  Widget _buildMenuItem(BuildContext context, MenuItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          item.icon,
          color: Theme.of(context).primaryColor,
          semanticLabel: item.semanticLabel,
        ),
        title: Text(item.title),
        trailing: const Icon(Icons.chevron_right),
        onTap: item.onTap,
      ),
    );
  }
}

class MenuItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final String? semanticLabel;

  MenuItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.semanticLabel,
  });
}