import 'package:flutter/material.dart';
import '../../../models/technique.dart';
import '../../../styles/kai_colors.dart';
import '../technique_tree_state.dart';

/// Widget pour afficher une carte de technique
class TechniqueCard extends StatelessWidget {
  final Technique technique;
  final TechniqueTreeState state;
  final VoidCallback onTap;

  const TechniqueCard({
    Key? key,
    required this.technique,
    required this.state,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Récupérer le statut de débloquage à partir de notre map
    final bool isUnlocked = state.unlockedTechniques[technique.id] ?? false;

    // Couleur basée sur l'affinité
    Color affinityColor;
    switch (technique.affinity) {
      case 'Flux':
        affinityColor = KaiColors.fluxColor;
        break;
      case 'Fracture':
        affinityColor = KaiColors.fractureColor;
        break;
      case 'Sceau':
        affinityColor = KaiColors.sealColor;
        break;
      case 'Dérive':
        affinityColor = KaiColors.driftColor;
        break;
      case 'Frappe':
        affinityColor = KaiColors.strikeColor;
        break;
      default:
        affinityColor = KaiColors.textSecondary;
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              isUnlocked ? affinityColor.withOpacity(0.7) : Colors.transparent,
          width: 1.5,
        ),
      ),
      elevation: 8,
      color: KaiColors.cardBackground,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isUnlocked
                  ? [
                      affinityColor.withOpacity(0.2),
                      KaiColors.cardBackground,
                    ]
                  : [
                      KaiColors.cardBackground,
                      KaiColors.cardBackground,
                    ],
            ),
          ),
          child: Stack(
            children: [
              // Contenu de la carte
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom et icône d'affinité
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            technique.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isUnlocked
                                  ? KaiColors.textPrimary
                                  : KaiColors.textSecondary,
                            ),
                          ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: affinityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: affinityColor.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            technique.affinity ?? 'Neutre',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: affinityColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // Description
                    Text(
                      technique.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: isUnlocked
                            ? KaiColors.textSecondary
                            : KaiColors.textSecondary.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: 12),
                    Spacer(),
                    // Puissance
                    Text(
                      _getFormattedPower(technique),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked
                            ? KaiColors.accent
                            : KaiColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4),
                    // Coût et niveau
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getFormattedCost(technique),
                          style: TextStyle(
                            fontSize: 12,
                            color: isUnlocked
                                ? KaiColors.textSecondary
                                : KaiColors.textSecondary.withOpacity(0.7),
                          ),
                        ),
                        if (isUnlocked)
                          Text(
                            _getFormattedLevel(technique),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: KaiColors.accent,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Indicateur de technique verrouillée
              if (!isUnlocked)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock,
                            color: KaiColors.textSecondary.withOpacity(0.7),
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'XP Requis: ${technique.xp_unlock_cost}',
                            style: TextStyle(
                              color: KaiColors.textSecondary.withOpacity(0.9),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Méthodes utilitaires pour afficher les informations
  String _getFormattedPower(Technique technique) {
    return 'Puissance: ${technique.damage}';
  }

  String _getFormattedCost(Technique technique) {
    return 'Coût: ${technique.cost_kai} Kai';
  }

  String _getFormattedLevel(Technique technique) {
    return 'Niv. ${technique.level}';
  }
}
