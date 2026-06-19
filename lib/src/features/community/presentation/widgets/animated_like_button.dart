import 'package:flutter/material.dart';

class AnimatedLikeButton extends StatefulWidget {
  const AnimatedLikeButton({
    super.key,
    required this.postId,
    required this.initialLikes,
    required this.initialIsLiked,
    required this.onLike,
    this.showText = true,
    this.iconSize = 22,
    this.textSize = 14,
    this.textWeightLiked = FontWeight.w800,
    this.textWeightUnliked = FontWeight.w600,
  });

  final int postId;
  final int initialLikes;
  final bool initialIsLiked;
  final VoidCallback onLike;
  final bool showText;
  final double iconSize;
  final double textSize;
  final FontWeight textWeightLiked;
  final FontWeight textWeightUnliked;

  @override
  State<AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<AnimatedLikeButton>
    with SingleTickerProviderStateMixin {
  late bool _isLiked;
  late int _likes;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initialIsLiked;
    _likes = widget.initialLikes;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.35, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant AnimatedLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postId != widget.postId) {
      _isLiked = widget.initialIsLiked;
      _likes = widget.initialLikes;
    } else {
      if (!_controller.isAnimating) {
        _isLiked = widget.initialIsLiked;
        _likes = widget.initialLikes;
      }
    }
  }

  void _handleLike() {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likes += 1;
        _controller.forward(from: 0.0);
      } else {
        _likes -= 1;
        if (_likes < 0) _likes = 0;
      }
    });
    widget.onLike();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _handleLike,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(
                _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _isLiked ? const Color(0xFFE91E63) : const Color(0xFF64748B),
                size: widget.iconSize,
              ),
            ),
            if (widget.showText) ...[
              const SizedBox(width: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, -0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  '$_likes',
                  key: ValueKey<int>(_likes),
                  style: TextStyle(
                    color: _isLiked ? const Color(0xFFE91E63) : const Color(0xFF1F2937),
                    fontSize: widget.textSize,
                    fontWeight: _isLiked ? widget.textWeightLiked : widget.textWeightUnliked,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
