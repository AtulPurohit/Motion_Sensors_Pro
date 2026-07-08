import 'dart:async';
import 'package:flutter/services.dart';
import 'motion_sensors_pro_platform_interface.dart';

class MotionSensorsPro {
  static const EventChannel _shakeEventChannel =
      EventChannel('motion_sensors_pro/shake');

  // Internal broadcast stream — raw hardware events (may fire 3-5x per shake).
  static Stream<void>? _rawShakeStream;

  // Debounced public stream — fires at most once per 1500ms window.
  // A single physical shake can generate 3–5 back-to-back events at the native
  // layer; this ensures the Flutter app only sees one event per gesture.
  static Stream<void>? _debouncedShakeStream;

  /// Stream of shake gesture events.
  ///
  /// Emits a single `void` event per physical shake gesture.
  /// Debounced to at most one event per 1500ms to filter hardware noise.
  static Stream<void> get onShake {
    if (_debouncedShakeStream != null) return _debouncedShakeStream!;

    _rawShakeStream ??=
        _shakeEventChannel.receiveBroadcastStream().map((_) => null);

    DateTime? _lastFired;

    _debouncedShakeStream = _rawShakeStream!.where((_) {
      final now = DateTime.now();
      if (_lastFired == null ||
          now.difference(_lastFired!) > const Duration(milliseconds: 1500)) {
        _lastFired = now;
        return true;
      }
      return false;
    }).asBroadcastStream();

    return _debouncedShakeStream!;
  }

  /// Programmatically simulate/trigger a shake gesture event.
  /// Useful for testing, simulator triggers, or keyboard shortcut triggers on macOS.
  static Future<void> mockShake() {
    return MotionSensorsProPlatform.instance.mockShake();
  }
}
