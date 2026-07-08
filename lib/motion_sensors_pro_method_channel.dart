import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'motion_sensors_pro_platform_interface.dart';

class MethodChannelMotionSensorsPro extends MotionSensorsProPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('motion_sensors_pro');

  @override
  Future<void> mockShake() async {
    await methodChannel.invokeMethod<void>('mockShake');
  }
}
