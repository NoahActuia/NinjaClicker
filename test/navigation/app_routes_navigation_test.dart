import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ninja_clicker/navigation/app_routes.dart';
import 'package:ninja_clicker/screens/intro_video_screen.dart';

void main() {
  testWidgets('navigates to intro route with playerName argument',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.root,
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.introVideo) {
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            final playerName = args['playerName'] as String? ?? 'Fracturé';
            return MaterialPageRoute(
              builder: (_) => IntroVideoScreen(playerName: playerName),
            );
          }
          return null;
        },
        routes: {
          AppRoutes.root: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.introVideo,
                        arguments: {'playerName': 'Noah'},
                      );
                    },
                    child: const Text('go'),
                  ),
                ),
              ),
        },
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.byType(IntroVideoScreen), findsOneWidget);
  });
}
