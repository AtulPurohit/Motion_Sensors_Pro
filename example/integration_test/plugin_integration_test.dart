import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:motion_sensors_pro/motion_sensors_pro.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mockShake test', (WidgetTester tester) async {
    // Assert that mockShake executes without throwing any exceptions
    expect(MotionSensorsPro.mockShake(), completes);
  });

  testWidgets('setSensorInterval test', (WidgetTester tester) async {
    // Assert that setSensorInterval executes without throwing any exceptions
    expect(MotionSensorsPro.setSensorInterval(const Duration(milliseconds: 100)), completes);
  });
}
