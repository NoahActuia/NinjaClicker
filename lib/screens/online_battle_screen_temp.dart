import 'package:flutter/material.dart';
import '../styles/kai_colors.dart';

class OnlineBattleScreenTemp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Barres de vie
          Row(
            children: [
              Expanded(
                child: _buildHealthBar("Joueur", 1000, Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHealthBar("Adversaire", 1000, Colors.red),
              ),
            ],
          ),
          // Barres de Kai
          Row(
            children: [
              Expanded(
                child: _buildKaiBar("Joueur", 100, 100),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKaiBar("Adversaire", 100, 100),
              ),
            ],
          ),
          _buildCombatZone(),
          _buildTechniques(),
        ],
      ),
    );
  }

  Widget _buildHealthBar(String label, double health, Color color,
      {bool hasShield = false}) {
    return Container(
      height: 25,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.black26,
      ),
      child: Stack(
        children: [
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: health / 1000.0,
              backgroundColor: Colors.black38,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 25,
            ),
          ),
          // Texte de la valeur
          Center(
            child: Text(
              "${health.toInt()}/1000",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          // Effet de bouclier
          if (hasShield)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: color.withOpacity(0.8),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKaiBar(String label, double kai, double maxKai) {
    return Container(
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.black26,
      ),
      child: Stack(
        children: [
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: kai / maxKai,
              backgroundColor: Colors.black38,
              valueColor: AlwaysStoppedAnimation<Color>(KaiColors.kaiEnergy),
              minHeight: 20,
            ),
          ),
          // Texte de la valeur
          Center(
            child: Text(
              "${kai.toInt()}/$maxKai",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombatZone() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(8),
          image: const DecorationImage(
            image: AssetImage('images/combat_background.png'),
            fit: BoxFit.cover,
            opacity: 0.7,
          ),
        ),
        child: Stack(
          children: [
            // Combattants
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Joueur
                Container(
                  width: 120,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/player_default.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Adversaire
                Container(
                  width: 120,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/enemy_default.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),

            // Message de combat
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Le combat commence!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "VOTRE TOUR",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechniques() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // En-têtes
          Row(
            children: [
              const Expanded(
                child: Text(
                  "VOS TECHNIQUES",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Container(
                width: 1,
                height: 20,
                color: Colors.white24,
              ),
              const Expanded(
                child: Text(
                  "TECHNIQUES DE L'ADVERSAIRE",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Techniques
          Expanded(
            child: Row(
              children: [
                // Techniques du joueur
                Expanded(
                  child: _buildTechniqueList(true),
                ),
                Container(
                  width: 1,
                  color: Colors.white24,
                ),
                // Techniques de l'adversaire
                Expanded(
                  child: _buildTechniqueList(false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechniqueList(bool isPlayer) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 4, // Exemple
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: isPlayer
                ? Colors.blue.withOpacity(0.2)
                : Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isPlayer
                  ? Colors.blue.withOpacity(0.5)
                  : Colors.red.withOpacity(0.5),
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Technique ${index + 1}",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.flash_on,
                    color: Colors.white,
                    size: 14,
                  ),
                  Text(
                    "150 dmg",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.energy_savings_leaf,
                    color: KaiColors.kaiEnergy,
                    size: 14,
                  ),
                  Text(
                    "30",
                    style: TextStyle(
                      color: KaiColors.kaiEnergy,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
