import 'package:cloud_firestore/cloud_firestore.dart';

class Kaijin {
  final String id;
  final String userId;
  final String name;
  int xp;
  int level;
  int totalLifetimeXp; // XP totale cumulée depuis la création du personnage
  int strength;
  int agility;
  int kai;
  int speed;
  int defense;
  int xpPerClick;
  double passiveXp;
  int power;
  Map<String, String> appearance;
  DateTime lastConnected;
  DateTime? previousLastConnected;

  // Données de classement
  String rank;
  int eloPoints;
  int matchesPlayed;
  int wins;
  int losses;

  // Données des techniques et senseis
  List<String> techniques = [];
  Map<String, int> techniqueLevels = {};
  List<String> senseis = [];
  Map<String, int> senseiLevels = {};
  Map<String, int> senseiQuantities = {};

  Kaijin({
    required this.id,
    required this.userId,
    required this.name,
    this.xp = 0,
    this.level = 1,
    this.totalLifetimeXp = 0,
    this.strength = 10,
    this.agility = 10,
    this.kai = 10,
    this.speed = 10,
    this.defense = 10,
    this.xpPerClick = 1,
    this.passiveXp = 0,
    this.power = 0,
    this.appearance = const {
      'skin': 'default',
      'headband': 'default',
      'weapon': 'default'
    },
    this.rank = 'beginner',
    this.eloPoints = 1000,
    this.matchesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    DateTime? lastConnected,
    DateTime? previousLastConnected,
  })  : this.lastConnected = lastConnected ?? DateTime.now(),
        this.previousLastConnected = previousLastConnected;

  // Depuis Firestore
  factory Kaijin.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Gérer spécifiquement le cas où passiveXp est un double
    var passiveXpValue = data['passiveXp'];
    double passiveXpInt;

    if (passiveXpValue is double) {
      // Convertir la valeur double en int
      passiveXpInt = passiveXpValue;
    } else {
      // Utiliser la valeur telle quelle (si c'est un int) ou 0 par défaut
      passiveXpInt = (passiveXpValue as double?) ?? 0;
    }

    return Kaijin(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      xp: data['xp'] ?? 0,
      level: data['level'] ?? 1,
      totalLifetimeXp:
          data['totalLifetimeXp'] ?? data['xp'] ?? 0, // Migration progressive
      strength: data['strength'] ?? 10,
      agility: data['agility'] ?? 10,
      kai: data['kai'] ?? 10,
      speed: data['speed'] ?? 10,
      defense: data['defense'] ?? 10,
      xpPerClick: data['xpPerClick'] ?? 1,
      passiveXp: passiveXpInt,
      power: data['power'] ?? 0,
      appearance: Map<String, String>.from(data['appearance'] ??
          {'skin': 'default', 'headband': 'default', 'weapon': 'default'}),
      rank: data['rank'] ?? 'beginner',
      eloPoints: data['eloPoints'] ?? 1000,
      matchesPlayed: data['matchesPlayed'] ?? 0,
      wins: data['wins'] ?? 0,
      losses: data['losses'] ?? 0,
      lastConnected: data['lastConnected'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastConnected'])
          : DateTime.now(),
      previousLastConnected: data['previousLastConnected'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['previousLastConnected'])
          : null,
    )
      ..techniques = List<String>.from(data['techniques'] ?? [])
      ..techniqueLevels = Map<String, int>.from(data['techniqueLevels'] ?? {})
      ..senseis = List<String>.from(data['senseis'] ?? [])
      ..senseiLevels = Map<String, int>.from(data['senseiLevels'] ?? {})
      ..senseiQuantities =
          Map<String, int>.from(data['senseiQuantities'] ?? {});
  }

  // Vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'xp': xp,
      'level': level,
      'totalLifetimeXp': totalLifetimeXp,
      'strength': strength,
      'agility': agility,
      'kai': kai,
      'speed': speed,
      'defense': defense,
      'xpPerClick': xpPerClick,
      'passiveXp': passiveXp,
      'power': power,
      'appearance': appearance,
      'rank': rank,
      'eloPoints': eloPoints,
      'matchesPlayed': matchesPlayed,
      'wins': wins,
      'losses': losses,
      'lastConnected': lastConnected.millisecondsSinceEpoch,
      'previousLastConnected': previousLastConnected?.millisecondsSinceEpoch,
      'techniques': techniques,
      'techniqueLevels': techniqueLevels,
      'senseis': senseis,
      'senseiLevels': senseiLevels,
      'senseiQuantities': senseiQuantities,
    };
  }

  // Calculer le score total du kaijin (pour le classement)
  int getTotalScore() {
    return power > 0 ? power : level * 1000 + xp;
  }

  // Obtenir la classe du kaijin en fonction de son niveau
  String getKaijinClass() {
    if (level >= 50) return 'Éclaireur';
    if (level >= 30) return 'Gardien';
    if (level >= 20) return 'Protecteur';
    if (level >= 10) return 'Initié';
    return 'Novice';
  }

  // Obtenir le rang du kaijin (1er, 2ème, etc.)
  String getFormattedRank() {
    final int rankNum = int.tryParse(rank) ?? 0;
    if (rankNum == 1) return '1er';
    if (rankNum == 2) return '2ème';
    if (rankNum == 3) return '3ème';
    return '${rankNum}ème';
  }
}
