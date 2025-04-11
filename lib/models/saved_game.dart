import 'package:cloud_firestore/cloud_firestore.dart';
import 'technique.dart';

class SavedGame {
  final String id;
  final String nom; // Pour compatibilité avec le code existant
  final String name; // Nouveau nom en anglais
  final int puissance; // Pour compatibilité avec le code existant
  final int xp; // Nouveau nom en anglais
  final int nombreDeClones; // Pour compatibilité avec le code existant
  final int senseiCount; // Nouveau nom en anglais
  final List<Technique> techniques;
  final DateTime date;

  SavedGame({
    required this.id,
    required this.nom,
    required this.puissance,
    required this.nombreDeClones,
    required this.techniques,
    required this.date,
  })  : name = nom,
        xp = puissance,
        senseiCount = nombreDeClones;

  // Depuis Firestore
  factory SavedGame.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Conversion des techniques
    List<Technique> techniques = [];
    if (data['techniques'] != null) {
      techniques = (data['techniques'] as List)
          .map((t) => Technique.fromJson(t))
          .toList();
    }

    return SavedGame(
      id: doc.id,
      nom: data['nom'] ?? data['name'] ?? '',
      puissance: data['puissance'] ?? data['xp'] ?? 0,
      nombreDeClones: data['nombreDeClones'] ?? data['senseiCount'] ?? 0,
      techniques: techniques,
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  // Vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'name': name,
      'puissance': puissance,
      'xp': xp,
      'nombreDeClones': nombreDeClones,
      'senseiCount': senseiCount,
      'techniques': techniques.map((t) => t.toJson()).toList(),
      'date': Timestamp.fromDate(date),
    };
  }

  // Pour la compatibilité
  Map<String, dynamic> toJson() {
    return toFirestore();
  }

  // Pour la compatibilité
  factory SavedGame.fromJson(Map<String, dynamic> json) {
    return SavedGame(
      id: json['id'] ?? '',
      nom: json['nom'] ?? json['name'] ?? '',
      puissance: json['puissance'] ?? json['xp'] ?? 0,
      nombreDeClones: json['nombreDeClones'] ?? json['senseiCount'] ?? 0,
      techniques: (json['techniques'] as List?)
              ?.map((t) => Technique.fromJson(t))
              .toList() ??
          [],
      date: json['date'] != null
          ? (json['date'] is Timestamp
              ? (json['date'] as Timestamp).toDate()
              : DateTime.parse(json['date']))
          : DateTime.now(),
    );
  }
}
