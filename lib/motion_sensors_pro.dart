import 'dart:async';
import 'package:flutter/services.dart';

/// Represents raw accelerometer data (includes gravity forces).
class AccelerometerEvent {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  AccelerometerEvent(this.x, this.y, this.z, {DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'AccelerometerEvent(x: $x, y: $y, z: $z, timestamp: $timestamp)';
}

/// Represents accelerometer data with gravity mathematically subtracted.
class UserAccelerometerEvent {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  UserAccelerometerEvent(this.x, this.y, this.z, {DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'UserAccelerometerEvent(x: $x, y: $y, z: $z, timestamp: $timestamp)';
}

/// Represents gyroscope angular velocity data (rad/s) around spatial axes.
class GyroscopeEvent {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  GyroscopeEvent(this.x, this.y, this.z, {DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'GyroscopeEvent(x: $x, y: $y, z: $z, timestamp: $timestamp)';
}

/// Represents magnetometer magnetic field readings (micro-Tesla µT).
class MagnetometerEvent {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  MagnetometerEvent(this.x, this.y, this.z, {DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'MagnetometerEvent(x: $x, y: $y, z: $z, timestamp: $timestamp)';
}

/// Represents atmospheric pressure data from the barometer sensor.
class BarometerEvent {
  /// Atmospheric pressure in hectopascals (hPa) or millibars.
  final double pressure;

  /// Relative altitude change in meters since the stream was opened (primarily iOS).
  final double relativeAltitude;

  final DateTime timestamp;

  BarometerEvent(this.pressure, this.relativeAltitude, {DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() =>
      'BarometerEvent(pressure: $pressure, relativeAltitude: $relativeAltitude, timestamp: $timestamp)';
}

/// The core entry point for the Motion Sensors Pro plugin.
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

  // Cache streams to avoid creating duplicate channel bindings
  static Stream<void>? _shakeStream;
  static Stream<AccelerometerEvent>? _accelerometerStream;
  static Stream<UserAccelerometerEvent>? _userAccelerometerStream;
  static Stream<GyroscopeEvent>? _gyroscopeStream;
  static Stream<MagnetometerEvent>? _magnetometerStream;
  static Stream<BarometerEvent>? _barometerStream;

  /// Configure the global sampling interval (in microseconds) for all raw sensor streams.
  /// Android: Standard values like SENSOR_DELAY_UI, SENSOR_DELAY_GAME are mapped.
  /// iOS: Updates CMMotionManager's updateIntervals dynamically.
  static Future<void> setSensorInterval(Duration interval) async {
    await _methodChannel.invokeMethod('setSensorInterval', {
      'microseconds': interval.inMicroseconds,
    });
  }

  /// Stream of shake gesture events.
  ///
  /// Emits a single `void` event per physical shake gesture.
  /// Debounced to at most one event per 1500ms to filter hardware noise.
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

  /// Stream of raw accelerometer data (includes gravity).
  static Stream<AccelerometerEvent> get accelerometerEvents {
    _accelerometerStream ??= _accelerometerChannel.receiveBroadcastStream().map((event) {
      final list = List<double>.from(event);
      return AccelerometerEvent(list[0], list[1], list[2]);
    }).asBroadcastStream();
    return _accelerometerStream!;
  }

  /// Stream of user acceleration data (excluding gravity).
  static Stream<UserAccelerometerEvent> get userAccelerometerEvents {
    _userAccelerometerStream ??= _userAccelerometerChannel.receiveBroadcastStream().map((event) {
      final list = List<double>.from(event);
      return UserAccelerometerEvent(list[0], list[1], list[2]);
    }).asBroadcastStream();
    return _userAccelerometerStream!;
  }

  /// Stream of angular velocity readings from the gyroscope.
  static Stream<GyroscopeEvent> get gyroscopeEvents {
    _gyroscopeStream ??= _gyroscopeChannel.receiveBroadcastStream().map((event) {
      final list = List<double>.from(event);
      return GyroscopeEvent(list[0], list[1], list[2]);
    }).asBroadcastStream();
    return _gyroscopeStream!;
  }

  /// Stream of ambient magnetic field readings.
  static Stream<MagnetometerEvent> get magnetometerEvents {
    _magnetometerStream ??= _magnetometerChannel.receiveBroadcastStream().map((event) {
      final list = List<double>.from(event);
      return MagnetometerEvent(list[0], list[1], list[2]);
    }).asBroadcastStream();
    return _magnetometerStream!;
  }

  /// Stream of barometric pressure data.
  /// Emits pressure in hPa/millibar and relative altitude change (primarily on iOS).
  /// Fails cleanly if barometer hardware is unsupported by device.
  static Stream<BarometerEvent> get barometerEvents {
    _barometerStream ??= _barometerChannel.receiveBroadcastStream().map((event) {
      final list = List<double>.from(event);
      return BarometerEvent(list[0], list[1]);
    }).asBroadcastStream();
    return _barometerStream!;
  }

  /// Programmatically simulate/trigger a shake gesture event.
  /// Useful for testing, simulator triggers, or keyboard shortcut triggers on macOS.
  static Future<void> mockShake() async {
    await _methodChannel.invokeMethod('mockShake');
  }
}
