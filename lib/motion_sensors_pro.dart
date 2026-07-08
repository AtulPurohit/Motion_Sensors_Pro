import 'dart:async';
import 'package:flutter/services.dart';

/// Represents raw accelerometer measurements along the three spatial axes.
///
/// Accelerometer readings measure the sum of all physical forces applied to
/// the device, including dynamic user acceleration and the static force of gravity.
///
/// Value units are in meters per second squared ($m/s^2$).
///
/// ### Example Usage:
/// ```dart
/// MotionSensorsPro.accelerometerEvents.listen((event) {
///   print('Raw Accelerometer: X: ${event.x}, Y: ${event.y}, Z: ${event.z}');
/// });
/// ```
class AccelerometerEvent {
  /// Acceleration force along the x-axis (lateral movement left/right) in $m/s^2$.
  final double x;

  /// Acceleration force along the y-axis (longitudinal movement forward/backward) in $m/s^2$.
  final double y;

  /// Acceleration force along the z-axis (vertical movement up/down) in $m/s^2$.
  final double z;

  /// The timestamp indicating when this sensor event was captured.
  final DateTime timestamp;

  AccelerometerEvent(this.x, this.y, this.z, {DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'AccelerometerEvent(x: $x, y: $y, z: $z, timestamp: $timestamp)';
}

/// Represents user acceleration measurements with gravity forces subtracted.
///
/// Unlike raw accelerometer readings, this stream mathematically filters out
/// the force of gravity (1g or ~9.81 $m/s^2$) using native device-level sensor fusion
/// (CoreMotion attitude estimation on iOS, and the Android Sensor Hub).
///
/// Value units are in meters per second squared ($m/s^2$).
///
/// ### Example Usage:
/// ```dart
/// MotionSensorsPro.userAccelerometerEvents.listen((event) {
///   print('Gravity-free User Acceleration: X: ${event.x}, Y: ${event.y}, Z: ${event.z}');
/// });
/// ```
class UserAccelerometerEvent {
  /// Gravity-subtracted user acceleration along the x-axis in $m/s^2$.
  final double x;

  /// Gravity-subtracted user acceleration along the y-axis in $m/s^2$.
  final double y;

  /// Gravity-subtracted user acceleration along the z-axis in $m/s^2$.
  final double z;

  /// The timestamp indicating when this sensor event was captured.
  final DateTime timestamp;

  UserAccelerometerEvent(this.x, this.y, this.z, {DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'UserAccelerometerEvent(x: $x, y: $y, z: $z, timestamp: $timestamp)';
}

/// Represents gyroscope angular velocity measurements (rotation speed) around three spatial axes.
///
/// Readings describe the speed of rotation around the device's X, Y, and Z axes.
///
/// Value units are in radians per second ($rad/s$).
///
/// ### Example Usage:
/// ```dart
/// MotionSensorsPro.gyroscopeEvents.listen((event) {
///   print('Rotation Speed: X: ${event.x}, Y: ${event.y}, Z: ${event.z}');
/// });
/// ```
class GyroscopeEvent {
  /// Rotation speed around the x-axis (pitch speed) in $rad/s$.
  final double x;

  /// Rotation speed around the y-axis (roll speed) in $rad/s$.
  final double y;

  /// Rotation speed around the z-axis (yaw speed) in $rad/s$.
  final double z;

  /// The timestamp indicating when this sensor event was captured.
  final DateTime timestamp;

  GyroscopeEvent(this.x, this.y, this.z, {DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'GyroscopeEvent(x: $x, y: $y, z: $z, timestamp: $timestamp)';
}

/// Represents ambient magnetic field strength along the three spatial axes.
///
/// Readings reflect the surrounding geomagnetic field vector, which is useful for
/// creating compasses, detecting metal objects, or orienting relative to the magnetic north pole.
///
/// Value units are in micro-Tesla ($\mu T$).
///
/// ### Example Usage:
/// ```dart
/// MotionSensorsPro.magnetometerEvents.listen((event) {
///   print('Magnetic field strength: X: ${event.x} uT, Y: ${event.y} uT');
/// });
/// ```
class MagnetometerEvent {
  /// Geomagnetic field strength along the x-axis in micro-Tesla ($\mu T$).
  final double x;

  /// Geomagnetic field strength along the y-axis in micro-Tesla ($\mu T$).
  final double y;

  /// Geomagnetic field strength along the z-axis in micro-Tesla ($\mu T$).
  final double z;

  /// The timestamp indicating when this sensor event was captured.
  final DateTime timestamp;

  MagnetometerEvent(this.x, this.y, this.z, {DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'MagnetometerEvent(x: $x, y: $y, z: $z, timestamp: $timestamp)';
}

/// Represents environmental pressure and relative altitude readings.
///
/// Note: Barometers are not present on all devices. If missing, listening to this stream
/// throws a `SENSOR_UNSUPPORTED` exception. Always catch stream errors gracefully.
///
/// ### Example Usage:
/// ```dart
/// MotionSensorsPro.barometerEvents.listen(
///   (event) {
///     print('Pressure: ${event.pressure} hPa');
///     print('Relative Altitude: ${event.relativeAltitude} meters');
///   },
///   onError: (error) => print('Sensor not supported on this device: $error'),
/// );
/// ```
class BarometerEvent {
  /// Ambient atmospheric pressure in hectopascals (hPa) or millibars.
  final double pressure;

  /// Relative altitude change in meters since the stream listener was first opened (primarily iOS).
  final double relativeAltitude;

  /// The timestamp indicating when this sensor event was captured.
  final DateTime timestamp;

  BarometerEvent(this.pressure, this.relativeAltitude, {DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() =>
      'BarometerEvent(pressure: $pressure, relativeAltitude: $relativeAltitude, timestamp: $timestamp)';
}

/// Represents the absolute 3D orientation (attitude) of the device relative to the Earth.
///
/// This fuses accelerometer, gyroscope, and magnetometer readings natively (via Kalman filters)
/// to compute the smooth, real-time spatial tilt angles of the device.
///
/// Value units are in radians.
///
/// ### Example Usage:
/// ```dart
/// MotionSensorsPro.attitudeEvents.listen((event) {
///   final rollDegrees = event.roll * 180 / 3.14159265;
///   print('Lateral Roll Angle: $rollDegrees degrees');
/// });
/// ```
class AttitudeEvent {
  /// The lateral roll angle in radians (rotation around the longitudinal axis). Ranges from -pi to pi.
  final double roll;

  /// The pitch angle in radians (rotation around the lateral axis). Ranges from -pi/2 to pi/2.
  final double pitch;

  /// The yaw/azimuth angle in radians (rotation around the vertical axis). Ranges from -pi to pi.
  final double yaw;

  /// The timestamp indicating when this sensor event was captured.
  final DateTime timestamp;

  AttitudeEvent(this.roll, this.pitch, this.yaw, {DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'AttitudeEvent(roll: $roll, pitch: $pitch, yaw: $yaw, timestamp: $timestamp)';
}

/// Represents physical step counts captured by the low-power step-detector chip.
///
/// Note: Requires the `NSMotionUsageDescription` key in the `Info.plist` for iOS.
/// If step-counting hardware is absent, throws a `SENSOR_UNSUPPORTED` exception.
///
/// ### Example Usage:
/// ```dart
/// MotionSensorsPro.pedometerEvents.listen(
///   (event) => print('Steps taken: ${event.steps}'),
///   onError: (error) => print('Pedometer unsupported: $error'),
/// );
/// ```
class PedometerEvent {
  /// Number of steps taken by the user since the stream started or since device boot.
  final int steps;

  /// The timestamp indicating when this step event was captured.
  final DateTime timestamp;

  PedometerEvent(this.steps, {DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'PedometerEvent(steps: $steps, timestamp: $timestamp)';
}

/// Represents proximity detection events indicating screen obstruction.
///
/// Checks if an object (such as a user's ear or hand) is near the proximity sensor.
///
/// ### Example Usage:
/// ```dart
/// MotionSensorsPro.proximityEvents.listen(
///   (event) => print('Is face near screen: ${event.isNear}'),
///   onError: (error) => print('Proximity sensor unsupported: $error'),
/// );
/// ```
class ProximityEvent {
  /// True if an object is close to the device sensor; false if it is clear.
  final bool isNear;

  /// The timestamp indicating when this sensor event was captured.
  final DateTime timestamp;

  ProximityEvent(this.isNear, {DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'ProximityEvent(isNear: $isNear, timestamp: $timestamp)';
}

/// The core entry point for the Motion Sensors Pro plugin.
///
/// Exposes native classification for shake gestures and real-time streams
/// for all 8 physical motion, environmental, and interaction sensors.
class MotionSensorsPro {
  // Method Channel for triggers & configuration
  static const MethodChannel _methodChannel = MethodChannel('motion_sensors_pro');

  // Event Channels for shake and raw sensor feeds
  static const EventChannel _shakeChannel = EventChannel('motion_sensors_pro/shake');
  static const EventChannel _accelerometerChannel = EventChannel('motion_sensors_pro/accelerometer');
  static const EventChannel _userAccelerometerChannel = EventChannel('motion_sensors_pro/user_accelerometer');
  static const EventChannel _gyroscopeChannel = EventChannel('motion_sensors_pro/gyroscope');
  static const EventChannel _magnetometerChannel = EventChannel('motion_sensors_pro/magnetometer');
  static const EventChannel _barometerChannel = EventChannel('motion_sensors_pro/barometer');
  static const EventChannel _attitudeChannel = EventChannel('motion_sensors_pro/attitude');
  static const EventChannel _pedometerChannel = EventChannel('motion_sensors_pro/pedometer');
  static const EventChannel _proximityChannel = EventChannel('motion_sensors_pro/proximity');

  // Cache streams to avoid creating duplicate channel bindings
  static Stream<void>? _shakeStream;
  static Stream<AccelerometerEvent>? _accelerometerStream;
  static Stream<UserAccelerometerEvent>? _userAccelerometerStream;
  static Stream<GyroscopeEvent>? _gyroscopeStream;
  static Stream<MagnetometerEvent>? _magnetometerStream;
  static Stream<BarometerEvent>? _barometerStream;
  static Stream<AttitudeEvent>? _attitudeStream;
  static Stream<PedometerEvent>? _pedometerStream;
  static Stream<ProximityEvent>? _proximityStream;

  /// Configure the global sampling interval (in microseconds) for all raw sensor streams.
  ///
  /// * **Android**: Standard values like `SENSOR_DELAY_UI` (60ms), `SENSOR_DELAY_GAME` (20ms) are mapped.
  /// * **iOS**: Updates CMMotionManager's updateIntervals dynamically.
  ///
  /// ### Example:
  /// ```dart
  /// await MotionSensorsPro.setSensorInterval(Duration(milliseconds: 20)); // 50Hz updates
  /// ```
  static Future<void> setSensorInterval(Duration interval) async {
    await _methodChannel.invokeMethod('setSensorInterval', {
      'microseconds': interval.inMicroseconds,
    });
  }

  /// Stream of shake gesture events.
  ///
  /// Emits a single `void` event per physical shake gesture.
  /// Debounced natively and in Dart to at most one event per 1500ms to filter hardware noise.
  ///
  /// ### Example:
  /// ```dart
  /// MotionSensorsPro.onShake.listen((_) {
  ///   print('Shake gesture detected!');
  /// });
  /// ```
  static Stream<void> get onShake {
    if (_shakeStream != null) return _shakeStream!;

    final rawStream = _shakeChannel.receiveBroadcastStream().map((_) => null);
    DateTime? lastFired;

    _shakeStream = rawStream.where((_) {
      final now = DateTime.now();
      if (lastFired == null || now.difference(lastFired!) > const Duration(milliseconds: 1500)) {
        lastFired = now;
        return true;
      }
      return false;
    }).asBroadcastStream();

    return _shakeStream!;
  }

  /// Stream of raw accelerometer data (includes gravity forces).
  ///
  /// Emits [AccelerometerEvent] values along X, Y, and Z axes in $m/s^2$.
  static Stream<AccelerometerEvent> get accelerometerEvents {
    _accelerometerStream ??= _accelerometerChannel.receiveBroadcastStream().map((event) {
      final list = List<double>.from(event);
      return AccelerometerEvent(list[0], list[1], list[2]);
    }).asBroadcastStream();
    return _accelerometerStream!;
  }

  /// Stream of user acceleration data (excluding gravity forces).
  ///
  /// Emits [UserAccelerometerEvent] values along X, Y, and Z axes in $m/s^2$.
  static Stream<UserAccelerometerEvent> get userAccelerometerEvents {
    _userAccelerometerStream ??= _userAccelerometerChannel.receiveBroadcastStream().map((event) {
      final list = List<double>.from(event);
      return UserAccelerometerEvent(list[0], list[1], list[2]);
    }).asBroadcastStream();
    return _userAccelerometerStream!;
  }

  /// Stream of angular velocity readings from the gyroscope.
  ///
  /// Emits [GyroscopeEvent] values in radians per second ($rad/s$).
  static Stream<GyroscopeEvent> get gyroscopeEvents {
    _gyroscopeStream ??= _gyroscopeChannel.receiveBroadcastStream().map((event) {
      final list = List<double>.from(event);
      return GyroscopeEvent(list[0], list[1], list[2]);
    }).asBroadcastStream();
    return _gyroscopeStream!;
  }

  /// Stream of ambient magnetic field readings.
  ///
  /// Emits [MagnetometerEvent] values in micro-Tesla ($\mu T$).
  static Stream<MagnetometerEvent> get magnetometerEvents {
    _magnetometerStream ??= _magnetometerChannel.receiveBroadcastStream().map((event) {
      final list = List<double>.from(event);
      return MagnetometerEvent(list[0], list[1], list[2]);
    }).asBroadcastStream();
    return _magnetometerStream!;
  }

  /// Stream of barometric pressure data.
  ///
  /// Emits [BarometerEvent] values containing pressure (hPa) and relative altitude change (meters).
  /// Fails cleanly with a [PlatformException] if barometer hardware is unsupported by the device.
  static Stream<BarometerEvent> get barometerEvents {
    _barometerStream ??= _barometerChannel.receiveBroadcastStream().map((event) {
      final list = List<double>.from(event);
      return BarometerEvent(list[0], list[1]);
    }).asBroadcastStream();
    return _barometerStream!;
  }

  /// Stream of device 3D Attitude (Orientation) events.
  ///
  /// Emits [AttitudeEvent] values containing roll, pitch, and yaw angles in radians.
  static Stream<AttitudeEvent> get attitudeEvents {
    _attitudeStream ??= _attitudeChannel.receiveBroadcastStream().map((event) {
      final list = List<double>.from(event);
      return AttitudeEvent(list[0], list[1], list[2]);
    }).asBroadcastStream();
    return _attitudeStream!;
  }

  /// Stream of pedometer step count events.
  ///
  /// Emits [PedometerEvent] containing the cumulative step count.
  /// Fails cleanly with a [PlatformException] if hardware is unsupported.
  static Stream<PedometerEvent> get pedometerEvents {
    _pedometerStream ??= _pedometerChannel.receiveBroadcastStream().map((event) {
      final stepCount = event as int;
      return PedometerEvent(stepCount);
    }).asBroadcastStream();
    return _pedometerStream!;
  }

  /// Stream of proximity sensor events.
  ///
  /// Emits [ProximityEvent] indicating if an object is near the screen.
  /// Fails cleanly if the proximity sensor is unsupported.
  static Stream<ProximityEvent> get proximityEvents {
    _proximityStream ??= _proximityChannel.receiveBroadcastStream().map((event) {
      final isNear = (event as int) == 1;
      return ProximityEvent(isNear);
    }).asBroadcastStream();
    return _proximityStream!;
  }

  /// Programmatically simulate/trigger a shake gesture event.
  ///
  /// Useful for automated widget testing, integration tests, or custom UI test triggers.
  static Future<void> mockShake() async {
    await _methodChannel.invokeMethod('mockShake');
  }
}
