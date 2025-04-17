import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/mission.dart';
import '../../models/technique.dart';
import '../../services/mission_service.dart';
import 'mission_detail_screen.dart';
import '../story_intro.dart';
import 'story_path_screen.dart';

class StoryScreen extends StatefulWidget {
  final int puissance;
  final Function(int puissance, int clones, List<dynamic> techniques) onMissionComplete;

  const StoryScreen({
    super.key,
    required this.puissance,
    required this.onMissionComplete,
  });

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  late Future<MissionService> _missionServiceFuture;

  @override
  void initState() {
    super.initState();
    _missionServiceFuture = _initMissionService();
  }

  Future<MissionService> _initMissionService() async {
    final prefs = await SharedPreferences.getInstance();
    return MissionService(prefs);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MissionService>(
      future: _missionServiceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        return StoryPathScreen(
          puissance: widget.puissance,
          onMissionComplete: widget.onMissionComplete,
        );
      },
    );
  }
}
