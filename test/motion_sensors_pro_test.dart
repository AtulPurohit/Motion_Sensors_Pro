import 'package:flutter_test/flutter_test.dart';
import 'package:motion_sensors_pro/motion_sensors_pro.dart';
import 'package:motion_sensors_pro/motion_sensors_pro_platform_interface.dart';
import 'package:motion_sensors_pro/motion_sensors_pro_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMotionSensorsProPlatform
    with MockPlatformInterfaceMixin
    implements MotionSensorsProPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final MotionSensorsProPlatform initialPlatform = MotionSensorsProPlatform.instance;

  test('$MethodChannelMotionSensorsPro is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMotionSensorsPro>());
  });

  test('getPlatformVersion', () async {
    MotionSensorsPro motionSensorsProPlugin = MotionSensorsPro();
    MockMotionSensorsProPlatform fakePlatform = MockMotionSensorsProPlatform();
    MotionSensorsProPlatform.instance = fakePlatform;

    expect(await motionSensorsProPlugin.getPlatformVersion(), '42');
  });
}
