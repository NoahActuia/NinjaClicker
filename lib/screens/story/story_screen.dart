import 'package:flutter/material.dart';
import '../../models/mission.dart';
import '../../models/technique.dart';
import '../../services/mission_service.dart';
import 'mission_detail_screen.dart';

class StoryScreen extends StatefulWidget {
  final int puissance;
  final Function(int puissance, int clones, List<Technique> techniques)
      onMissionComplete;

  const StoryScreen({
    super.key,
    required this.puissance,
    required this.onMissionComplete,
  });

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  final MissionService _missionService = MissionService();

  List<Mission> _missions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  // Charger les missions
  Future<void> _loadMissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Charger les missions depuis Firebase
      final missions = await _missionService.loadMissions();
      setState(() {
        _missions = missions;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des missions: $e');

      // Charger les missions par défaut en cas d'erreur
      setState(() {
        _missions = _missionService.getMissions();
        _isLoading = false;
      });
    }
  }

  // Marquer une mission comme terminée
  void _completeMission(Mission mission) async {
    setState(() {
      final index = _missions.indexWhere((m) => m.id == mission.id);
      if (index != -1) {
        _missions[index].completed = true;
      }
    });

    // Sauvegarder l'état des missions dans Firebase
    try {
      await _missionService.saveMissions(_missions);
      print('Progression des missions enregistrée');
    } catch (e) {
      print('Erreur lors de la sauvegarde des missions: $e');
    }

    // Donner les récompenses au joueur
    int missionPuissance = mission.recompensePuissance;
    int missionClones = 0;
    List<Technique> missionTechniques = [];

    for (var recompense in mission.recompenses) {
      if (recompense.type == 'puissance') {
        missionPuissance += recompense.quantite;
      } else if (recompense.type == 'clone') {
        missionClones += recompense.quantite;
      } else if (recompense.type == 'technique' &&
          recompense.technique != null) {
        missionTechniques.add(recompense.technique!);
      }
    }

    // Appeler le callback pour mettre à jour le jeu principal
    widget.onMissionComplete(
        missionPuissance, missionClones, missionTechniques);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mode Histoire',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.orange[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.webp'),
            fit: BoxFit.cover,
            opacity: 0.6,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _missions.length,
                itemBuilder: (context, index) {
                  final mission = _missions[index];
                  final isAvailable = _missionService.isMissionAvailable(
                      mission, widget.puissance);

                  // Vérifier si les missions précédentes ont été terminées
                  final isPreviousCompleted =
                      index == 0 || _missions[index - 1].completed;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: (isAvailable &&
                              isPreviousCompleted &&
                              !mission.completed)
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MissionDetailScreen(
                                    mission: mission,
                                    onComplete: () => _completeMission(mission),
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image de la mission
                          Stack(
                            alignment: Alignment.bottomLeft,
                            children: [
                              Image.asset(
                                mission.image,
                                width: double.infinity,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                              Container(
                                width: double.infinity,
                                color: Colors.black.withOpacity(0.6),
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  mission.titre,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (mission.completed)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'TERMINÉE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          // Détails de la mission
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mission.description,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.flash_on,
                                      color: Colors.orange[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Puissance requise: ${mission.puissanceRequise}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isAvailable
                                            ? Colors.black
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (mission.difficulte != null)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: Colors.orange[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Difficulté: ${mission.difficulte}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Récompenses:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...mission.recompenses.map((recompense) {
                                  if (recompense.type == 'technique' &&
                                      recompense.technique != null) {
                                    return ListTile(
                                      leading: const Icon(Icons.auto_awesome),
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        'Technique: ${recompense.technique!.name}',
                                      ),
                                      subtitle: Text(
                                        recompense.technique!.description,
                                      ),
                                    );
                                  } else if (recompense.type == 'clone') {
                                    return ListTile(
                                      leading: const Icon(Icons.people),
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        '${recompense.quantite} clone${recompense.quantite > 1 ? 's' : ''}',
                                      ),
                                    );
                                  } else {
                                    return ListTile(
                                      leading: const Icon(Icons.bolt),
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        '${recompense.quantite} points de puissance',
                                      ),
                                    );
                                  }
                                }).toList(),
                                const SizedBox(height: 10),
                                Center(
                                  child: ElevatedButton.icon(
                                    onPressed: (isAvailable &&
                                            isPreviousCompleted &&
                                            !mission.completed)
                                        ? () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    MissionDetailScreen(
                                                  mission: mission,
                                                  onComplete: () =>
                                                      _completeMission(mission),
                                                ),
                                              ),
                                            );
                                          }
                                        : null,
                                    icon: Icon(
                                      mission.completed
                                          ? Icons.check_circle
                                          : Icons.play_arrow,
                                    ),
                                    label: Text(
                                      mission.completed
                                          ? 'Terminée'
                                          : 'Commencer la mission',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: mission.completed
                                          ? Colors.green
                                          : Colors.orange[700],
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
