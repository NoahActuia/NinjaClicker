🧩 STRUCTURATION DU JEU NinjaClicker

⚙️ 1. Modules principaux du jeu
Module Description
🎮 Système de clicker Gagne de l’XP en cliquant.
🧍 Création et gestion de ninja Personnalisation initiale du personnage joueur.
🧠 Système de progression Achat de Sensei (passif), de statistiques (caracs), et de techniques.
⚔️ Système de combat (PvE & PvP) Combat tour par tour avec gestion de chakra et enchaînements techniques.
🌐 Mode en ligne Matchmaking, classement mondial, historique de combats.
🛠️ Gestion de techniques Déblocage, combinaison, activation conditionnelle (combo logique).
📈 Système de classement & rangs Système de rangs, classement mondial, saison etc.
🏗️ 2. Structure fonctionnelle détaillée
📍 A. Création & Gestion du Ninja
Nom, apparence (skin, bandeau, armes, etc.)

Stats de base : force, agilité, chakra, vitesse, défense

Techniques possédées (spéciales + auto)

Liste d’items passifs : Sensei, boosts, talismans (évolutif)

📍 B. Système de Clicker
Action principale : Tap = +XP

XP = monnaie centrale

Multiplicateurs :

Par clic

Par Sensei

Par bonus temporels (combo, critiques, etc.)

Stats impactant le click : agilité = vitesse de génération, force = critique...

📍 C. Système de Sensei (Revenus passifs)
Chaque Sensei = génération automatique d’XP

Coût progressif

Possibilité de les améliorer (niv)

Animation ou interaction légère possible (tap sur le Sensei = bonus)

📍 D. Système d’amélioration
Stats : augmenter les caracs (via XP ou autre monnaie secondaire)

Techniques :

Spéciales = chakra, déclenchées manuellement en combat

Auto = déclenchement conditionnel ou aléatoire, combo possibles

📍 E. Gestion des Techniques
Base de données dynamique de techniques (spéciales / auto)

Chaque technique possède :

Nom

Type (spéciale / auto)

Conditions de déclenchement (ex : « après propulsion »)

Effet (dégâts, stun, push, debuff, buff…)

Coût (chakra ou gratuit)

Cooldown

📍 F. Combat tour par tour
⚔️ PvE & PvP :

Initiative (stat vitesse ?)

Interface simple en choix de techniques

Chakra consommé à chaque usage

Techniques auto = détectent les conditions et s’activent seules

Combos : système de « chain logique »

UI : barre de chakra, cooldowns, logs de combat

📍 G. Mode en ligne (PvP)
Matchmaking rapide

Mode classé / amical

Historique de combats

Système anti-abus (temps entre combats, auto-play limite…)

📍 H. Classement mondial
Rang : bronze, argent, or, platine, etc.

Top 100 mondial affiché

Système de points (Elo ou MMR)

Saisons (optionnel) avec récompenses

📍 I. Contenu évolutif
Ajout de nouvelles techniques dynamiquement

Ajout de nouveaux Sensei / équipements

Nouveaux effets (statut, météo, terrain)

Nouveaux modes (arène, tour, boss hebdo...)

🔁 3. Boucle de gameplay (Loop)
Le joueur clique pour XP

Il améliore son ninja : stats, techniques, Sensei

Il teste ses builds en PvE ou PvP

Il grimpe le classement mondial

Il débloque de nouvelles techniques / boosts / apparences

Il recommence avec une meilleure stratégie et automatisation

📦 4. Données à structurer (backend / DB)
Joueurs (id, pseudo, stats, ninja, techniques, classements…)

Techniques (type, effet, coût, condition, visuel…)

Sensei (id, xp/sec, niveau…)

Combats (historique, logs, adversaires…)

Classement (rang, points, saison…)

---
