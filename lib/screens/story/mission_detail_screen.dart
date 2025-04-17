import 'package:flutter/material.dart';
import '../../models/mission.dart';
import '../../models/technique.dart';
import 'mission_intro_sequence.dart';
import 'combat_screen.dart';
import '../../theme/app_colors.dart';

class MissionDetailScreen extends StatefulWidget {
  final Mission mission;
  final VoidCallback onComplete;

  const MissionDetailScreen({
    super.key,
    required this.mission,
    required this.onComplete,
  });

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  bool _hasSeenIntro = false;
  bool _isInCombat = false;
  bool _isLoading = false;

  void _startCombat() {
    setState(() {
      _isInCombat = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Afficher la séquence d'introduction
    if (!_hasSeenIntro) {
      return MissionIntroSequence(
        onComplete: () {
          setState(() {
            _hasSeenIntro = true;
            _isInCombat = true; // Passer directement au combat après l'intro
          });
        },
      );
    }

    // Afficher l'écran de combat
    if (_isInCombat) {
      return CombatScreen(
        mission: widget.mission,
        onComplete: widget.onComplete,
      );
    }

    // Afficher les détails de la mission
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          widget.mission.titre,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image de la mission
            if (widget.mission.image != null)
              Image.asset(
                widget.mission.image!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            else
              Container(
                height: 200,
                color: Colors.grey[800],
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: Colors.white54,
                  ),
                ),
              ),

            // Détails de la mission
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    widget.mission.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Difficulté
                  _buildInfoRow(
                    Icons.star,
                    'Difficulté',
                    widget.mission.difficulty.toString(),
                    AppColors.accent,
                  ),
                  const SizedBox(height: 16),

                  // Puissance requise
                  _buildInfoRow(
                    Icons.flash_on,
                    'Puissance requise',
                    widget.mission.puissanceRequise.toString(),
                    AppColors.kaiEnergy,
                  ),
                  const SizedBox(height: 24),

                  // Histoire de la mission
                  if (widget.mission.histoire != null) ...[
                    const Text(
                      "Histoire",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                        widget.mission.histoire!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Récompenses
                  const Text(
                    'Récompenses',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...widget.mission.recompenses.map((recompense) {
                    IconData icon;
                    String text;
                    switch (recompense.type) {
                      case 'puissance':
                        icon = Icons.flash_on;
                        text = '${recompense.quantite} points de puissance';
                        break;
                      case 'technique':
                        icon = Icons.auto_awesome;
                        text = 'Nouvelle technique : ${recompense.technique?.name ?? ""}';
                        break;
                      case 'clone':
                        icon = Icons.person_add;
                        text = '${recompense.quantite} clone(s)';
                        break;
                      default:
                        icon = Icons.star;
                        text = '${recompense.quantite} ${recompense.type}';
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _buildInfoRow(icon, '', text, AppColors.accent),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _startMission,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.kaiEnergy,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text(
                  'COMMENCER LA MISSION',
                  style: TextStyle(fontSize: 18),
                ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _startMission() {
    setState(() => _isLoading = true);
    
    // Simuler un délai pour l'animation
    Future.delayed(const Duration(seconds: 1), () {
      widget.onComplete();
      Navigator.of(context).pop();
    });
  }
}
