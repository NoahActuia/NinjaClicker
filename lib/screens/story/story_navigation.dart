import 'package:flutter/material.dart';
import 'mission_intro_sequence.dart';
import 'story_path_screen.dart';

class StoryNavigation extends StatefulWidget {
  final int puissance;
  final Function(int puissance, int clones, List<dynamic> techniques) onMissionComplete;

  const StoryNavigation({
    super.key,
    required this.puissance,
    required this.onMissionComplete,
  });

  @override
  State<StoryNavigation> createState() => _StoryNavigationState();
}

class _StoryNavigationState extends State<StoryNavigation> {
  bool _hasSeenIntro = false;

  @override
  Widget build(BuildContext context) {
    if (!_hasSeenIntro) {
      return MissionIntroSequence(
        onComplete: () {
          setState(() {
            _hasSeenIntro = true;
          });
        },
      );
    }

    return StoryPathScreen(
      puissance: widget.puissance,
      onMissionComplete: widget.onMissionComplete,
    );
  }
} 