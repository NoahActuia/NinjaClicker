import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_clicker/services/progression_link_service.dart';

void main() {
  group('ProgressionLinkService.unlockWithXp', () {
    test('returns success and debits xp when unlock works', () async {
      int balance = 100;
      int sounds = 0;

      final result = await ProgressionLinkService.unlockWithXp(
        totalXP: balance,
        unlockCost: 30,
        updateXP: (amount) => balance += amount,
        unlockAction: () async => true,
        playSound: (_) => sounds++,
      );

      expect(result, isNull);
      expect(balance, 70);
      expect(sounds, 1);
    });

    test('returns not enough xp without mutation', () async {
      int balance = 20;
      int sounds = 0;

      final result = await ProgressionLinkService.unlockWithXp(
        totalXP: balance,
        unlockCost: 30,
        updateXP: (amount) => balance += amount,
        unlockAction: () async => true,
        playSound: (_) => sounds++,
      );

      expect(result, 'ERR_NOT_ENOUGH_XP');
      expect(balance, 20);
      expect(sounds, 0);
    });

    test('returns invalid unlock cost when cost is zero or less', () async {
      int balance = 100;

      final result = await ProgressionLinkService.unlockWithXp(
        totalXP: balance,
        unlockCost: 0,
        updateXP: (amount) => balance += amount,
        unlockAction: () async => true,
        playSound: (_) {},
      );

      expect(result, 'ERR_INVALID_UNLOCK_COST');
      expect(balance, 100);
    });

    test('refunds xp when unlock throws', () async {
      int balance = 100;

      final result = await ProgressionLinkService.unlockWithXp(
        totalXP: balance,
        unlockCost: 30,
        updateXP: (amount) => balance += amount,
        unlockAction: () async {
          throw Exception('boom');
        },
        playSound: (_) {},
      );

      expect(result, 'ERR_UNLOCK_EXCEPTION');
      expect(balance, 100);
    });
  });

  group('ProgressionLinkService.upgradeWithXp', () {
    test('returns success and increments level when upgrade works', () async {
      int balance = 120;
      int level = 2;
      int sounds = 0;

      final result = await ProgressionLinkService.upgradeWithXp(
        isUnlocked: true,
        currentLevel: level,
        maxLevel: 10,
        totalXP: balance,
        upgradeCost: 40,
        updateXP: (amount) => balance += amount,
        incrementLevel: () => level++,
        rollbackLevel: () => level = 2,
        upgradeAction: () async => true,
        playSound: (_) => sounds++,
      );

      expect(result, isNull);
      expect(balance, 80);
      expect(level, 3);
      expect(sounds, 1);
    });

    test('rolls back xp and level when upgrade action fails', () async {
      int balance = 120;
      int level = 2;

      final result = await ProgressionLinkService.upgradeWithXp(
        isUnlocked: true,
        currentLevel: level,
        maxLevel: 10,
        totalXP: balance,
        upgradeCost: 40,
        updateXP: (amount) => balance += amount,
        incrementLevel: () => level++,
        rollbackLevel: () => level = 2,
        upgradeAction: () async => false,
        playSound: (_) {},
      );

      expect(result, 'ERR_UPGRADE_FAILED');
      expect(balance, 120);
      expect(level, 2);
    });

    test('returns max level reached when already capped', () async {
      int balance = 120;
      int level = 5;

      final result = await ProgressionLinkService.upgradeWithXp(
        isUnlocked: true,
        currentLevel: level,
        maxLevel: 5,
        totalXP: balance,
        upgradeCost: 40,
        updateXP: (amount) => balance += amount,
        incrementLevel: () => level++,
        rollbackLevel: () => level = 5,
        upgradeAction: () async => true,
        playSound: (_) {},
      );

      expect(result, 'ERR_MAX_LEVEL_REACHED');
      expect(balance, 120);
      expect(level, 5);
    });

    test('returns not unlocked when entity is locked', () async {
      int balance = 120;
      int level = 1;

      final result = await ProgressionLinkService.upgradeWithXp(
        isUnlocked: false,
        currentLevel: level,
        maxLevel: 5,
        totalXP: balance,
        upgradeCost: 20,
        updateXP: (amount) => balance += amount,
        incrementLevel: () => level++,
        rollbackLevel: () => level = 1,
        upgradeAction: () async => true,
        playSound: (_) {},
      );

      expect(result, 'ERR_NOT_UNLOCKED');
      expect(balance, 120);
      expect(level, 1);
    });

    test('returns invalid upgrade cost when cost is zero or less', () async {
      int balance = 120;
      int level = 1;

      final result = await ProgressionLinkService.upgradeWithXp(
        isUnlocked: true,
        currentLevel: level,
        maxLevel: 5,
        totalXP: balance,
        upgradeCost: 0,
        updateXP: (amount) => balance += amount,
        incrementLevel: () => level++,
        rollbackLevel: () => level = 1,
        upgradeAction: () async => true,
        playSound: (_) {},
      );

      expect(result, 'ERR_INVALID_UPGRADE_COST');
      expect(balance, 120);
      expect(level, 1);
    });

    test('rolls back xp and level when upgrade throws', () async {
      int balance = 120;
      int level = 2;

      final result = await ProgressionLinkService.upgradeWithXp(
        isUnlocked: true,
        currentLevel: level,
        maxLevel: 10,
        totalXP: balance,
        upgradeCost: 40,
        updateXP: (amount) => balance += amount,
        incrementLevel: () => level++,
        rollbackLevel: () => level = 2,
        upgradeAction: () async {
          throw Exception('boom');
        },
        playSound: (_) {},
      );

      expect(result, 'ERR_UPGRADE_EXCEPTION');
      expect(balance, 120);
      expect(level, 2);
    });
  });
}
