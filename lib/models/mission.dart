import 'technique.dart';

class Mission {
  final String id;
  final String titre;
  final String description;
  final String image;
  final int puissanceRequise;
  final int recompensePuissance;
  final List<Recompense> recompenses;
  final String? histoire;
  final int? difficulte;
  bool completed = false;

  Mission({
    required this.id,
    required this.titre,
    required this.description,
    required this.image,
    required this.puissanceRequise,
    required this.recompensePuissance,
    required this.recompenses,
    this.histoire,
    this.difficulte,
    this.completed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'description': description,
      'image': image,
      'puissanceRequise': puissanceRequise,
      'recompensePuissance': recompensePuissance,
      'recompenses': recompenses.map((r) => r.toJson()).toList(),
      'histoire': histoire,
      'difficulte': difficulte,
      'completed': completed,
    };
  }

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'],
      titre: json['titre'],
      description: json['description'],
      image: json['image'],
      puissanceRequise: json['puissanceRequise'],
      recompensePuissance: json['recompensePuissance'],
      recompenses: (json['recompenses'] as List)
          .map((r) => Recompense.fromJson(r))
          .toList(),
      histoire: json['histoire'],
      difficulte: json['difficulte'],
      completed: json['completed'] ?? false,
    );
  }
}

class Recompense {
  final String type; // 'technique', 'clone', 'puissance'
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
      'technique': technique?.toJson(),
    };
  }

  factory Recompense.fromJson(Map<String, dynamic> json) {
    return Recompense(
      type: json['type'],
      quantite: json['quantite'],
      technique: json['technique'] != null
          ? Technique.fromJson(json['technique'])
          : null,
    );
  }
}
