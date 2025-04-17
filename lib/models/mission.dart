import 'technique.dart';

class Recompense {
  final String type;
  final int quantite;
  final Technique? technique;

  Recompense({
    required this.type,
    required this.quantite,
    this.technique,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'quantite': quantite,
      if (technique != null) 'technique': technique!.toJson(),
    };
  }

  factory Recompense.fromJson(Map<String, dynamic> json) {
    return Recompense(
      type: json['type'] as String,
      quantite: json['quantite'] as int,
      technique: json['technique'] != null
          ? Technique.fromJson(json['technique'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Mission {
  final dynamic id;
  final String name;
  final String description;
  final int difficulty;
  final Map<String, dynamic> rewards;
  final int enemyLevel;
  final String? image;
  final String? histoire;
  bool completed;
  final int puissanceRequise;
  final List<Recompense> recompenses;
  final int recompensePuissance;

  Mission({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.rewards,
    required this.enemyLevel,
    this.image,
    this.histoire,
    this.completed = false,
    this.puissanceRequise = 0,
    List<Recompense>? recompenses,
    this.recompensePuissance = 0,
  }) : recompenses = recompenses ?? [];

  // Getters pour la compatibilité
  String get titre => name;
  int get difficulte => difficulty;

  // Convertir une Map en objet Mission
  factory Mission.fromMap(Map<String, dynamic> map) {
    return Mission(
      id: map['id'],
      name: map['name'] as String,
      description: map['description'] as String,
      difficulty: map['difficulty'] as int,
      rewards: Map<String, dynamic>.from(map['rewards'] as Map),
      enemyLevel: map['enemyLevel'] as int,
      image: map['image'] as String?,
      histoire: map['histoire'] as String?,
      completed: map['completed'] as bool? ?? false,
      puissanceRequise: map['puissanceRequise'] as int? ?? 0,
      recompenses: (map['recompenses'] as List<dynamic>?)
              ?.map((e) => Recompense.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recompensePuissance: map['recompensePuissance'] as int? ?? 0,
    );
  }

  // Convertir l'objet Mission en Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'difficulty': difficulty,
      'rewards': rewards,
      'enemyLevel': enemyLevel,
      'image': image,
      'histoire': histoire,
      'completed': completed,
      'puissanceRequise': puissanceRequise,
      'recompenses': recompenses.map((r) => r.toJson()).toList(),
      'recompensePuissance': recompensePuissance,
    };
  }

  // Méthodes de sérialisation JSON
  factory Mission.fromJson(Map<String, dynamic> json) => Mission.fromMap(json);
  Map<String, dynamic> toJson() => toMap();
}
