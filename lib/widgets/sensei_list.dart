import 'package:flutter/material.dart';
import '../models/sensei.dart';

class SenseiList extends StatelessWidget {
  final List<Sensei> senseis;
  final int puissance;
  final Function(Sensei) onAcheterSensei;
  final Function(Sensei) onAmeliorerSensei;

  const SenseiList({
    super.key,
    required this.senseis,
    required this.puissance,
    required this.onAcheterSensei,
    required this.onAmeliorerSensei,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Senseis',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 10),
          senseis.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun sensei disponible pour le moment',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                    itemCount: senseis.length,
                    itemBuilder: (context, index) {
                      final sensei = senseis[index];
                      return SenseiCard(
                        sensei: sensei,
                        puissance: puissance,
                        onAcheterSensei: onAcheterSensei,
                        onAmeliorerSensei: onAmeliorerSensei,
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}

class SenseiCard extends StatelessWidget {
  final Sensei sensei;
  final int puissance;
  final Function(Sensei) onAcheterSensei;
  final Function(Sensei) onAmeliorerSensei;

  const SenseiCard({
    super.key,
    required this.sensei,
    required this.puissance,
    required this.onAcheterSensei,
    required this.onAmeliorerSensei,
  });

  @override
  Widget build(BuildContext context) {
    final currentCost = sensei.getCurrentCost();
    final upgradeCost = currentCost * 2;
    final canBuy = puissance >= currentCost;
    final canUpgrade = puissance >= upgradeCost && sensei.quantity > 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Image du sensei (à remplacer par une vraie image)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person, color: Colors.blue),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sensei.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        sensei.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (sensei.quantity > 0)
                        Text(
                          'Niveau ${sensei.level} • ${sensei.quantity} ${sensei.quantity > 1 ? 'exemplaires' : 'exemplaire'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                          ),
                        ),
                      Text(
                        '+${sensei.getTotalXpPerSecond()} XP/sec',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: canBuy ? () => onAcheterSensei(sensei) : null,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: Text('Acheter (${currentCost} XP)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (sensei.quantity > 0)
                  ElevatedButton.icon(
                    onPressed:
                        canUpgrade ? () => onAmeliorerSensei(sensei) : null,
                    icon: const Icon(Icons.upgrade),
                    label: Text('Améliorer (${upgradeCost} XP)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
