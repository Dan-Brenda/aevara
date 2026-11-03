// lib/features/challenges/components/participant_avatars_row.dart
import 'package:flutter/material.dart';

/// Initials in a circle. The colour is picked from the name, so a person looks
/// the same on every screen.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({super.key, required this.name, this.size = 32});

  final String name;
  final double size;

  static const _colors = <Color>[
    Color(0xFF24A699),
    Color(0xFF5B8DEF),
    Color(0xFFB46FD8),
    Color(0xFFE08E45),
    Color(0xFFD9627A),
    Color(0xFF6BA84F),
    Color(0xFF4FA3C7),
  ];

  @override
  Widget build(BuildContext context) {
    final initials = name.split(' ').where((p) => p.isNotEmpty).take(2).map((p) => p[0]).join();
    final color = _colors[name.codeUnits.fold<int>(0, (a, b) => a + b) % _colors.length];
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color,
      child: Text(
        initials,
        style: TextStyle(color: Colors.white, fontSize: size * 0.38, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class ParticipantAvatarsRow extends StatelessWidget {
  const ParticipantAvatarsRow({super.key, required this.names, this.max = 4});

  final List<String> names;
  final int max;

  @override
  Widget build(BuildContext context) {
    const size = 28.0;
    final shown = names.take(max).toList();
    final extra = names.length - shown.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size + (shown.length - 1) * 20,
          height: size,
          child: Stack(
            children: [
              for (var i = 0; i < shown.length; i++)
                Positioned(left: i * 20, child: PersonAvatar(name: shown[i], size: size)),
            ],
          ),
        ),
        if (extra > 0) ...[
          const SizedBox(width: 6),
          Text('+$extra', style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}
