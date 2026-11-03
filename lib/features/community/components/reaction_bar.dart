// lib/features/community/components/reaction_bar.dart
import 'package:flutter/material.dart';

import '../../../core/demo.dart';

class ReactionBar extends StatefulWidget {
  const ReactionBar({super.key, required this.reactions, required this.comments});

  final int reactions;
  final int comments;

  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _liked = !_liked),
          icon: Icon(_liked ? Icons.favorite : Icons.favorite_border, size: 18),
          label: Text('${widget.reactions + (_liked ? 1 : 0)}'),
        ),
        TextButton.icon(
          onPressed: () => showDemoReadOnlyMessage(),
          icon: const Icon(Icons.chat_bubble_outline, size: 18),
          label: Text('${widget.comments}'),
        ),
      ],
    );
  }
}
