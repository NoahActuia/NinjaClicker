import 'dart:convert';

class Technique {
  final String nom;
  final String description;
  final int cout;
  final int puissanceParSeconde;
  final String son;
  int niveau = 0;

  Technique({
    required this.nom,
    required this.description,
    required this.cout,
    required this.puissanceParSeconde,
    required this.son,
  });

  // Méthode pour convertir en Map pour la sauvegarde
  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'description': description,
      'cout': cout,
      'puissanceParSeconde': puissanceParSeconde,
      'son': son,
      'niveau': niveau,
    };
  }

  // Méthode pour créer une Technique à partir d'un Map
  factory Technique.fromJson(Map<String, dynamic> json) {
    Technique technique = Technique(
      nom: json['nom'],
      description: json['description'],
      cout: json['cout'],
      puissanceParSeconde: json['puissanceParSeconde'],
      son: json['son'],
    );
    technique.niveau = json['niveau'];
    return technique;
  }
}
