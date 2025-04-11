import 'package:flutter/material.dart';
import '../../models/mission.dart';
import '../../models/technique.dart';

class MissionDetailScreen extends StatelessWidget {
  final Mission mission;
  final Function onComplete;

  const MissionDetailScreen({
    super.key,
    required this.mission,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          mission.titre,
          style: const TextStyle(
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
            opacity: 0.7,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image de la mission
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    mission.image,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),

                // Titre de la mission
                Text(
                  mission.titre,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),

                // Description de la mission
                Text(
                  mission.description,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),

                // Histoire de la mission
                const Text(
                  "Histoire",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    mission.histoire,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Récompenses
                const Text(
                  "Récompenses",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),

                // Récompense de puissance de base
                _buildRewardCard(
                  "Puissance",
                  "${mission.recompensePuissance} points de puissance",
                  Icons.flash_on,
                  Colors.amber,
                ),

                // Autres récompenses
                ...mission.recompenses.map((recompense) {
                  if (recompense.type == 'puissance') {
                    return _buildRewardCard(
                      "Puissance bonus",
                      "${recompense.quantite} points de puissance",
                      Icons.flash_on,
                      Colors.amber,
                    );
                  } else if (recompense.type == 'clone') {
                    return _buildRewardCard(
                      "Clones",
                      "${recompense.quantite} clone${recompense.quantite > 1 ? 's' : ''}",
                      Icons.person_add,
                      Colors.blue,
                    );
                  } else if (recompense.type == 'technique' &&
                      recompense.technique != null) {
                    return _buildTechniqueRewardCard(recompense.technique!);
                  } else {
                    return const SizedBox.shrink();
                  }
                }).toList(),

                const SizedBox(height: 32),

                // Bouton pour compléter la mission
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      onComplete();
                      _showRewardDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Compléter la mission",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRewardCard(
      String title, String description, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: color,
          size: 32,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(description),
      ),
    );
  }

  Widget _buildTechniqueRewardCard(Technique technique) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(
          Icons.auto_awesome,
          color: Colors.purple,
          size: 32,
        ),
        title: Text(
          "Technique: ${technique.nom}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(technique.description),
        trailing: Text(
          "${technique.puissanceParSeconde}/s",
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showRewardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Mission Accomplie !",
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                "Félicitations, ninja !",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Vous avez réussi la mission avec succès et gagné des récompenses !",
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text(
                "Génial !",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }
}
