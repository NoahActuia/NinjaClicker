const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

// Configuration de l'email (à remplacer par vos vrais identifiants)
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.FIREBASE_EMAIL_USER || 'noreply@kaijin-game.fr',
    pass: process.env.FIREBASE_EMAIL_PASSWORD || '',
  },
});

/**
 * Cloud Function : Envoie un email d'alerte à l'inscription
 */
exports.onUserSignup = functions.auth.user().onCreate(async (user) => {
  const email = user.email;
  const displayName = user.displayName || email.split('@')[0];

  const mailOptions = {
    from: 'Kaijin <noreply@kaijin-game.fr>',
    to: email,
    subject: '⚔️ Bienvenue dans Kaijin !',
    html: `
      <!DOCTYPE html>
      <html lang="fr">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        </head>
        <body style="margin:0;padding:0;background:linear-gradient(135deg,#0f172a 0%,#111827 100%);font-family:Arial,Helvetica,sans-serif;color:#f8fafc;">
          <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="padding:40px 20px;">
            <tr>
              <td align="center">
                <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="max-width:600px;background:#111827;border:1px solid #2d3748;border-radius:20px;">
                  <tr>
                    <td style="background:linear-gradient(90deg,#e94560 0%,#ff7a59 100%);padding:32px 30px;text-align:center;">
                      <div style="font-size:42px;line-height:1;margin-bottom:10px;">⚔️</div>
                      <h1 style="margin:0;color:#ffffff;font-size:28px;">Bienvenue dans Kaijin, ${displayName} !</h1>
                      <p style="margin:8px 0 0;color:#fff7ed;font-size:15px;">Votre compte vient d'être créé</p>
                    </td>
                  </tr>
                  <tr>
                    <td style="padding:36px 30px;">
                      <h2 style="margin:0 0 14px;color:#ffffff;font-size:24px;">Inscription confirmée ✓</h2>
                      <p style="margin:0 0 20px;color:#d1d5db;line-height:1.7;">
                        Votre compte Kaijin a bien été créé. N'oublie pas de vérifier ton email pour accéder au jeu !
                      </p>
                      <p style="margin:0 0 8px;color:#94a3b8;font-size:13px;line-height:1.6;">
                        <strong>Email :</strong> ${email}
                      </p>
                      <p style="margin:0 0 20px;color:#64748b;font-size:12px;line-height:1.6;">
                        Si tu n'es pas à l'origine de cette inscription, tu peux ignorer cet email.
                      </p>
                    </td>
                  </tr>
                  <tr>
                    <td style="background:#0a0f1f;padding:20px 30px;text-align:center;border-top:1px solid #1f2937;">
                      <p style="margin:0;color:#64748b;font-size:12px;">
                        © 2026 Kaijin — NinjaClicker. Tous droits réservés.
                      </p>
                    </td>
                  </tr>
                </table>
              </td>
            </tr>
          </table>
        </body>
      </html>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log(`[SIGNUP_EMAIL_SENT] Email d'inscription envoyé à ${email}`);
    
    await admin.firestore().collection('email_logs').add({
      type: 'signup',
      email: email,
      username: displayName,
      uid: user.uid,
      sent: true,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      error: null,
    });
    
    console.log(`[SIGNUP_LOG] Log créé pour ${email}`);
  } catch (error) {
    console.error(`[SIGNUP_EMAIL_ERROR] Erreur lors de l'envoi du mail d'inscription à ${email}:`, error);
    
    try {
      await admin.firestore().collection('email_logs').add({
        type: 'signup',
        email: email,
        username: displayName,
        uid: user.uid,
        sent: false,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        error: error.message,
      });
    } catch (logError) {
      console.error(`[SIGNUP_LOG_ERROR] Impossible de créer le log:`, logError);
    }
  }
});

/**
 * Cloud Function : Envoie un email d'alerte lors de la connexion
 */
exports.notifyLogin = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'L\'utilisateur doit être authentifié.'
    );
  }

  const email = data.email || context.auth.token.email;
  const username = data.username || email.split('@')[0];
  const uid = context.auth.uid;

  if (!email) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Email manquant'
    );
  }

  const mailOptions = {
    from: 'Kaijin <noreply@kaijin-game.fr>',
    to: email,
    subject: '🔐 Nouvelle connexion à Kaijin détectée',
    html: `
      <!DOCTYPE html>
      <html lang="fr">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        </head>
        <body style="margin:0;padding:0;background:linear-gradient(135deg,#0f172a 0%,#111827 100%);font-family:Arial,Helvetica,sans-serif;color:#f8fafc;">
          <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="padding:40px 20px;">
            <tr>
              <td align="center">
                <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="max-width:600px;background:#111827;border:1px solid #2d3748;border-radius:20px;">
                  <tr>
                    <td style="background:linear-gradient(90deg,#38bdf8 0%,#6366f1 100%);padding:32px 30px;text-align:center;">
                      <div style="font-size:42px;line-height:1;margin-bottom:10px;">🔐</div>
                      <h1 style="margin:0;color:#ffffff;font-size:28px;">Nouvelle connexion détectée</h1>
                      <p style="margin:8px 0 0;color:#fff7ed;font-size:15px;">À l'instant</p>
                    </td>
                  </tr>
                  <tr>
                    <td style="padding:36px 30px;">
                      <h2 style="margin:0 0 14px;color:#ffffff;font-size:24px;">Connexion sécurisée</h2>
                      <p style="margin:0 0 20px;color:#d1d5db;line-height:1.7;">
                        Un utilisateur vient de se connecter à ton compte Kaijin. Si ce n'est pas toi, change immédiatement ton mot de passe.
                      </p>
                      <div style="background:#1f2937;border-left:4px solid #38bdf8;padding:16px;border-radius:8px;margin:0 0 20px;">
                        <p style="margin:0 0 8px;color:#94a3b8;font-size:13px;line-height:1.6;">
                          <strong>Pseudo :</strong> ${username}
                        </p>
                        <p style="margin:0 0 8px;color:#94a3b8;font-size:13px;line-height:1.6;">
                          <strong>Email :</strong> ${email}
                        </p>
                        <p style="margin:0;color:#94a3b8;font-size:13px;line-height:1.6;">
                          <strong>Heure :</strong> ${new Date().toLocaleString('fr-FR')}
                        </p>
                      </div>
                      <p style="margin:0 0 8px;color:#64748b;font-size:12px;line-height:1.6;">
                        Si tu suspectes une activité suspecte, change immédiatement ton mot de passe depuis tes paramètres de sécurité.
                      </p>
                    </td>
                  </tr>
                  <tr>
                    <td style="background:#0a0f1f;padding:20px 30px;text-align:center;border-top:1px solid #1f2937;">
                      <p style="margin:0;color:#64748b;font-size:12px;">
                        © 2026 Kaijin — NinjaClicker. Tous droits réservés.
                      </p>
                    </td>
                  </tr>
                </table>
              </td>
            </tr>
          </table>
        </body>
      </html>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log(`[LOGIN_EMAIL_SENT] Email de connexion envoyé à ${email}`);
    
    await admin.firestore().collection('email_logs').add({
      type: 'login',
      email: email,
      username: username,
      uid: uid,
      sent: true,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      error: null,
    });
    
    console.log(`[LOGIN_LOG] Log créé pour ${email}`);
    return { sent: true, message: 'Email de connexion envoyé avec succès' };
  } catch (error) {
    console.error(`[LOGIN_EMAIL_ERROR] Erreur lors de l'envoi du mail de connexion à ${email}:`, error);
    
    try {
      await admin.firestore().collection('email_logs').add({
        type: 'login',
        email: email,
        username: username,
        uid: uid,
        sent: false,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        error: error.message,
      });
    } catch (logError) {
      console.error(`[LOGIN_LOG_ERROR] Impossible de créer le log:`, logError);
    }
    
    return { sent: false, error: error.message };
  }
});
