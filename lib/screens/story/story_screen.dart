import 'package:flutter/material.dart';
import '../../models/mission.dart';
import '../../models/technique.dart';
import '../../services/mission_service.dart';
import '../../services/save_service.dart';
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
  final SaveService _saveService = SaveService();

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
      // Charger les missions sauvegardées
      final savedMissions = await _saveService.loadMissions();

      if (savedMissions.isNotEmpty) {
        setState(() {
          _missions = savedMissions;
        });
      } else {
        // Si aucune mission sauvegardée, charger les missions par défaut
        setState(() {
          _missions = _missionService.getMissions();
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des missions: $e');

      // Charger les missions par défaut en cas d'erreur
      setState(() {
        _missions = _missionService.getMissions();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Sauvegarder l'état des missions
  Future<void> _saveMissions() async {
    try {
      await _saveService.saveMissions(_missions);
    } catch (e) {
      print('Erreur lors de la sauvegarde des missions: $e');
    }
  }

  // Marquer une mission comme terminée
  void _completeMission(Mission mission) {
    setState(() {
      final index = _missions.indexWhere((m) => m.id == mission.id);
      if (index != -1) {
        _missions[index].completed = true;
      }
    });

    // Sauvegarder l'état des missions
    _saveMissions();

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
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Terminée',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          // Informations de la mission
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mission.description,
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.flash_on,
                                      color: isAvailable
                                          ? Colors.orange
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Puissance requise: ${mission.puissanceRequise}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isAvailable
                                            ? Colors.black
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (!isAvailable ||
                                    !isPreviousCompleted ||
                                    mission.completed)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: mission.completed
                                          ? Colors.green.withOpacity(0.2)
                                          : !isPreviousCompleted
                                              ? Colors.orange.withOpacity(0.2)
                                              : Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      mission.completed
                                          ? 'Mission déjà accomplie'
                                          : !isPreviousCompleted
                                              ? 'Terminez la mission précédente'
                                              : 'Puissance insuffisante',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: mission.completed
                                            ? Colors.green
                                            : !isPreviousCompleted
                                                ? Colors.orange[800]
                                                : Colors.red,
                                      ),
                                    ),
                                  )
                                else
                                  ElevatedButton(
                                    onPressed: () {
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
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      minimumSize:
                                          const Size(double.infinity, 0),
                                    ),
                                    child: const Text(
                                      'Commencer la mission',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
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
