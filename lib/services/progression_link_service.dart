typedef ProgressionAction = Future<bool> Function();
typedef ProgressionValueUpdater = void Function(int amount);
typedef ProgressionLevelUpdater = void Function();
typedef ProgressionSoundPlayer = void Function(String assetName);

class ProgressionLinkService {
  static Future<String?> unlockWithXp({
    required int totalXP,
    required int unlockCost,
    required ProgressionValueUpdater updateXP,
    required ProgressionAction unlockAction,
    required ProgressionSoundPlayer playSound,
  }) async {
    if (unlockCost <= 0) return 'ERR_INVALID_UNLOCK_COST';
    if (totalXP < unlockCost) return 'ERR_NOT_ENOUGH_XP';

    updateXP(-unlockCost);

    try {
      final success = await unlockAction();
      if (success) {
        playSound('unlock.mp3');
        return null;
      }

      updateXP(unlockCost);
      return 'ERR_UNLOCK_FAILED';
    } catch (_) {
      updateXP(unlockCost);
      return 'ERR_UNLOCK_EXCEPTION';
    }
  }

  static Future<String?> upgradeWithXp({
    required bool isUnlocked,
    required int currentLevel,
    required int maxLevel,
    required int totalXP,
    required int upgradeCost,
    required ProgressionValueUpdater updateXP,
    required ProgressionLevelUpdater incrementLevel,
    required ProgressionLevelUpdater rollbackLevel,
    required ProgressionAction upgradeAction,
    required ProgressionSoundPlayer playSound,
  }) async {
    if (!isUnlocked) return 'ERR_NOT_UNLOCKED';
    if (currentLevel >= maxLevel) return 'ERR_MAX_LEVEL_REACHED';
    if (upgradeCost <= 0) return 'ERR_INVALID_UPGRADE_COST';
    if (totalXP < upgradeCost) return 'ERR_NOT_ENOUGH_XP';

    updateXP(-upgradeCost);
    incrementLevel();

    try {
      final success = await upgradeAction();
      if (success) {
        playSound('upgrade.mp3');
        return null;
      }

      updateXP(upgradeCost);
      rollbackLevel();
      return 'ERR_UPGRADE_FAILED';
    } catch (_) {
      updateXP(upgradeCost);
      rollbackLevel();
      return 'ERR_UPGRADE_EXCEPTION';
    }
  }
}
