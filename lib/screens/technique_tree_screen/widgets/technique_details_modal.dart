import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../models/technique.dart';
import '../../../styles/kai_colors.dart';
import '../technique_tree_state.dart';
import 'info_card.dart';

/// Widget pour afficher les détails d'une technique dans une modale
class TechniqueDetailsModal extends StatefulWidget {
  final Technique technique;
  final TechniqueTreeState state;
  final bool isUnlocked;
  final int techLevel;
  final int upgradeCost;
  final int currentPower;
  final int nextLevelPower;

  const TechniqueDetailsModal({
    Key? key,
    required this.technique,
    required this.state,
    required this.isUnlocked,
    required this.techLevel,
    required this.upgradeCost,
    required this.currentPower,
    required this.nextLevelPower,
  }) : super(key: key);

  @override
  _TechniqueDetailsModalState createState() => _TechniqueDetailsModalState();
}

class _TechniqueDetailsModalState extends State<TechniqueDetailsModal> {
  late int _techLevel;
  late int _upgradeCost;
  late int _currentPower;
  late int _nextLevelPower;

  @override
  void initState() {
    super.initState();
    _techLevel = widget.techLevel;
    _upgradeCost = widget.upgradeCost;
    _currentPower = widget.currentPower;
    _nextLevelPower = widget.nextLevelPower;
  }

  // Fonction pour actualiser les données de la modale
  Future<void> _refreshTechniqueDetails() async {
    try {
      if (widget.state.kaijinId.isEmpty || !widget.isUnlocked) return;

      final relations = await widget.state
          .getKaijinTechniquesForTechnique(widget.technique.id);

      if (relations.isNotEmpty) {
        final kaijinTechnique = relations.first;
        setState(() {
          _techLevel = kaijinTechnique.level;
          _upgradeCost = widget.technique.getUpgradeCost();
          double powerMultiplier = 1.0 + (0.25 * (_techLevel - 1));
          _currentPower = (widget.technique.damage * powerMultiplier).round();
          _nextLevelPower =
              (widget.technique.damage * (powerMultiplier + 0.25)).round();
        });
      }
    } catch (e) {
      print('Erreur lors de l\'actualisation des détails de la technique: $e');
    }
  }

  // Fonction pour améliorer la technique depuis la modale
  Future<void> _upgradeFromModal() async {
    await widget.state
        .upgradeTechnique(context, widget.technique, _techLevel, _upgradeCost);
    // Actualiser les données de la modale sans la fermer
    await _refreshTechniqueDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: KaiColors.primaryDark,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec le nom de la technique
          _buildHeader(),

          // Contenu principal
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status de débloquage
                  _buildLockStatus(),
                  SizedBox(height: 16),

                  // Description
                  _buildDescription(),
                  SizedBox(height: 24),

                  // Type et Affinité
                  _buildTypeAffinityRow(),
                  SizedBox(height: 12),

                  // Coût et Cooldown
                  _buildCostCooldownRow(),
                  SizedBox(height: 24),

                  // Statistiques (basées sur le niveau)
                  _buildStatsSection(),

                  // Niveau et progression (si débloqué)
                  if (widget.isUnlocked) _buildUpgradeSection(),

                  // Bouton de débloquage (uniquement si non débloqué)
                  if (!widget.isUnlocked) _buildUnlockButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KaiColors.primaryDark,
            KaiColors.accent.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.technique.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: KaiColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  widget.technique.affinity ?? 'Neutre',
                  style: TextStyle(
                    fontSize: 14,
                    color: KaiColors.accent,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: KaiColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLockStatus() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isUnlocked
            ? KaiColors.success.withOpacity(0.1)
            : KaiColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isUnlocked
              ? KaiColors.success.withOpacity(0.5)
              : KaiColors.accent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.isUnlocked ? Icons.check_circle : Icons.lock,
            color: widget.isUnlocked ? KaiColors.success : KaiColors.accent,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.isUnlocked
                  ? 'Technique débloquée (Niveau $_techLevel)'
                  : 'Technique verrouillée',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.isUnlocked ? KaiColors.success : KaiColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: KaiColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Text(
          widget.technique.description,
          style: TextStyle(
            fontSize: 16,
            color: KaiColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeAffinityRow() {
    return Row(
      children: [
        InfoCard(
          label: 'Type',
          value: widget.technique.type.toUpperCase(),
          icon: Icons.category,
          color: KaiColors.accent,
        ),
        SizedBox(width: 12),
        InfoCard(
          label: 'Affinité',
          value: widget.technique.affinity ?? 'Aucune',
          icon: Icons.architecture,
          color: KaiColors.accent,
        ),
      ],
    );
  }

  Widget _buildCostCooldownRow() {
    return Row(
      children: [
        InfoCard(
          label: 'Coût',
          value: '${widget.technique.cost_kai} Kai',
          icon: Icons.attach_money,
          color: KaiColors.accent,
        ),
        SizedBox(width: 12),
        InfoCard(
          label: 'Récupération',
          value: '${widget.technique.cooldown} tours',
          icon: Icons.timer,
          color: KaiColors.accent,
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Effets et Dégâts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: KaiColors.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: KaiColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: KaiColors.accent.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dégâts de base:',
                    style: TextStyle(
                      fontSize: 16,
                      color: KaiColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${widget.technique.damage}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: KaiColors.accent,
                    ),
                  ),
                ],
              ),

              // Afficher les conditions générées et déclencheurs
              if (widget.technique.condition_generated != null) ...[
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Condition générée:',
                      style: TextStyle(
                        fontSize: 16,
                        color: KaiColors.textSecondary,
                      ),
                    ),
                    Text(
                      widget.technique.condition_generated!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: KaiColors.success,
                      ),
                    ),
                  ],
                ),
              ],

              if (widget.technique.trigger_condition != null) ...[
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Déclencheur:',
                      style: TextStyle(
                        fontSize: 16,
                        color: KaiColors.textSecondary,
                      ),
                    ),
                    Text(
                      widget.technique.trigger_condition!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: KaiColors.error,
                      ),
                    ),
                  ],
                ),
              ],

              if (widget.isUnlocked) ...[
                SizedBox(height: 16),
                Divider(
                  color: KaiColors.accent.withOpacity(0.3),
                  thickness: 1,
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dégâts actuels:',
                      style: TextStyle(
                        fontSize: 16,
                        color: KaiColors.textSecondary,
                      ),
                    ),
                    Text(
                      '$_currentPower',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: KaiColors.accent,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dégâts niveau suivant:',
                      style: TextStyle(
                        fontSize: 16,
                        color: KaiColors.textSecondary,
                      ),
                    ),
                    Text(
                      '$_nextLevelPower',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: KaiColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpgradeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24),
        Text(
          'Niveau et Amélioration',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: KaiColors.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: KaiColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: KaiColors.accent.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Niveau actuel
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Niveau actuel:',
                    style: TextStyle(
                      fontSize: 16,
                      color: KaiColors.textSecondary,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: KaiColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_techLevel / ${widget.technique.max_level}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: KaiColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Barre de progression
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _techLevel / widget.technique.max_level,
                  backgroundColor: KaiColors.accent.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(KaiColors.accent),
                  minHeight: 8,
                ),
              ),
              SizedBox(height: 16),
              // Coût d'amélioration
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Coût pour améliorer:',
                    style: TextStyle(
                      fontSize: 16,
                      color: KaiColors.textSecondary,
                    ),
                  ),
                  Text(
                    '$_upgradeCost XP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.state.playerXp >= _upgradeCost
                          ? KaiColors.success
                          : KaiColors.error,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Bouton d'amélioration
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _techLevel < widget.technique.max_level &&
                          widget.state.playerXp >= _upgradeCost
                      ? () => _upgradeFromModal()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KaiColors.success,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _techLevel >= widget.technique.max_level
                        ? 'Niveau Maximum Atteint'
                        : widget.state.playerXp >= _upgradeCost
                            ? 'Améliorer (Niveau ${_techLevel + 1})'
                            : 'XP Insuffisante',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnlockButton() {
    return Container(
      padding: EdgeInsets.all(16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: widget.state.playerXp >= widget.technique.xp_unlock_cost
            ? () {
                Navigator.pop(context);
                widget.state.unlockTechnique(context, widget.technique);
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: KaiColors.success,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_open),
            SizedBox(width: 8),
            Text(
              widget.state.playerXp >= widget.technique.xp_unlock_cost
                  ? 'Débloquer (${widget.technique.xp_unlock_cost} XP)'
                  : 'XP insuffisante (${widget.state.playerXp}/${widget.technique.xp_unlock_cost})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
