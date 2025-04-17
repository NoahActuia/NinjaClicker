import 'package:flutter/material.dart';
import '../game_state.dart';
import '../../../styles/kai_colors.dart';
import '../../../styles/kai_text_styles.dart';
import '../../../models/resonance.dart';
import 'resonances_tab_components/resonance_header.dart';
import 'resonances_tab_components/resonance_card.dart';

class ResonancesTab extends StatefulWidget {
  final GameState gameState;
  final int totalXP;
  final List<Resonance> resonances;
  final Function(Resonance) onUnlockResonance;
  final Function(Resonance) onUpgradeResonance;
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

    await widget.onUnlockResonance(resonance);

    // Rafraîchir la liste des résonances
    await widget.onRefresh();

    setState(() {
      isLoading = false;
      // Rafraîchir la liste locale
      currentResonances = List<Resonance>.from(widget.resonances);
    });
  }

  // Wrapper pour améliorer une résonance avec gestion d'état
  Future<void> handleUpgradeResonance(Resonance resonance) async {
    setState(() {
      isLoading = true;
    });

    await widget.onUpgradeResonance(resonance);

    // Rafraîchir la liste des résonances
    await widget.onRefresh();

    setState(() {
      isLoading = false;
      // Rafraîchir la liste locale
      currentResonances = List<Resonance>.from(widget.resonances);
    });
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
