# Templates email Firebase — Kaijin

Copiez-collez ces textes dans la **Console Firebase** :
**Authentication → Modèles (Templates)**

---

## 1. Vérification de l'adresse e-mail

**Nom de l'expéditeur :** `Kaijin`
**Objet :** `Vérifiez votre compte Kaijin`

**Corps du message (HTML) :** voir `verification-email.html`

**URL d'action :** laisser par défaut (généré par Firebase)

---

## 2. Réinitialisation du mot de passe

**Nom de l'expéditeur :** `Kaijin`
**Objet :** `Réinitialisation de votre mot de passe Kaijin`

**Corps du message (HTML) :** voir `password-reset.html`

---

## 3. Modification de l'adresse e-mail

**Objet :** `Confirmez votre nouvelle adresse email Kaijin`

**Corps :** voir `email-change.html`

---

## 4. Domaines autorisés (important)

**Authentication → Paramètres → Domaines autorisés**

Ajoutez si absent :
- `ninjaclicker-9bad6.firebaseapp.com`
- `localhost` (pour les tests)

---

## 5. Activer la 2FA TOTP

1. **Méthode de connexion** → **Mettre à niveau** (Identity Platform)
2. **Authentification multifacteur** → Activer **TOTP**
3. Enregistrer

---

## 6. Désactiver l'auth anonyme

**Méthode de connexion** → **Anonyme** → Désactiver → Enregistrer
