import 'package:flutter/material.dart';
import 'technique_tree_state.dart';
import 'technique_tree_screen_view.dart';

/// Widget principal de l'écran des techniques
class TechniqueTreeScreen extends StatefulWidget {
  const TechniqueTreeScreen({Key? key}) : super(key: key);

  @override
  _TechniqueTreeScreenState createState() => _TechniqueTreeScreenState();
}

class _TechniqueTreeScreenState extends State<TechniqueTreeScreen> {
  late TechniqueTreeState _state;

  @override
  void initState() {
    super.initState();

    // Initialiser l'état avec une fonction de rappel pour mettre à jour l'interface
    _state = TechniqueTreeState(
      setState: (callback) {
        if (mounted) {
          setState(callback);
        }
      },
    );

    // Lancer l'initialisation des données
    _initialize();
  }

  // Méthode d'initialisation des données
  Future<void> _initialize() async {
    await _state.initialize();
  }

  @override
  Widget build(BuildContext context) {
    // Déléguer l'affichage à la vue
    return TechniqueTreeScreenView(
      state: _state,
    );
  }
}
