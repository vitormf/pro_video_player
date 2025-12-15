import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_video_player/pro_video_player.dart';

void main() {
  group('CastButton', () {
    group('default values', () {
      test('default size is 24.0', () {
        const button = CastButton();
        expect(button.size, 24.0);
      });

      test('default alwaysVisible is false', () {
        const button = CastButton();
        expect(button.alwaysVisible, isFalse);
      });

      test('default tintColor is null', () {
        const button = CastButton();
        expect(button.tintColor, isNull);
      });

      test('default activeTintColor is null', () {
        const button = CastButton();
        expect(button.activeTintColor, isNull);
      });

      test('default callbacks are null', () {
        const button = CastButton();
        expect(button.onCastStateChanged, isNull);
        expect(button.onWillBeginPresentingRoutes, isNull);
        expect(button.onDidEndPresentingRoutes, isNull);
      });
    });

    group('properties', () {
      test('stores custom tintColor', () {
        const button = CastButton(tintColor: Colors.red);
        expect(button.tintColor, Colors.red);
      });

      test('stores custom activeTintColor', () {
        const button = CastButton(activeTintColor: Colors.blue);
        expect(button.activeTintColor, Colors.blue);
      });

      test('stores custom size', () {
        const button = CastButton(size: 48);
        expect(button.size, 48);
      });

      test('stores alwaysVisible true', () {
        const button = CastButton(alwaysVisible: true);
        expect(button.alwaysVisible, isTrue);
      });

      test('stores all custom parameters', () {
        void onCastStateChanged(String state) {}
        void onWillBegin() {}
        void onDidEnd() {}

        final button = CastButton(
          tintColor: Colors.red,
          activeTintColor: Colors.green,
          size: 32,
          alwaysVisible: true,
          onCastStateChanged: onCastStateChanged,
          onWillBeginPresentingRoutes: onWillBegin,
          onDidEndPresentingRoutes: onDidEnd,
        );

        expect(button.tintColor, Colors.red);
        expect(button.activeTintColor, Colors.green);
        expect(button.size, 32);
        expect(button.alwaysVisible, isTrue);
        expect(button.onCastStateChanged, onCastStateChanged);
        expect(button.onWillBeginPresentingRoutes, onWillBegin);
        expect(button.onDidEndPresentingRoutes, onDidEnd);
      });
    });

    group('construction', () {
      testWidgets('creates with default parameters', (tester) async {
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CastButton())));

        expect(find.byType(CastButton), findsOneWidget);
      });

      testWidgets('creates with custom tintColor', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: CastButton(tintColor: Colors.red)),
          ),
        );

        expect(find.byType(CastButton), findsOneWidget);
      });

      testWidgets('creates with custom activeTintColor', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: CastButton(activeTintColor: Colors.blue)),
          ),
        );

        expect(find.byType(CastButton), findsOneWidget);
      });

      testWidgets('creates with custom size', (tester) async {
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CastButton(size: 48))));

        expect(find.byType(CastButton), findsOneWidget);
      });

      testWidgets('creates with alwaysVisible true', (tester) async {
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CastButton(alwaysVisible: true))));

        expect(find.byType(CastButton), findsOneWidget);
      });

      testWidgets('creates with all custom parameters', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CastButton(
                tintColor: Colors.red,
                activeTintColor: Colors.green,
                size: 32,
                alwaysVisible: true,
                onCastStateChanged: (state) {},
                onWillBeginPresentingRoutes: () {},
                onDidEndPresentingRoutes: () {},
              ),
            ),
          ),
        );

        expect(find.byType(CastButton), findsOneWidget);
      });
    });

    group('callbacks', () {
      testWidgets('onCastStateChanged callback is stored', (tester) async {
        var callbackCalled = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CastButton(
                onCastStateChanged: (state) {
                  callbackCalled = true;
                },
              ),
            ),
          ),
        );

        // The callback won't be called in test environment,
        // but we verify it's accepted
        expect(find.byType(CastButton), findsOneWidget);
        expect(callbackCalled, isFalse); // Not called yet
      });

      testWidgets('onWillBeginPresentingRoutes callback is stored', (tester) async {
        var callbackCalled = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CastButton(
                onWillBeginPresentingRoutes: () {
                  callbackCalled = true;
                },
              ),
            ),
          ),
        );

        expect(find.byType(CastButton), findsOneWidget);
        expect(callbackCalled, isFalse);
      });

      testWidgets('onDidEndPresentingRoutes callback is stored', (tester) async {
        var callbackCalled = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CastButton(
                onDidEndPresentingRoutes: () {
                  callbackCalled = true;
                },
              ),
            ),
          ),
        );

        expect(find.byType(CastButton), findsOneWidget);
        expect(callbackCalled, isFalse);
      });
    });

    group('widget lifecycle', () {
      testWidgets('disposes without error', (tester) async {
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CastButton())));

        // Replace with different widget to trigger dispose
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));

        expect(find.byType(CastButton), findsNothing);
      });

      testWidgets('can be rebuilt with different parameters', (tester) async {
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CastButton(size: 20))));

        expect(find.byType(CastButton), findsOneWidget);

        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CastButton(size: 48))));

        expect(find.byType(CastButton), findsOneWidget);
      });
    });

    group('widget tree', () {
      testWidgets('can be placed in Row', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: Row(children: [CastButton(), SizedBox(width: 8), Text('Cast')])),
          ),
        );

        expect(find.byType(CastButton), findsOneWidget);
        expect(find.text('Cast'), findsOneWidget);
      });

      testWidgets('can be placed in Column', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: Column(children: [CastButton(), SizedBox(height: 8), Text('Cast')])),
          ),
        );

        expect(find.byType(CastButton), findsOneWidget);
        expect(find.text('Cast'), findsOneWidget);
      });

      testWidgets('can be placed in IconButton', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: IconButton(onPressed: () {}, icon: const CastButton()),
            ),
          ),
        );

        expect(find.byType(CastButton), findsOneWidget);
        expect(find.byType(IconButton), findsOneWidget);
      });
    });

    group('multiple instances', () {
      testWidgets('can render multiple CastButtons', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  CastButton(key: Key('cast1')),
                  CastButton(key: Key('cast2')),
                  CastButton(key: Key('cast3')),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(CastButton), findsNWidgets(3));
        expect(find.byKey(const Key('cast1')), findsOneWidget);
        expect(find.byKey(const Key('cast2')), findsOneWidget);
        expect(find.byKey(const Key('cast3')), findsOneWidget);
      });

      testWidgets('each instance has independent properties', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  CastButton(key: Key('cast1'), size: 20),
                  CastButton(key: Key('cast2'), size: 32),
                  CastButton(key: Key('cast3'), size: 48),
                ],
              ),
            ),
          ),
        );

        // Verify each CastButton widget exists
        final cast1 = tester.widget<CastButton>(find.byKey(const Key('cast1')));
        final cast2 = tester.widget<CastButton>(find.byKey(const Key('cast2')));
        final cast3 = tester.widget<CastButton>(find.byKey(const Key('cast3')));

        expect(cast1.size, 20);
        expect(cast2.size, 32);
        expect(cast3.size, 48);
      });
    });

    group('key handling', () {
      testWidgets('accepts custom key', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: CastButton(key: Key('custom_cast_button'))),
          ),
        );

        expect(find.byKey(const Key('custom_cast_button')), findsOneWidget);
      });

      testWidgets('different keys create different widgets', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  CastButton(key: Key('button_a')),
                  CastButton(key: Key('button_b')),
                ],
              ),
            ),
          ),
        );

        expect(find.byKey(const Key('button_a')), findsOneWidget);
        expect(find.byKey(const Key('button_b')), findsOneWidget);
        expect(find.byType(CastButton), findsNWidgets(2));
      });
    });

    group('createState', () {
      test('creates state successfully', () {
        const button = CastButton();
        final state = button.createState();
        expect(state, isNotNull);
      });
    });
  });
}
