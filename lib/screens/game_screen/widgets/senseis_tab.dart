import 'package:flutter/material.dart';
import '../game_state.dart';
import '../../../styles/kai_colors.dart';
import '../../../models/sensei.dart';
import '../../../services/sensei_service.dart';
import '../../../models/kaijin.dart';

class SenseisTab extends StatefulWidget {
  final GameState gameState;
  final int totalXP;
  final List<Sensei> senseis;
  final Function() onUpdateState;
  final Kaijin? currentKaijin;

  const SenseisTab({
    Key? key,
    required this.gameState,
    required this.totalXP,
    required this.senseis,
    required this.onUpdateState,
    required this.currentKaijin,
  }) : super(key: key);

  @override
  State<SenseisTab> createState() => _SenseisTabState();
}

class _SenseisTabState extends State<SenseisTab> {
  final SenseiService _senseiService = SenseiService();
  bool isLoading = false;

  // Fonction pour acheter un sensei
  Future<void> acheterSensei(Sensei sensei) async {
    if (widget.currentKaijin == null) return;
    setState(() => isLoading = true);

    final success = await _senseiService.acheterSensei(
        widget.currentKaijin!, sensei, widget.totalXP, (int amount) {
      widget.gameState.addXP(amount);
      widget.onUpdateState();
    });

    if (success) {
      await widget.gameState.saveGame(updateConnections: true);
      widget.onUpdateState();
    }

    setState(() => isLoading = false);
  }

  // Fonction pour améliorer un sensei
  Future<void> ameliorerSensei(Sensei sensei) async {
    if (widget.currentKaijin == null) return;
    setState(() => isLoading = true);

    final success = await _senseiService.ameliorerSensei(
        widget.currentKaijin!, sensei, widget.totalXP, (int amount) {
      widget.gameState.addXP(amount);
      widget.onUpdateState();
    });

    if (success) {
      await widget.gameState.saveGame(updateConnections: true);
      widget.onUpdateState();
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            buildSenseiHeader(),
            ...widget.senseis.map((sensei) => buildSenseiCard(context, sensei)),
            buildLockedSenseiPlaceholder(),
          ],
        ),
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget buildSenseiHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            KaiColors.primaryDark,
            KaiColors.primaryDark.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Senseis Disponibles',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les senseis vous enseignent de nouvelles techniques et augmentent votre génération passive d\'XP.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSenseiCard(BuildContext context, Sensei sensei) {
    final int nextLevelCost = _senseiService.calculateUpgradeCost(sensei);
    final bool canAffordUpgrade = widget.totalXP >= nextLevelCost;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              KaiColors.background,
              KaiColors.background.withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: KaiColors.accent.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: KaiColors.primaryDark.withOpacity(0.2),
                      border: Border.all(
                        color: KaiColors.accent,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        sensei.image,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sensei.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue, // Couleur par défaut
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "Sensei", // Texte par défaut
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Niveau ${sensei.level}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: KaiColors.primaryDark.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bolt,
                          color: KaiColors.accent,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.gameState.formatNumber(sensei.getTotalXpPerSecond())} / sec',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                sensei.description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: (canAffordUpgrade && !isLoading)
                    ? () => ameliorerSensei(sensei)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAffordUpgrade
                      ? KaiColors.primaryDark
                      : Colors.grey.shade800,
                  disabledBackgroundColor: Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.upgrade, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Améliorer (${widget.gameState.formatNumber(nextLevelCost)})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLockedSenseiPlaceholder() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade700.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.lock,
            size: 40,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 16),
          const Text(
            'Sensei Verrouillé',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Progressez dans le mode histoire pour débloquer de nouveaux senseis avec des affinités différentes.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
