import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Minimal test - just check binding works', (tester) async {
    // This test does nothing except verify the binding initialized
    expect(true, isTrue);
  });
}
