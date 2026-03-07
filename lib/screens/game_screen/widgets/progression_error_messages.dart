import '../../../l10n/app_strings.dart';

String mapProgressionErrorToMessage(String code, {required String entityLabel}) {
  switch (code) {
    case 'ERR_NOT_ENOUGH_XP':
      return AppStrings.xpInsufficient;
    case 'ERR_KAIJIN_NOT_FOUND':
      return AppStrings.kaijinNotFound;
    case 'ERR_NOT_UNLOCKED':
      return '$entityLabel non débloqué.';
    case 'ERR_MAX_LEVEL_REACHED':
      return AppStrings.maxLevelReached;
    case 'ERR_INVALID_UNLOCK_COST':
    case 'ERR_INVALID_UPGRADE_COST':
      return AppStrings.invalidCostDetected;
    default:
      return AppStrings.actionUnavailable;
  }
}
