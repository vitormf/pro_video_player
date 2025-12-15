import 'dart:io';

import 'package:integration_test/integration_test_driver.dart' as driver;

Future<void> main() async {
  try {
    // Run the integration tests
    await driver.integrationDriver();
  } finally {
    // Ensure Chrome processes are cleaned up after tests complete (pass or fail)
    // This handles cases where the WebDriver doesn't properly close the browser
    if (Platform.isMacOS) {
      // Give the driver a moment to clean up naturally
      await Future<void>.delayed(const Duration(seconds: 1));
      // Force close any remaining Chrome instances started by chromedriver
      await Process.run('pkill', ['-f', 'chromedriver']);
    }
  }
}
