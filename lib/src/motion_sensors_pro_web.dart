// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// The Web implementation of the Motion Sensors Pro plugin.
class MotionSensorsProWeb {
  static void registerWith(Registrar registrar) {
    // 1. Shake Event Channel
    final shakeChannel = PluginEventChannel('motion_sensors_pro/shake');
    shakeChannel.setController(_createShakeStreamController());

    // 2. Accelerometer Channel (includes gravity)
    final accelChannel = PluginEventChannel('motion_sensors_pro/accelerometer');
    accelChannel.setController(_createAccelerometerController());

    // 3. User Accelerometer Channel (gravity excluded)
    final userAccelChannel = PluginEventChannel('motion_sensors_pro/user_accelerometer');
    userAccelChannel.setController(_createUserAccelerometerController());

    // 4. Gyroscope Channel
    final gyroChannel = PluginEventChannel('motion_sensors_pro/gyroscope');
    gyroChannel.setController(_createGyroscopeController());

    // 5. Magnetometer Channel
    final magChannel = PluginEventChannel('motion_sensors_pro/magnetometer');
    magChannel.setController(_createMagnetometerController());

    // 6. Barometer Channel (unsupported on Web/browsers - fails cleanly)
    final baroChannel = PluginEventChannel('motion_sensors_pro/barometer');
    baroChannel.setController(_createUnsupportedController('Barometer'));

    // 7. Attitude Channel (fuses orientation alpha, beta, gamma values)
    final attitudeChannel = PluginEventChannel('motion_sensors_pro/attitude');
    attitudeChannel.setController(_createAttitudeController());

    // 8. Pedometer Channel (unsupported on Web/browsers - fails cleanly)
    final pedometerChannel = PluginEventChannel('motion_sensors_pro/pedometer');
    pedometerChannel.setController(_createUnsupportedController('Pedometer'));

    // 9. Proximity Channel (unsupported on Web/browsers - fails cleanly)
    final proximityChannel = PluginEventChannel('motion_sensors_pro/proximity');
    proximityChannel.setController(_createUnsupportedController('Proximity'));

    // Config Method Channel
    final methodChannel = MethodChannel(
      'motion_sensors_pro',
      const StandardMethodCodec(),
      registrar,
    );
    methodChannel.setMethodCallHandler((call) async {
      if (call.method == 'mockShake') {
        _shakeMockStreamController.add(true);
      }
      return null;
    });
  }

  static final StreamController<bool> _shakeMockStreamController = StreamController<bool>.broadcast();

  // Create stream controller for Shake gesture
  static StreamController<bool> _createShakeStreamController() {
    late StreamController<bool> controller;
    StreamSubscription? motionSub;
    StreamSubscription? mockSub;

    // Shake threshold configs
    double lastX = 0;
    double lastY = 0;
    double lastZ = 0;
    int lastUpdate = 0;
    int lastShakeTime = 0;

    controller = StreamController<bool>.broadcast(
      onListen: () {
        // Listen to simulated mocks
        mockSub = _shakeMockStreamController.stream.listen((event) {
          controller.add(true);
        });

        // Listen to real device motion
        motionSub = html.window.onDeviceMotion.listen((event) {
          final accel = event.acceleration;
          if (accel == null) return;

          final now = DateTime.now().millisecondsSinceEpoch;
          if ((now - lastUpdate) > 100) {
            final diffTime = now - lastUpdate;
            lastUpdate = now;

            final x = accel.x?.toDouble() ?? 0.0;
            final y = accel.y?.toDouble() ?? 0.0;
            final z = accel.z?.toDouble() ?? 0.0;

            final dx = x - lastX;
            final dy = y - lastY;
            final dz = z - lastZ;

            final deltaMagnitude = math.sqrt(dx * dx + dy * dy + dz * dz);
            final speed = (deltaMagnitude / diffTime) * 10000;

            if (speed > 800) {
              if (now - lastShakeTime > 1000) {
                lastShakeTime = now;
                controller.add(true);
              }
            }

            lastX = x;
            lastY = y;
            lastZ = z;
          }
        });
      },
      onCancel: () {
        motionSub?.cancel();
        mockSub?.cancel();
      },
    );
    return controller;
  }

  // Accelerometer (includes gravity)
  static StreamController<List<double>> _createAccelerometerController() {
    late StreamController<List<double>> controller;
    StreamSubscription? sub;

    controller = StreamController<List<double>>.broadcast(
      onListen: () {
        sub = html.window.onDeviceMotion.listen((event) {
          final accel = event.accelerationIncludingGravity;
          if (accel != null) {
            controller.add([
              accel.x?.toDouble() ?? 0.0,
              accel.y?.toDouble() ?? 0.0,
              accel.z?.toDouble() ?? 0.0,
            ]);
          }
        });
      },
      onCancel: () {
        sub?.cancel();
      },
    );
    return controller;
  }

  // User Accelerometer (gravity subtracted)
  static StreamController<List<double>> _createUserAccelerometerController() {
    late StreamController<List<double>> controller;
    StreamSubscription? sub;

    controller = StreamController<List<double>>.broadcast(
      onListen: () {
        sub = html.window.onDeviceMotion.listen((event) {
          final accel = event.acceleration;
          if (accel != null) {
            controller.add([
              accel.x?.toDouble() ?? 0.0,
              accel.y?.toDouble() ?? 0.0,
              accel.z?.toDouble() ?? 0.0,
            ]);
          }
        });
      },
      onCancel: () {
        sub?.cancel();
      },
    );
    return controller;
  }

  // Gyroscope
  static StreamController<List<double>> _createGyroscopeController() {
    late StreamController<List<double>> controller;
    StreamSubscription? sub;

    controller = StreamController<List<double>>.broadcast(
      onListen: () {
        sub = html.window.onDeviceMotion.listen((event) {
          final rotation = event.rotationRate;
          if (rotation != null) {
            // Web rotation rate matches angular velocity
            controller.add([
              rotation.alpha?.toDouble() ?? 0.0,
              rotation.beta?.toDouble() ?? 0.0,
              rotation.gamma?.toDouble() ?? 0.0,
            ]);
          }
        });
      },
      onCancel: () {
        sub?.cancel();
      },
    );
    return controller;
  }

  // Magnetometer
  static StreamController<List<double>> _createMagnetometerController() {
    late StreamController<List<double>> controller;
    StreamSubscription? sub;

    controller = StreamController<List<double>>.broadcast(
      onListen: () {
        sub = html.window.onDeviceOrientation.listen((event) {
          controller.add([
            event.alpha?.toDouble() ?? 0.0,
            event.beta?.toDouble() ?? 0.0,
            event.gamma?.toDouble() ?? 0.0,
          ]);
        });
      },
      onCancel: () {
        sub?.cancel();
      },
    );
    return controller;
  }

  // Attitude / absolute orientation
  static StreamController<List<double>> _createAttitudeController() {
    late StreamController<List<double>> controller;
    StreamSubscription? sub;

    controller = StreamController<List<double>>.broadcast(
      onListen: () {
        sub = html.window.onDeviceOrientation.listen((event) {
          // Convert orientation degree angles to radians
          final toRad = math.pi / 180.0;
          final roll = (event.gamma?.toDouble() ?? 0.0) * toRad;
          final pitch = (event.beta?.toDouble() ?? 0.0) * toRad;
          final yaw = (event.alpha?.toDouble() ?? 0.0) * toRad;
          controller.add([roll, pitch, yaw]); // roll, pitch, yaw
        });
      },
      onCancel: () {
        sub?.cancel();
      },
    );
    return controller;
  }

  // Unsupported Sensor Controller
  static StreamController<List<double>> _createUnsupportedController(String sensorName) {
    late StreamController<List<double>> controller;
    controller = StreamController<List<double>>.broadcast(
      onListen: () {
        controller.addError(
          PlatformException(
            code: 'SENSOR_UNSUPPORTED',
            message: '$sensorName is not supported on Web/Browsers.',
          ),
        );
      },
      onCancel: () {},
    );
    return controller;
  }
}
