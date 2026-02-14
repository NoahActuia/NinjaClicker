import 'package:flutter/material.dart';
import '../game_state.dart';
import '../../../styles/kai_colors.dart';
import '../../../models/sensei.dart';
import 'senseis_tab_components/sensei_header.dart';
import 'senseis_tab_components/sensei_card.dart';

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
    setState(() {
      isLoading = true;
    });

    final errorCode = await widget.onUnlockSensei(sensei);

    // Rafraîchir la liste des senseis
    await widget.onRefresh();

    setState(() {
      isLoading = false;
      // Rafraîchir la liste locale
      currentSenseis = List<Sensei>.from(widget.senseis);
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

  // Wrapper pour améliorer un sensei avec gestion d'état
  Future<void> handleUpgradeSensei(Sensei sensei) async {
    setState(() {
      isLoading = true;
    });

    final errorCode = await widget.onUpgradeSensei(sensei);

    // Rafraîchir la liste des senseis
    await widget.onRefresh();

    setState(() {
      isLoading = false;
      // Rafraîchir la liste locale
      currentSenseis = List<Sensei>.from(widget.senseis);
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
        return 'Sensei non débloqué.';
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
