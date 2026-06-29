# Sécurité — NinjaClicker / Kaijin

## Vue d'ensemble

Ce document décrit les mesures de sécurité implémentées dans le projet, pour la soutenance orale et l'audit.

**Architecture :** Application Flutter + Firebase (Auth + Firestore). Pas de backend custom — la sécurité repose sur une **défense en profondeur** :

1. **Firestore Security Rules** (côté serveur Firebase)
2. **Contrôles côté client** (services Dart)
3. **Authentification renforcée** (email vérifié, 2FA TOTP, anti-bruteforce)

---

## Mesures implémentées

### Authentification

| Mesure | Fichier(s) | Description |
|--------|-----------|-------------|
| Mot de passe fort (12+ chars) | `lib/utils/security_config.dart` | Majuscule, minuscule, chiffre, symbole obligatoires |
| Vérification email | `lib/screens/email_verification_screen.dart` | Accès bloqué tant que l'email n'est pas vérifié |
| Double authentification (2FA TOTP) | `lib/services/mfa_service.dart` | Google Authenticator / Authy |
| Reset mot de passe | `lib/screens/forgot_password_screen.dart` | Lien Firebase par email |
| Anti-bruteforce | `lib/services/auth_service.dart` | 5 tentatives → blocage 15 min |
| Messages d'erreur sécurisés | `lib/utils/auth_error_mapper.dart` | Pas de fuite d'infos techniques |

### Autorisation (Firestore Rules)

| Collection | Politique |
|-----------|-----------|
| `users/{uid}` | Lecture/écriture propriétaire uniquement |
| `kaijins/{id}` | CRUD propriétaire + limite XP (+5000 max par update) |
| `techniques`, `senseis`, `resonances` | Lecture seule côté client |
| `challenges` | Participants uniquement |
| `test`, `connection_test` | **Bloqué** |
| Tout le reste | **Refus par défaut** |

Fichier : `firestore.rules`

### Contrôles côté client

| Service | Contrôle |
|---------|----------|
| `SecurityService` | Vérification propriété kaijin, cible de défi |
| `KaijinService` | Ownership avant update/delete/addXp |
| `ChallengeService` | Seul le challenger crée, seule la cible accepte/refuse |

### Durcissement production

| Mesure | Fichier |
|--------|---------|
| Écran debug Firebase désactivé en release | `lib/main.dart` |
| Seed DB client uniquement en debug | `lib/utils/security_config.dart` |
| Route `/firebase_test` absente en release | `lib/main.dart` |

---

## Configuration Firebase requise

### 1. Déployer les Firestore Rules

```bash
cd NinjaClicker
firebase deploy --only firestore:rules
```

### 2. Activer la 2FA TOTP (Identity Platform)

1. Console Firebase → Authentication → Sign-in method
2. Activer **Multi-factor authentication**
3. Activer **TOTP** comme second facteur
4. (Nécessite le plan Blaze / Identity Platform)

### 3. Restreindre les clés API

Console Google Cloud → APIs & Services → Credentials :
- Restreindre par package Android (`com.example.ninja_clicker`)
- Restreindre par bundle iOS
- Restreindre les domaines web autorisés

### 4. Activer la vérification email

Authentication → Templates → Email verification (personnaliser le template)

---

## Pour l'oral : méthodologie pentest

Voir `docs/RAPPORT_PENTEST.md` — rapport type avec vulnérabilités trouvées par des testeurs et corrections apportées.

**Pitch oral suggéré :**

> « Nous avons soumis l'application à un audit de sécurité mené par [X testeurs / notre groupe]. Ils ont identifié [N] vulnérabilités critiques dont l'absence de règles Firestore, la possibilité de modifier les données d'autres joueurs, et l'absence de 2FA. Nous avons corrigé chaque point documenté dans notre rapport de pentest, avec des commits traçables sur Git. »

---

## Limites connues (honnêteté pour le jury)

- La logique de jeu (XP, combats PvP) reste partiellement **client-authoritative** — un attaquant déterminé avec des outils reverse-engineering pourrait tenter de contourner les règles. Les Firestore Rules limitent les dégâts (plafond XP, ownership).
- Pour une sécurité maximale en production : migrer la logique sensible vers **Cloud Functions**.
- La 2FA nécessite Identity Platform (configuration Firebase payante).

---

## Historique des commits sécurité

| Commit | Description |
|--------|-------------|
| `security(rules)` | Firestore rules deny-by-default |
| `security(utils)` | Validation MDP, mapping erreurs, config |
| `security(auth)` | Auth renforcé, MFA, email verification |
| `security(services)` | Ownership checks kaijin + challenges |
| `security(hardening)` | Debug gate, seed DB debug-only |
| `docs(security)` | Documentation + rapport pentest |
