import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/technique.dart';
import '../../models/kaijin_technique.dart';
import '../../styles/kai_colors.dart';
import 'technique_tree_state.dart';
import 'widgets/technique_card.dart';
import 'widgets/technique_details_modal.dart';
import 'widgets/xp_display.dart';
import 'widgets/technique_level_section.dart';
import 'widgets/technique_app_bar.dart';
import 'widgets/info_card.dart';

/// Vue de l'écran d'arbre des techniques qui s'occupe uniquement de l'affichage
class TechniqueTreeScreenView extends StatelessWidget {
  final TechniqueTreeState state;

  const TechniqueTreeScreenView({
    Key? key,
    required this.state,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KaiColors.background,
      appBar: TechniqueAppBar(
        state: state,
        kaijinName: state.kaijinName,
      ),
      body: state.isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(KaiColors.accent),
              ),
            )
          : Column(
              children: [
                // XP disponible
                XpDisplay(playerXp: state.playerXp),

                // Arbre des techniques
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/academy.webp'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          KaiColors.primaryDark.withOpacity(0.8),
                          BlendMode.darken,
                        ),
                      ),
                    ),
                    child: ListView.builder(
                      itemCount: state.techniquesByLevel.length,
                      itemBuilder: (context, index) {
                        // Niveau de technique (index + 1 car les niveaux commencent à 1)
                        final level = index + 1;
                        final techniques = state.techniquesByLevel[level] ?? [];

                        // Filtrer par affinité si nécessaire
                        final filteredTechniques = state.selectedAffinity ==
                                'Tous'
                            ? techniques
                            : techniques
                                .where(
                                    (t) => t.affinity == state.selectedAffinity)
                                .toList();

                        if (filteredTechniques.isEmpty) {
                          return SizedBox.shrink();
                        }

                        return TechniqueLevelSection(
                          level: level,
                          techniques: filteredTechniques,
                          state: state,
                          onTapTechnique: (technique) =>
                              _showTechniqueDetails(context, technique),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _showTechniqueDetails(
      BuildContext context, Technique technique) async {
    // Récupérer le statut de débloquage
    bool isUnlocked = state.unlockedTechniques[technique.id] ?? false;

    // Récupérer le niveau actuel de la technique pour ce kaijin (si déjà débloquée)
    int techLevel = 1;
    KaijinTechnique? kaijinTechnique;

    if (isUnlocked) {
      final relations =
          await state.getKaijinTechniquesForTechnique(technique.id);
      if (relations.isNotEmpty) {
        kaijinTechnique = relations.first;
        techLevel = kaijinTechnique.level;
      }
    }

    // Calculer le coût d'amélioration (augmente de 50% à chaque niveau)
    int upgradeCost = technique.getUpgradeCost();

    // Calculer les statistiques en fonction du niveau
    double powerMultiplier = 1.0 + (0.25 * (techLevel - 1));
    int currentPower = (technique.damage * powerMultiplier).round();
    int nextLevelPower = (technique.damage * (powerMultiplier + 0.25)).round();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TechniqueDetailsModal(
        technique: technique,
        state: state,
        isUnlocked: isUnlocked,
        techLevel: techLevel,
        upgradeCost: upgradeCost,
        currentPower: currentPower,
        nextLevelPower: nextLevelPower,
      ),
    );
  }
}
