import 'package:cloud_firestore/cloud_firestore.dart';

/// Migration utilitaire pour harmoniser les coûts d'upgrade des résonances.
/// Convertit le champ legacy `baseUpgradeCost` vers `xpCostToUpgradeLink`.
class MigrateResonanceUpgradeCost {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> run() async {
    try {
      final snapshot = await _firestore.collection('resonances').get();
      if (snapshot.docs.isEmpty) {
        print('Migration résonances: aucune résonance trouvée.');
        return;
      }

      final batch = _firestore.batch();
      int updatedCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final hasCanonicalField = data.containsKey('xpCostToUpgradeLink');
        final legacyValue = data['baseUpgradeCost'];

        if (!hasCanonicalField && legacyValue is num) {
          batch.update(doc.reference, {
            'xpCostToUpgradeLink': legacyValue.toInt(),
          });
          updatedCount++;
        }
      }

      if (updatedCount == 0) {
        print('Migration résonances: aucune mise à jour nécessaire.');
        return;
      }

      await batch.commit();
      print(
          'Migration résonances terminée: $updatedCount document(s) mis à jour.');
    } catch (e) {
      print('Erreur migration résonances xpCostToUpgradeLink: $e');
    }
  }
}
