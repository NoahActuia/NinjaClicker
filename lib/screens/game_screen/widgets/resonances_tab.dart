import 'package:flutter/material.dart';
import '../game_state.dart';
import '../../../styles/kai_colors.dart';
import '../../../models/resonance.dart';
import 'resonances_tab_components/resonance_header.dart';
import 'resonances_tab_components/resonance_card.dart';

class ResonancesTab extends StatefulWidget {
  final GameState gameState;
  final int totalXP;
  final List<Resonance> resonances;
  final Future<String?> Function(Resonance) onUnlockResonance;
  final Future<String?> Function(Resonance) onUpgradeResonance;
  final Function() onRefresh;

  const ResonancesTab({
    Key? key,
    required this.gameState,
    required this.totalXP,
    required this.resonances,
    required this.onUnlockResonance,
    required this.onUpgradeResonance,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<ResonancesTab> createState() => _ResonancesTabState();
}

class _ResonancesTabState extends State<ResonancesTab> {
  bool isLoading = false;

  // List locale pour stocker les résonances mises à jour
  late List<Resonance> currentResonances;

  @override
  void initState() {
    super.initState();
    currentResonances = List<Resonance>.from(widget.resonances);
  }

  @override
  void didUpdateWidget(ResonancesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Mettre à jour la liste locale quand les props changent
    if (widget.resonances != oldWidget.resonances) {
      setState(() {
        currentResonances = List<Resonance>.from(widget.resonances);
      });
    }
  }

  // Wrapper pour débloquer une résonance avec gestion d'état
  Future<void> handleUnlockResonance(Resonance resonance) async {
    setState(() {
      isLoading = true;
    });

    final errorCode = await widget.onUnlockResonance(resonance);

    // Rafraîchir la liste des résonances
    await widget.onRefresh();

    setState(() {
      isLoading = false;
      // Rafraîchir la liste locale
      currentResonances = List<Resonance>.from(widget.resonances);
    });

    if (errorCode != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_mapErrorToMessage(errorCode)),
          backgroundColor: KaiColors.error,
        ),
      );
    }
  }

  // Wrapper pour améliorer une résonance avec gestion d'état
  Future<void> handleUpgradeResonance(Resonance resonance) async {
    setState(() {
      isLoading = true;
    });

    final errorCode = await widget.onUpgradeResonance(resonance);

    // Rafraîchir la liste des résonances
    await widget.onRefresh();

    setState(() {
      isLoading = false;
      // Rafraîchir la liste locale
      currentResonances = List<Resonance>.from(widget.resonances);
    });

    if (errorCode != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_mapErrorToMessage(errorCode)),
          backgroundColor: KaiColors.error,
        ),
      );
    }
  }

  String _mapErrorToMessage(String code) {
    switch (code) {
      case 'ERR_NOT_ENOUGH_XP':
        return 'XP insuffisante pour cette action.';
      case 'ERR_KAIJIN_NOT_FOUND':
        return 'Kaijin introuvable. Recharge la session.';
      case 'ERR_NOT_UNLOCKED':
        return 'Résonance non débloquée.';
      case 'ERR_MAX_LEVEL_REACHED':
        return 'Niveau maximum déjà atteint.';
      case 'ERR_INVALID_UNLOCK_COST':
      case 'ERR_INVALID_UPGRADE_COST':
        return 'Coût invalide détecté. Réessaie après synchronisation.';
      default:
        return 'Action impossible pour le moment.';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Trier les résonances par ordre croissant de coût XP de base
    final sortedResonances = List<Resonance>.from(currentResonances)
      ..sort((a, b) => a.xpCostToUnlock.compareTo(b.xpCostToUnlock));

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            setState(() {
              isLoading = true;
            });
            await widget.onRefresh();
            setState(() {
              isLoading = false;
              currentResonances = List<Resonance>.from(widget.resonances);
            });
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              const ResonanceHeader(),
              ...sortedResonances.map((resonance) => ResonanceCard(
                    resonance: resonance,
                    totalXP: widget.totalXP,
                    gameState: widget.gameState,
                    onUnlockResonance: handleUnlockResonance,
                    onUpgradeResonance: handleUpgradeResonance,
                  )),
            ],
          ),
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
}
