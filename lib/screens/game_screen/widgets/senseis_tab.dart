import 'package:flutter/material.dart';
import '../game_state.dart';
import '../../../models/sensei.dart';
import 'senseis_tab_components/sensei_header.dart';
import 'senseis_tab_components/sensei_card.dart';
import 'progression_action_runner.dart';

class SenseisTab extends StatefulWidget {
  final GameState gameState;
  final int totalXP;
  final List<Sensei> senseis;
  final Future<String?> Function(Sensei) onUnlockSensei;
  final Future<String?> Function(Sensei) onUpgradeSensei;
  final Function() onRefresh;

  const SenseisTab({
    Key? key,
    required this.gameState,
    required this.totalXP,
    required this.senseis,
    required this.onUnlockSensei,
    required this.onUpgradeSensei,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<SenseisTab> createState() => _SenseisTabState();
}

class _SenseisTabState extends State<SenseisTab> {
  bool isLoading = false;

  // List locale pour stocker les senseis mis à jour
  late List<Sensei> currentSenseis;

  @override
  void initState() {
    super.initState();
    currentSenseis = List<Sensei>.from(widget.senseis);
  }

  @override
  void didUpdateWidget(SenseisTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Mettre à jour la liste locale quand les props changent
    if (widget.senseis != oldWidget.senseis) {
      setState(() {
        currentSenseis = List<Sensei>.from(widget.senseis);
      });
    }
  }

  // Wrapper pour débloquer un sensei avec gestion d'état
  Future<void> handleUnlockSensei(Sensei sensei) async {
    await runProgressionAction<Sensei>(
      context: context,
      action: widget.onUnlockSensei,
      refresh: () async => widget.onRefresh(),
      onLoadingStart: () => setState(() => isLoading = true),
      onLoadingEnd: () => setState(() => isLoading = false),
      syncLocalState: () => setState(() {
        currentSenseis = List<Sensei>.from(widget.senseis);
      }),
      entity: sensei,
      entityLabel: 'Sensei',
    );
  }

  // Wrapper pour améliorer un sensei avec gestion d'état
  Future<void> handleUpgradeSensei(Sensei sensei) async {
    await runProgressionAction<Sensei>(
      context: context,
      action: widget.onUpgradeSensei,
      refresh: () async => widget.onRefresh(),
      onLoadingStart: () => setState(() => isLoading = true),
      onLoadingEnd: () => setState(() => isLoading = false),
      syncLocalState: () => setState(() {
        currentSenseis = List<Sensei>.from(widget.senseis);
      }),
      entity: sensei,
      entityLabel: 'Sensei',
    );
  }

  @override
  Widget build(BuildContext context) {
    // Trier les senseis par ordre croissant de coût XP de base
    final sortedSenseis = List<Sensei>.from(currentSenseis)
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
              currentSenseis = List<Sensei>.from(widget.senseis);
            });
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              const SenseiHeader(),
              ...sortedSenseis.map((sensei) => SenseiCard(
                    sensei: sensei,
                    totalXP: widget.totalXP,
                    gameState: widget.gameState,
                    onUnlockSensei: handleUnlockSensei,
                    onUpgradeSensei: handleUpgradeSensei,
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
