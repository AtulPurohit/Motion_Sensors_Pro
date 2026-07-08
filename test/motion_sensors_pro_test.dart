import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_sensors_pro/motion_sensors_pro.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('motion_sensors_pro');
  final List<MethodCall> log = <MethodCall>[];

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      log.add(methodCall);
      switch (methodCall.method) {
        case 'mockShake':
          return null;
        case 'setSensorInterval':
          return null;
        default:
          return null;
      }
    });
    log.clear();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('mockShake calls method channel', () async {
    await MotionSensorsPro.mockShake();
    expect(log, hasLength(1));
    expect(log.single.method, 'mockShake');
  });

  test('setSensorInterval calls method channel with correct arguments', () async {
    const duration = Duration(milliseconds: 100);
    await MotionSensorsPro.setSensorInterval(duration);
    expect(log, hasLength(1));
    expect(log.single.method, 'setSensorInterval');
    expect(log.single.arguments, {'microseconds': 100000});
  });
}
