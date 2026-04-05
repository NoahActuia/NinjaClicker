import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_clicker/screens/game_screen/widgets/progression_action_runner.dart';

Widget _buildHarness({required VoidCallback onPressed}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: onPressed,
            child: const Text('run'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('runProgressionAction executes full success flow',
      (WidgetTester tester) async {
    bool loadingStarted = false;
    bool loadingEnded = false;
    bool synced = false;

    await tester.pumpWidget(
      _buildHarness(
        onPressed: () async {
          final context = tester.element(find.byType(ElevatedButton));
          await runProgressionAction<String>(
            context: context,
            action: (_) async => null,
            refresh: () async {},
            onLoadingStart: () => loadingStarted = true,
            onLoadingEnd: () => loadingEnded = true,
            syncLocalState: () => synced = true,
            entity: 'entity',
            entityLabel: 'Sensei',
          );
        },
      ),
    );

    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();

    expect(loadingStarted, isTrue);
    expect(loadingEnded, isTrue);
    expect(synced, isTrue);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('runProgressionAction shows snackbar on domain error',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildHarness(
        onPressed: () async {
          final context = tester.element(find.byType(ElevatedButton));
          await runProgressionAction<String>(
            context: context,
            action: (_) async => 'ERR_NOT_ENOUGH_XP',
            refresh: () async {},
            onLoadingStart: () {},
            onLoadingEnd: () {},
            syncLocalState: () {},
            entity: 'entity',
            entityLabel: 'Sensei',
          );
        },
      ),
    );

    await tester.tap(find.text('run'));
    await tester.pumpAndSettle();

    expect(find.text('XP insuffisante pour cette action.'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
