// lib/widgets/swipe_card_stack.dart
import 'package:flutter/material.dart';

typedef SwipeCallback = void Function(Map<String, dynamic> article, bool liked);

class SwipeCardStack extends StatefulWidget {
  final List<Map<String, dynamic>> articles;
  final SwipeCallback onSwipe;
  final int maxStack;

  const SwipeCardStack({
    Key? key,
    required this.articles,
    required this.onSwipe,
    this.maxStack = 1, // Changed default to 1 for single card display
  }) : super(key: key);

  @override
  State<SwipeCardStack> createState() => _SwipeCardStackState();
}

class _SwipeCardStackState extends State<SwipeCardStack> {
  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.articles);
  }

  @override
  void didUpdateWidget(covariant SwipeCardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.articles != widget.articles) {
      _items = List.from(widget.articles);
    }
  }

  void _handleSwipe(Map<String, dynamic> article, bool liked) {
    widget.onSwipe(article, liked);
    setState(() => _items.remove(article));
  }

  Widget _buildCard(Map<String, dynamic> article) {
    // Swap this for your existing _buildNewsCard(article) look if desired.
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.7),
                    Colors.green.withOpacity(0.7),
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.article_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical:4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Good News', style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  Icon(Icons.sentiment_very_satisfied, color: Colors.green, size: 20),
                ]),
                const SizedBox(height: 10),
                Text(article['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text(article['description'], style: TextStyle(color: Colors.grey[700]), maxLines: 3, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const Center(child: Text('No more articles'));

    // Always show only one card at a time
    final int stackCount = 1;

    return SizedBox(
      height: 420,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_items.isNotEmpty) ...[
            Positioned.fill(
              child: Draggable<Map<String, dynamic>>(
                data: _items[0],
                feedback: Material(
                  color: Colors.transparent,
                  child: Transform.scale(
                    scale: 1.02,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width - 32, 
                      child: _buildCard(_items[0]),
                    ),
                  ),
                ),
                childWhenDragging: Container(),
                onDragEnd: (details) {
                  final screenCenterX = MediaQuery.of(context).size.width / 2;
                  final dx = details.offset.dx - screenCenterX;
                  if (dx > 100) _handleSwipe(_items[0], true);
                  else if (dx < -100) _handleSwipe(_items[0], false);
                  else setState(() {});
                },
                child: GestureDetector(
                  onTap: () {},
                  child: _buildCard(_items[0]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}