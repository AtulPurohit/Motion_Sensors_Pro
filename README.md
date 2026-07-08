# Motion Sensors Pro

[![pub package](https://img.shields.io/pub/v/motion_sensors_pro.svg)](https://pub.dev/packages/motion_sensors_pro)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A high-performance, battery-efficient, and **Xcode simulator-aware** shake gesture detection plugin for Flutter. 

Unlike low-level sensor plugins (such as `sensors_plus`) that flood the Flutter bridge with continuous coordinate streams, `Motion Sensors Pro` does all the math natively and triggers a single, debounced event only when a genuine shake gesture occurs.

---

## ✨ Features

- 🔋 **Battery-Efficient**: Performs high-frequency shake detection calculations directly in native memory (Swift/Kotlin) so the CPU sleeps until a shake is detected.
- ⚡ **Zero Bridge Flooding**: Emits a single event over the platform channel per gesture instead of 100+ coordinate objects per second.
- 📱 **Xcode Simulator Shake Support**: Fully compatible with the iOS Simulator's `Hardware -> Shake Gesture` command out-of-the-box.
- 🛡️ **Advanced Noise Filtering**: Employs gravity-subtracted linear acceleration on Android and native motion listeners on iOS to filter out tremors, drift, and tilts.
- ⏱️ **Dual-Layer Debouncing**: Combines a native 1-second cooldown with a Dart 1.5-second broadcast stream filter to ensure a single physical shake triggers exactly one action.
- 🧪 **Mocking & Test Support**: Exposes a clean `mockShake()` method for automated unit/integration testing or triggering simulated shakes on macOS/Simulator.

---

## 📊 Comparison: `sensors_plus` vs `motion_sensors_pro`

| Feature | `sensors_plus` | `motion_sensors_pro` |
| :--- | :---: | :---: |
| **Data Overhead** | High (constant coordinate serialization) | **Minimal (single event on trigger)** |
| **Noise Filtering** | None (must write custom Dart filters) | **Native (low/high-pass & gravity subtraction)** |
| **iOS Simulator Shake Command** | ❌ Fails (doesn't trigger accelerometer) | **✅ Supported (intercepts native UI window shake)** |
| **Battery Consumption** | High (active CPU thread & GC pressure) | **Ultra Low (sleeps when device is static)** |
| **Integration Complexity** | High (requires manual math/gestures) | **Instant (plug-and-play Stream)** |

---

## 🚀 Getting Started

### Installation

Add `motion_sensors_pro` to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  motion_sensors_pro:
    path: ../Motion_Sensor_Pro # Or pub version when published
```

Run `flutter pub get` in your project folder.

---

## 📖 Usage

Using `Motion Sensors Pro` is incredibly simple. Just listen to the `onShake` stream:

```dart
import 'package:flutter/material.dart';
import 'package:motion_sensors_pro/motion_sensors_pro.dart';

class ShakeDemoScreen extends StatefulWidget {
  const ShakeDemoScreen({Key? key}) : super(key: key);

  @override
  State<ShakeDemoScreen> createState() => _ShakeDemoScreenState();
}

class _ShakeDemoScreenState extends State<ShakeDemoScreen> {
  late final StreamSubscription<void> _shakeSubscription;

  @override
  void initState() {
    super.initState();
    
    // Subscribe to shake gestures
    _shakeSubscription = MotionSensorsPro.onShake.listen((_) {
      _handleShakeGesture();
    });
  }

  void _handleShakeGesture() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📱 Shake gesture detected successfully!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    // Unsubscribing automatically turns off hardware listeners to save battery
    _shakeSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Motion Sensors Pro')),
      body: const Center(
        child: Text('Shake your physical device or trigger Xcode Simulator Shake!'),
      ),
    );
  }
}
```

### 🧪 Programmatic Testing (Mocking)

You can trigger a shake event programmatically without physical movement. This is ideal for automated driver tests or adding quick debug triggers in your UI:

```dart
// Simulate a native shake gesture event
await MotionSensorsPro.mockShake();
```

---

## 🛠️ How It Works (Technical Overview)

1. **iOS (`Swift`)**: Intercepts iOS window motion events using a clean Swift extension on `UIWindow` matching `.motionShake`. This enables seamless compatibility with Xcode's simulated shake command.
2. **Android (`Kotlin`)**: Registers a native `SensorEventListener`. It prioritizes `TYPE_LINEAR_ACCELERATION` (where gravity is pre-subtracted by the Android hardware abstraction layer), falling back to vector delta magnitude mapping on older hardware.
3. **Flutter Platform Channel**: Operates over a single `EventChannel` (`motion_sensors_pro/shake`). Because we perform all gesture classification on the native side, we only pass an event when a real shake is validated.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
