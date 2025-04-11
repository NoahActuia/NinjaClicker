import 'dart:convert';
import 'technique.dart';

class SavedGame {
  final String nom;
  final int puissance;
  final int nombreDeClones;
  final List<Technique> techniques;
  final DateTime date;

  SavedGame({
    required this.nom,
    required this.puissance,
    required this.nombreDeClones,
    required this.techniques,
    required this.date,
  });

  // Méthode pour convertir en Map pour la sauvegarde
  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'puissance': puissance,
      'nombreDeClones': nombreDeClones,
      'techniques': techniques.map((t) => t.toJson()).toList(),
      'date': date.toIso8601String(),
    };
  }

  // Méthode pour créer une SavedGame à partir d'un Map
  factory SavedGame.fromJson(Map<String, dynamic> json) {
    return SavedGame(
      nom: json['nom'],
      puissance: json['puissance'],
      nombreDeClones: json['nombreDeClones'],
      techniques: (json['techniques'] as List)
          .map((t) => Technique.fromJson(t))
          .toList(),
      date: DateTime.parse(json['date']),
    );
  }
}
