# Resume des modifications IA

Ce document resume les modifications implementees pendant les sprints 0, 1, 2 et 3.

## Commits realises

- `ccd2a6b` - stabilise la progression XP et les couts d'upgrade
- `77d2d2b` - fiabilise les flows progression et erreurs utilisateur
- `ae8a23e` - factorise la progression sensei/resonance
- `7ddb079` - ajoute des tests unitaires sur la progression factorisee
- `b712b65` - uniformise routes et centralise les textes de base
- `eab253d` - etend la centralisation i18n sur les ecrans cles

## Sprint 0 - Corrections critiques gameplay/data

### 1) Resonances: correction des couts d'upgrade

- `lib/models/resonance.dart`
  - fallback legacy ajoute: lecture `xpCostToUpgradeLink` puis `baseUpgradeCost`
  - fallback equivalent ajoute dans `fromJson`
- `lib/services/resonance_service.dart`
  - seeds par defaut migrent vers `xpCostToUpgradeLink`
  - migration idempotente runtime `migrateLegacyUpgradeCostField()`
- `lib/migrations/migrate_resonance_upgrade_cost.dart`
  - script de migration dedie pour convertir les docs legacy

### 2) XP/niveau: unification du pipeline

- `lib/screens/game_screen/game_state.dart`
  - tous les gains (clic/passif/offline) passent par `addXP()`
  - ajout de `adjustSpendableXp()` pour depenses/remboursements sans toucher `totalLifetimeXp`
  - sync `currentKaijin.xp` renforcee pendant gains/depenses
- `lib/services/kaijin_service.dart`
  - suppression de l'ancienne logique de level-up `currentLevel * 100`
  - `addXp()` met a jour `xp` et `totalLifetimeXp` uniquement

### 3) Techniques: harmonisation des couts

- `lib/services/technique_service.dart`
  - unlock base sur `xp_unlock_cost`
  - upgrade base sur `technique.getUpgradeCost()`

## Sprint 1 - Robustesse et erreurs explicites

### 1) Logging structure

- `lib/services/app_logger.dart` (nouveau)
  - `info`, `warning`, `error` via `debugPrint`
- integration progressive dans:
  - `kaijin_service.dart`
  - `resonance_service.dart`
  - `sensei_service.dart`
  - `technique_service.dart`
  - `game_state.dart`
  - `technique_tree_state.dart`

### 2) Operations XP atomiques sur l'arbre des techniques

- `lib/screens/technique_tree_screen/technique_tree_state.dart`
  - unlock et upgrade passent en transactions Firestore
  - debit XP + relation pivot effectues atomiquement
  - checks explicites: kaijin introuvable, XP insuffisante, technique non debloquee

### 3) Codes d'erreur explicites et UX de feedback

- `technique_tree_state.dart`
  - codes internes (ex: `ERR_NOT_ENOUGH_XP`, `ERR_INVALID_UPGRADE_COST`, etc.)
  - mapping central vers messages utilisateur
- services `sensei`/`resonance`
  - retours `Future<String?>` (`null` si succes, code sinon)
- `game_state.dart`
  - propagation des codes d'erreur depuis services
- tabs UI
  - `lib/screens/game_screen/widgets/senseis_tab.dart`
  - `lib/screens/game_screen/widgets/resonances_tab.dart`
  - snackbar affichee selon le code d'erreur reel

## Sprint 2 - Factorisation service + UI

### 1) Factorisation metier de progression

- `lib/services/progression_link_service.dart` (nouveau)
  - logique commune unlock/upgrade:
    - validations
    - debit/remboursement XP
    - increment/rollback niveau
    - codes d'erreur standards
    - son de succes
- adoption dans:
  - `sensei_service.dart`
  - `resonance_service.dart`

### 2) Factorisation des messages d'erreur

- `lib/screens/game_screen/widgets/progression_error_messages.dart` (nouveau)
  - mapping unique code -> message utilisateur

### 3) Factorisation du flux UI d'action

- `lib/screens/game_screen/widgets/progression_action_runner.dart` (nouveau)
  - flux commun:
    - start loading
    - execute action
    - refresh
    - sync liste locale
    - afficher snackbar d'erreur
- integration dans:
  - `senseis_tab.dart`
  - `resonances_tab.dart`

## Sprint 3 - Navigation + base i18n

### 1) Uniformisation navigation

- `lib/navigation/app_routes.dart` (nouveau)
  - registre central de routes nommees
- `lib/main.dart`
  - routes principales branchees sur `AppRoutes`
  - `onGenerateRoute` ajoute pour routes avec arguments (`intro_video`, `game`)
- `lib/screens/welcome_screen.dart`
  - remplace plusieurs `MaterialPageRoute` par `pushReplacementNamed`
- `lib/screens/game_screen/widgets/game_app_bar.dart`
  - navigation vers online combat et retour menu via routes nommees

### 2) Centralisation de textes (base i18n)

- `lib/l10n/app_strings.dart` (nouveau)
  - centralise les labels gameplay et messages d'erreur principaux
- integration dans:
  - `game_screen_view.dart` (labels passifs/references sensei-resonance)
  - `progression_error_messages.dart`
  - `technique_tree_state.dart`
  - `welcome_screen.dart`
  - `game_app_bar.dart`

### 3) Nettoyage lie au sprint 3

- suppression d'imports inutilises sur plusieurs ecrans touches
- suppression d'un bloc de dialogue non utilise dans `welcome_screen.dart`

## Tests ajoutes

- `test/services/progression_link_service_test.dart` (nouveau)
  - couverture des scenarios:
    - unlock succes
    - unlock XP insuffisante
    - unlock cout invalide
    - unlock exception + remboursement
    - upgrade succes
    - upgrade echec + rollback
    - upgrade niveau max
    - upgrade non debloque
    - upgrade cout invalide
    - upgrade exception + rollback

## Impact global

- progression plus fiable et coherente entre runtime/UI/persistance
- reduction de duplication importante entre senseis et resonances
- meilleur diagnostic grace au logger structure
- meilleure UX avec erreurs explicites plutot que generiques
- base de tests unitaire pour eviter les regressions sur le moteur de progression
- navigation plus coherente et previsible sur les flux coeur
- base i18n prete a etre etendue ecran par ecran
