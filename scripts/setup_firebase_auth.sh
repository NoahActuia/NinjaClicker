#!/usr/bin/env bash
# Configuration Firebase Auth pour Kaijin — à lancer depuis NinjaClicker/
set -euo pipefail

echo "=== Kaijin — Configuration Firebase Auth ==="
echo ""

if ! command -v firebase &>/dev/null; then
  echo "❌ Firebase CLI non installé. Installez avec : npm install -g firebase-tools"
  exit 1
fi

PROJECT_ID="ninjaclicker-9bad6"

echo "1. Connexion Firebase..."
firebase login --no-localhost 2>/dev/null || firebase login

echo "2. Sélection du projet $PROJECT_ID..."
firebase use "$PROJECT_ID"

echo "3. Déploiement des Firestore Rules..."
firebase deploy --only firestore:rules

echo ""
echo "✅ Rules déployées."
echo ""
echo "=== Actions MANUELLES dans la Console Firebase ==="
echo ""
echo "📧 TEMPLATES EMAIL (Authentication → Modèles) :"
echo "   → Copier firebase/email-templates/verification-email.html"
echo "   → Copier firebase/email-templates/password-reset.html"
echo "   → Voir firebase/email-templates/README.md"
echo ""
echo "🔐 DOUBLE AUTH (Authentication → Méthode de connexion) :"
echo "   → Cliquer 'Mettre à niveau' (Identity Platform)"
echo "   → Activer Authentification multifacteur → TOTP"
echo ""
echo "🚫 SÉCURITÉ :"
echo "   → Désactiver 'Anonyme'"
echo "   → Garder 'E-mail/Mot de passe' activé"
echo ""
echo "🌐 DOMAINES (Authentication → Paramètres) :"
echo "   → Ajouter ninjaclicker-9bad6.firebaseapp.com"
echo ""
