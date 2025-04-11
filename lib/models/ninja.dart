import 'package:cloud_firestore/cloud_firestore.dart';

class Ninja {
  final String id;
  final String userId;
  final String name;
  int xp;
  int level;
  int strength;
  int agility;
  int chakra;
  int speed;
  int defense;
  int xpPerClick;
  int passiveXp;
  Map<String, String> appearance;

  // Données de classement
  String rank;
  int eloPoints;
  int matchesPlayed;
  int wins;
  int losses;

  Ninja({
    required this.id,
    required this.userId,
    required this.name,
    this.xp = 0,
    this.level = 1,
    this.strength = 10,
    this.agility = 10,
    this.chakra = 10,
    this.speed = 10,
    this.defense = 10,
    this.xpPerClick = 1,
    this.passiveXp = 0,
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
  });

  // Depuis Firestore
  factory Ninja.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Ninja(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      xp: data['xp'] ?? 0,
      level: data['level'] ?? 1,
      strength: data['strength'] ?? 10,
      agility: data['agility'] ?? 10,
      chakra: data['chakra'] ?? 10,
      speed: data['speed'] ?? 10,
      defense: data['defense'] ?? 10,
      xpPerClick: data['xpPerClick'] ?? 1,
      passiveXp: data['passiveXp'] ?? 0,
      appearance: Map<String, String>.from(data['appearance'] ??
          {'skin': 'default', 'headband': 'default', 'weapon': 'default'}),
      rank: data['rank'] ?? 'beginner',
      eloPoints: data['eloPoints'] ?? 1000,
      matchesPlayed: data['matchesPlayed'] ?? 0,
      wins: data['wins'] ?? 0,
      losses: data['losses'] ?? 0,
    );
  }

  // Vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'xp': xp,
      'level': level,
      'strength': strength,
      'agility': agility,
      'chakra': chakra,
      'speed': speed,
      'defense': defense,
      'xpPerClick': xpPerClick,
      'passiveXp': passiveXp,
      'appearance': appearance,
      'rank': rank,
      'eloPoints': eloPoints,
      'matchesPlayed': matchesPlayed,
      'wins': wins,
      'losses': losses,
    };
  }
}
