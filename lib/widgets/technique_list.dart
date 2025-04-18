import 'package:flutter/material.dart';
import '../models/technique.dart';
import '../styles/kai_colors.dart';

class TechniqueList extends StatelessWidget {
  final List<Technique> techniques;
  final int puissance;
  final Function(Technique) onAcheterTechnique;

  const TechniqueList({
    super.key,
    required this.techniques,
    required this.puissance,
    required this.onAcheterTechnique,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Techniques Kaijin',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: KaiColors.primaryDark,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: techniques.length,
              itemBuilder: (context, index) {
                final technique = techniques[index];
                return TechniqueCard(
                  technique: technique,
                  puissance: puissance,
                  onAcheterTechnique: onAcheterTechnique,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TechniqueCard extends StatelessWidget {
  final Technique technique;
  final int puissance;
  final Function(Technique) onAcheterTechnique;

  const TechniqueCard({
    super.key,
    required this.technique,
    required this.puissance,
    required this.onAcheterTechnique,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: 5,
        horizontal: 10,
      ),
      child: ListTile(
        title: Text(
          technique.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(technique.description),
            Text(
              'Niveau: ${technique.level}',
              style: TextStyle(
                color: KaiColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Dégâts: ${technique.damage * technique.level}',
              style: TextStyle(
                color: KaiColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (technique.condition_generated != null)
              Text(
                'Effet: ${technique.condition_generated}',
                style: TextStyle(
                  color: KaiColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (technique.trigger_condition != null)
              Text(
                'Déclencheur: ${technique.trigger_condition}',
                style: TextStyle(
                  color: KaiColors.sealColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            Text(
              'Temps de recharge: ${technique.cooldown} tours',
              style: TextStyle(
                color: KaiColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: puissance >= technique.cost_kai
              ? () => onAcheterTechnique(technique)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: KaiColors.accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[400],
          ),
          child: Text(
            '${technique.cost_kai}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
