import 'package:flutter/material.dart';
import '../../../models/technique.dart';
import '../../../styles/kai_colors.dart';
import '../technique_tree_state.dart';
import 'technique_card.dart';

/// Widget pour afficher une section de niveau de techniques
class TechniqueLevelSection extends StatelessWidget {
  final int level;
  final List<Technique> techniques;
  final TechniqueTreeState state;
  final Function(Technique) onTapTechnique;

  const TechniqueLevelSection({
    Key? key,
    required this.level,
    required this.techniques,
    required this.state,
    required this.onTapTechnique,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre du niveau
        Container(
          margin: EdgeInsets.only(top: 16, left: 16, right: 16),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                KaiColors.primaryDark,
                KaiColors.accent.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.insights,
                color: KaiColors.accent,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Niveau $level',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: KaiColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        // Grille de techniques
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: techniques.length,
          itemBuilder: (context, index) {
            final technique = techniques[index];

            // Vérifier la possibilité de déblocage
            int techLevel = state.techniqueLevels[technique.id] ?? 1;
            String? parentId = state.techniqueParents[technique.id];
            bool canUnlock = techLevel == 1 ||
                (parentId != null &&
                    (state.unlockedTechniques[parentId] ?? false));

            return TechniqueCard(
              technique: technique,
              state: state,
              onTap: () => onTapTechnique(technique),
            );
          },
        ),
        SizedBox(height: 16),
      ],
    );
  }
}
