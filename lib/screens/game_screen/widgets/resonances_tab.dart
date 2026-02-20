import 'package:flutter/material.dart';
import '../game_state.dart';
import '../../../models/resonance.dart';
import 'resonances_tab_components/resonance_header.dart';
import 'resonances_tab_components/resonance_card.dart';
import 'progression_action_runner.dart';

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
    await runProgressionAction<Resonance>(
      context: context,
      action: widget.onUnlockResonance,
      refresh: () async => widget.onRefresh(),
      onLoadingStart: () => setState(() => isLoading = true),
      onLoadingEnd: () => setState(() => isLoading = false),
      syncLocalState: () => setState(() {
        currentResonances = List<Resonance>.from(widget.resonances);
      }),
      entity: resonance,
      entityLabel: 'Résonance',
    );
  }

  // Wrapper pour améliorer une résonance avec gestion d'état
  Future<void> handleUpgradeResonance(Resonance resonance) async {
    await runProgressionAction<Resonance>(
      context: context,
      action: widget.onUpgradeResonance,
      refresh: () async => widget.onRefresh(),
      onLoadingStart: () => setState(() => isLoading = true),
      onLoadingEnd: () => setState(() => isLoading = false),
      syncLocalState: () => setState(() {
        currentResonances = List<Resonance>.from(widget.resonances);
      }),
      entity: resonance,
      entityLabel: 'Résonance',
    );
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
