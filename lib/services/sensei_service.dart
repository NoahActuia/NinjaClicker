import '../models/kaijin.dart';
import '../models/sensei.dart';
import 'kaijin_service.dart';

/// Service qui gère toutes les opérations liées aux senseis
class SenseiService {
  static final SenseiService _instance = SenseiService._internal();
  factory SenseiService() => _instance;

  final KaijinService kaijinService = KaijinService();

  SenseiService._internal();

  // Charger les senseis disponibles pour un kaijin
  Future<List<Sensei>> loadSenseis(String kaijinId) async {
    try {
      final senseis = await kaijinService.getKaijinSenseis(kaijinId);
      print('${senseis.length} senseis chargés');
      return senseis;
    } catch (e) {
      print('Erreur lors du chargement des senseis: $e');
      return [];
    }
  }

  // Filtrer les senseis pour obtenir ceux du joueur
  List<Sensei> getPlayerSenseis(List<Sensei> allSenseis, Kaijin kaijin) {
    if (allSenseis.isEmpty || kaijin.senseis.isEmpty) {
      return [];
    }

    final playerSenseis = allSenseis
        .where((sensei) => kaijin.senseis.contains(sensei.id))
        .toList();

    // Mettre à jour les niveaux et quantités de senseis
    for (var sensei in playerSenseis) {
      sensei.level = kaijin.senseiLevels[sensei.id] ?? 1;
      sensei.quantity = kaijin.senseiQuantities[sensei.id] ?? 0;
    }

    return playerSenseis;
  }

  // Acheter un sensei
  Future<bool> acheterSensei(
      Kaijin kaijin, Sensei sensei, int totalXP, Function(int) updateXP) async {
    final cout = sensei.getCurrentCost();
    if (totalXP >= cout && sensei.quantity == 0) {
      updateXP(-cout);
      sensei.quantity += 1;

      try {
        await kaijinService.addSenseiToKaijin(kaijin.id, sensei.id);
        print(
            'Sensei ${sensei.name} ajouté au kaijin ${kaijin.name} (Quantité: ${sensei.quantity})');
        return true;
      } catch (e) {
        print('Erreur lors de l\'achat du sensei: $e');
        sensei.quantity -= 1;
        updateXP(cout); // Rembourser l'XP
        return false;
      }
    }
    return false;
  }

  // Améliorer un sensei
  Future<bool> ameliorerSensei(
      Kaijin kaijin, Sensei sensei, int totalXP, Function(int) updateXP) async {
    final cout = sensei.getCurrentCost() * 2;
    if (totalXP >= cout && sensei.quantity > 0) {
      updateXP(-cout);
      sensei.level += 1;

      try {
        await kaijinService.upgradeSensei(kaijin.id, sensei.id);
        print('Sensei ${sensei.name} amélioré au niveau ${sensei.level}');
        return true;
      } catch (e) {
        print('Erreur lors de l\'amélioration du sensei: $e');
        sensei.level -= 1;
        updateXP(cout); // Rembourser l'XP
        return false;
      }
    }
    return false;
  }

  // Calculer l'XP totale par seconde générée par les senseis
  double calculateTotalXpPerSecond(List<Sensei> senseis) {
    double totalXpPerSecond = 0;
    for (var sensei in senseis) {
      if (sensei.quantity > 0) {
        totalXpPerSecond += sensei.getTotalXpPerSecond();
      }
    }
    return totalXpPerSecond;
  }

  // Calculer le coût d'amélioration d'un sensei
  int calculateUpgradeCost(Sensei sensei) {
    return (sensei.baseCost * (sensei.costMultiplier * sensei.level)).toInt();
  }
}
