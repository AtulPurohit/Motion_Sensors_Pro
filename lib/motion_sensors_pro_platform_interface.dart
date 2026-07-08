import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'motion_sensors_pro_method_channel.dart';

abstract class MotionSensorsProPlatform extends PlatformInterface {
  MotionSensorsProPlatform() : super(token: _token);

  static final Object _token = Object();

  static MotionSensorsProPlatform _instance = MethodChannelMotionSensorsPro();

  static MotionSensorsProPlatform get instance => _instance;

  static set instance(MotionSensorsProPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> mockShake() {
    throw UnimplementedError('mockShake() has not been implemented.');
  }
}
