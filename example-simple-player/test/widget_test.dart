import 'package:example_simple_player/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App builds and shows home screen', (tester) async {
    await tester.pumpWidget(const SimplePlayerApp());
    await tester.pumpAndSettle();

    // Verify home screen elements are present
    expect(find.text('Simple Player'), findsOneWidget);
    expect(find.text('Open File'), findsOneWidget);
    expect(find.text('Open URL'), findsOneWidget);
  });
}
