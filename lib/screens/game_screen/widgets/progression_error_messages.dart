String mapProgressionErrorToMessage(String code, {required String entityLabel}) {
  switch (code) {
    case 'ERR_NOT_ENOUGH_XP':
      return 'XP insuffisante pour cette action.';
    case 'ERR_KAIJIN_NOT_FOUND':
      return 'Kaijin introuvable. Recharge la session.';
    case 'ERR_NOT_UNLOCKED':
      return '$entityLabel non débloqué.';
    case 'ERR_MAX_LEVEL_REACHED':
      return 'Niveau maximum déjà atteint.';
    case 'ERR_INVALID_UNLOCK_COST':
    case 'ERR_INVALID_UPGRADE_COST':
      return 'Coût invalide détecté. Réessaie après synchronisation.';
    default:
      return 'Action impossible pour le moment.';
  }
}
