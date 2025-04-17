import 'package:flutter/material.dart';
import '../../../../styles/kai_colors.dart';

/// Widget pour les onglets
class KaiTabsWidget extends StatelessWidget implements PreferredSizeWidget {
  const KaiTabsWidget({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(50);

  @override
  Widget build(BuildContext context) {
    return TabBar(
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorPadding: const EdgeInsets.symmetric(horizontal: 4),
      labelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 14,
      ),
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          colors: [
            KaiColors.accent.withOpacity(0.6),
            KaiColors.accent.withOpacity(0.3),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white.withOpacity(0.7),
      tabs: [
        _buildTab(Icons.auto_fix_high, 'Résonances'),
        _buildTab(Icons.people, 'Senseis'),
      ],
    );
  }

  // Méthode pour construire un onglet
  Widget _buildTab(IconData icon, String label) {
    return Tab(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
    );
  }
}
