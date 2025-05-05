import 'package:flutter/material.dart';
import '../../../styles/kai_colors.dart';
import '../technique_tree_state.dart';

/// Widget de la barre d'application pour l'écran des techniques
class TechniqueAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TechniqueTreeState state;
  final String kaijinName;

  const TechniqueAppBar({
    Key? key,
    required this.state,
    required this.kaijinName,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Arbre des Techniques',
            style: TextStyle(color: KaiColors.textPrimary),
          ),
          Text(
            'Fracturé: $kaijinName',
            style: TextStyle(
              color: KaiColors.accent,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      backgroundColor: KaiColors.primaryDark,
      iconTheme: IconThemeData(color: KaiColors.textPrimary),
      elevation: 8.0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              KaiColors.primaryDark,
              KaiColors.primaryDark.withOpacity(0.8),
              KaiColors.accent.withOpacity(0.3),
            ],
          ),
        ),
      ),
      actions: [
        // Bouton pour le mode en ligne
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          margin: EdgeInsets.only(right: 8.0),
          decoration: BoxDecoration(
            color: KaiColors.accent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextButton.icon(
            icon: Icon(Icons.public, color: KaiColors.accent),
            label: Text(
              'Mode en ligne',
              style: TextStyle(
                color: KaiColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/online_combat');
            },
          ),
        ),
        // Filtre par affinité
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          margin: EdgeInsets.only(right: 8.0),
          decoration: BoxDecoration(
            color: KaiColors.cardBackground.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: DropdownButton<String>(
            value: state.selectedAffinity,
            dropdownColor: KaiColors.primaryDark,
            style: TextStyle(color: KaiColors.textPrimary),
            icon: Icon(Icons.filter_list, color: KaiColors.accent),
            underline: Container(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                state.updateSelectedAffinity(newValue);
              }
            },
            items:
                state.affinities.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
