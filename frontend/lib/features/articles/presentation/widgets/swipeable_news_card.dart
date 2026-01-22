import 'package:flutter/material.dart';
// import 'package:swipeable_card/swipeable_card.dart';
import 'news_card.dart';

class SwipeableNewsCard extends StatefulWidget {
  final String title;
  final String description;
  final String imageUrl;
  final String articleUrl;
  final bool isBookmarked;
  final bool isLiked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onLikeToggle;
  final VoidCallback onSwipeRight;
  final VoidCallback onSwipeLeft;

  const SwipeableNewsCard({
    Key? key,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.articleUrl,
    this.isBookmarked = false,
    this.isLiked = false,
    required this.onBookmarkToggle,
    required this.onLikeToggle,
    required this.onSwipeRight,
    required this.onSwipeLeft,
  }) : super(key: key);

  @override
  State<SwipeableNewsCard> createState() => _SwipeableNewsCardState();
}

class _SwipeableNewsCardState extends State<SwipeableNewsCard> {
  late bool _isLiked;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
  }

  @override
  Widget build(BuildContext context) {
    return Column();
    // return SwipeableWidget(
    //   child: NewsCard(
    //     title: widget.title,
    //     description: widget.description,
    //     imageUrl: widget.imageUrl,
    //     articleUrl: widget.articleUrl,
    //     isBookmarked: widget.isBookmarked,
    //     isLiked: _isLiked,
    //     onBookmarkToggle: widget.onBookmarkToggle,
    //     onLikeToggle: () {
    //       setState(() {
    //         _isLiked = !_isLiked;
    //       });
    //       widget.onLikeToggle();
    //     },
    //   ),
    //   onSwipeLeft: widget.onSwipeLeft,
    //   onSwipeRight: () {
    //     setState(() {
    //       _isLiked = true;
    //     });
    //     widget.onSwipeRight();
    //   },
    // );
  }
}