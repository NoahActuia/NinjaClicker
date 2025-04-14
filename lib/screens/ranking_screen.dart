import 'package:flutter/material.dart';
import '../models/ninja.dart';
import '../services/ninja_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../styles/kai_colors.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({Key? key}) : super(key: key);

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final NinjaService _ninjaService = NinjaService();
  List<Ninja> _rankedNinjas = [];
  bool _isLoading = true;
  String? _currentUserId;
  String _sortFilter = 'level'; // 'level' ou 'score'

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _loadRanking();
  }

  void _getCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
    }
  }

  Future<void> _loadRanking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final ninjas = await _ninjaService.getAllNinjasRankedByLevel();

      setState(() {
        _rankedNinjas = ninjas;

        // Trier selon le filtre actuel
        if (_sortFilter == 'score') {
          _rankedNinjas
              .sort((a, b) => b.getTotalScore().compareTo(a.getTotalScore()));
          // Mettre à jour les rangs
          for (int i = 0; i < _rankedNinjas.length; i++) {
            _rankedNinjas[i].rank = (i + 1).toString();
          }
        }

        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement du classement: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KaiColors.background,
      appBar: AppBar(
        title: const Text(
          'Classement des Fracturés',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: KaiColors.textPrimary,
          ),
        ),
        backgroundColor: KaiColors.primaryDark,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                KaiColors.primaryDark,
                KaiColors.accent.withOpacity(0.2),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: KaiColors.accent),
            onPressed: _loadRanking,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: KaiColors.accent,
                    ),
                  )
                : _buildRankingList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: KaiColors.primaryDark,
        boxShadow: [
          BoxShadow(
            color: KaiColors.accent.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'Trier par:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: KaiColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          _buildFilterChip(
            label: 'Niveau',
            value: 'level',
            icon: Icons.power,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Score Total',
            value: 'score',
            icon: Icons.score,
          ),
          const Spacer(),
          if (!_isLoading && _rankedNinjas.isNotEmpty)
            Text(
              '${_rankedNinjas.length} fracturés',
              style: const TextStyle(
                color: KaiColors.textSecondary,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final bool isSelected = _sortFilter == value;

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : KaiColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : KaiColors.textSecondary,
            ),
          ),
        ],
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _sortFilter = value;

            // Trier la liste selon le nouveau filtre
            if (value == 'level') {
              _rankedNinjas.sort((a, b) {
                if (a.level != b.level) {
                  return b.level.compareTo(a.level);
                }
                return b.xp.compareTo(a.xp);
              });
            } else if (value == 'score') {
              _rankedNinjas.sort(
                  (a, b) => b.getTotalScore().compareTo(a.getTotalScore()));
            }

            // Mettre à jour les rangs
            for (int i = 0; i < _rankedNinjas.length; i++) {
              _rankedNinjas[i].rank = (i + 1).toString();
            }
          });
        }
      },
      backgroundColor: KaiColors.cardBackground,
      selectedColor: KaiColors.accent,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : KaiColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildRankingList() {
    if (_rankedNinjas.isEmpty) {
      return const Center(
        child: Text(
          'Aucun ninja dans le classement',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    // Trouver le rang du ninja actuel
    int? currentUserRank;
    for (int i = 0; i < _rankedNinjas.length; i++) {
      if (_rankedNinjas[i].userId == _currentUserId) {
        currentUserRank = i + 1;
        break;
      }
    }

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.webp'),
              fit: BoxFit.cover,
              opacity: 0.2,
            ),
          ),
          child: ListView.builder(
            itemCount: _rankedNinjas.length,
            itemBuilder: (context, index) {
              final ninja = _rankedNinjas[index];
              final isCurrentUser = ninja.userId == _currentUserId;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: isCurrentUser ? 8 : 2,
                color: isCurrentUser ? Colors.amber.shade50 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isCurrentUser
                      ? BorderSide(color: Colors.amber.shade400, width: 2)
                      : BorderSide.none,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: _buildRankingBadge(index + 1),
                  title: Row(
                    children: [
                      Text(
                        ninja.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isCurrentUser
                              ? Colors.deepOrange.shade800
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isCurrentUser)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.shade800,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Vous',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.military_tech,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ninja.getNinjaClass(),
                            style: TextStyle(
                              color: _getLevelColor(ninja.level),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.flash_on,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Score: ${ninja.getTotalScore()}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getLevelColor(ninja.level),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Niveau ${ninja.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Afficher un message indiquant le rang du joueur actuel
        if (currentUserRank != null)
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.deepOrange.shade800,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Votre rang: ${currentUserRank}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRankingBadge(int rank) {
    Color badgeColor;
    IconData? badgeIcon;

    // Déterminer la couleur et l'icône en fonction du rang
    if (rank == 1) {
      badgeColor = Colors.amber;
      badgeIcon = Icons.emoji_events;
    } else if (rank == 2) {
      badgeColor = Colors.grey.shade300;
      badgeIcon = Icons.emoji_events;
    } else if (rank == 3) {
      badgeColor = Colors.brown.shade300;
      badgeIcon = Icons.emoji_events;
    } else {
      badgeColor = Colors.blue.shade100;
      badgeIcon = null;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: badgeIcon != null
            ? Icon(badgeIcon, color: Colors.white)
            : Text(
                rank.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // Obtenir une couleur en fonction du niveau
  Color _getLevelColor(int level) {
    if (level >= 50) return Colors.red.shade800;
    if (level >= 30) return Colors.purple.shade700;
    if (level >= 20) return Colors.indigo.shade700;
    if (level >= 10) return Colors.blue.shade700;
    if (level >= 5) return Colors.green.shade700;
    return Colors.grey.shade700;
  }
}
