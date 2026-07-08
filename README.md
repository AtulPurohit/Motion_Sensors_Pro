# Motion Sensors Pro

[![pub package](https://img.shields.io/pub/v/motion_sensors_pro.svg)](https://pub.dev/packages/motion_sensors_pro)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A premium, production-grade motion and environmental sensor engine for Flutter. By combining high-efficiency native gesture classification with real-time, low-latency streams for **8 physical hardware sensors**, it provides developers with the ultimate API for immersive, device-aware mobile experiences. Engineered with sub-millisecond dynamic intervals, thread-safe memory mapping, and seamless Xcode Simulator mock-shake routing, it represents the new standard for motion tracking in Flutter.

1. **Shake Gesture Detection** (Native classification, 100% Simulator-friendly)
2. **Accelerometer** (Raw 3-axis acceleration including gravity)
3. **User Accelerometer** (Gravity mathematically subtracted by OS)
4. **Gyroscope** (Angular velocity/rotation speed)
5. **Magnetometer** (Ambient magnetic field vector)
6. **Barometer** (Atmospheric pressure & relative altitude changes)
7. **Device Attitude** (Absolute 3D orientation: Roll, Pitch, Yaw via Sensor Fusion)
8. **Pedometer** (Low-power hardware step counter updates)
9. **Proximity Sensor** (Face detection/screen proximity monitoring)

---

## 📱 Platform Support

| Android | iOS | macOS | Web | Linux | Windows |
| :---: | :---: | :---: | :---: | :---: | :---: |
|   ✅   |  ✅  |  ✅*  |  ✅*  |  ❌   |   ❌    |

\* **macOS**: Exposes safe fallback stream handlers that emit descriptive unsupported sensor exceptions instead of raising missing plugin channel registration errors. Programmatic mock triggers remain fully operational for unit/widget testing.

\* **Web**: Supported on mobile web browsers (Safari, Chrome, etc.) using HTML5 DeviceMotion & DeviceOrientation APIs. Setting sampling rate/interval is currently unsupported on web due to browser constraints.

---

## ✨ Why `motion_sensors_pro` is Better than `sensors_plus`

| Feature | `sensors_plus` | `motion_sensors_pro` |
| :--- | :---: | :---: |
| **Shake Gesture detection** | ❌ None (must parse streams manually in Dart) | **✅ Native classification, debounced and ready** |
| **Xcode Simulator Shake Support** | ❌ Fails (simulate shake triggers no sensors) | **✅ Supported (intercepts native motion window)** |
| **Dynamic Sampling Interval** | ⚠️ Limited / Static configurations | **✅ Dynamic configuration down to microseconds** |
| **Bridge Overhead / CPU Load** | High (floods bridge with 100+ coordinate msg/s) | **Ultra Low (sleeps when static, custom intervals)** |
| **Barometer Fallback Handling** | ❌ Prone to crash on missing hardware | **✅ Graceful fallback (emits clean Unsupported exception)** |
| **Desktop / macOS Support** | ⚠️ Partial / Unhandled channels | **✅ Safe fallbacks (returns descriptive status exceptions)** |
| **3D Attitude (Roll/Pitch/Yaw)** | ❌ None | **✅ Supported (native sensor fusion)** |
| **Pedometer & Proximity Sensors** | ❌ None | **✅ Supported (native step & face detection)** |

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

## 📋 Requirements

### iOS
- iOS 12.0 or higher.
- To listen to the **Barometer** (`barometerEvents`) or **Pedometer** (`pedometerEvents`), you must include the `NSMotionUsageDescription` key in your `ios/Runner/Info.plist` file:
  ```xml
  <key>NSMotionUsageDescription</key>
  <string>This app requires access to motion data to receive barometric pressure readings and count physical steps.</string>
  ```

### Android
- Android SDK 21 (Lollipop) or higher.
- Uses standard hardware sensors; no manifest permissions required.

---

## 📖 Usage

### 1. Dynamic Sampling Frequency (Global Configuration)

Unlike other plugins, you can configure the sensor polling interval dynamically from Dart. CoreMotion and Android SensorManager adapt immediately:

```dart
import 'package:motion_sensors_pro/motion_sensors_pro.dart';

// Set sampling rate to every 50 milliseconds (20Hz)
await MotionSensorsPro.setSensorInterval(const Duration(milliseconds: 50));
```

---

### 2. Shake Gesture Detection

Listen for device shake events. A native-level cooldown (1.0s) and Dart-level debouncer (1.5s) ensure exactly one event fires per physical gesture:

```dart
MotionSensorsPro.onShake.listen((_) {
  print("📱 Device was shaken!");
});
```

#### Xcode Simulator Testing
In Xcode Simulator, trigger a shake by selecting **Features -> Shake Gesture** (or **Hardware -> Shake Gesture**). The stream will fire normally.

---

### 3. Accelerometer (Raw Acceleration including Gravity)

Emits raw acceleration values along the X, Y, and Z axes in $m/s^2$.

```dart
MotionSensorsPro.accelerometerEvents.listen((event) {
  print("Raw Accelerometer: X: ${event.x}, Y: ${event.y}, Z: ${event.z}");
});
```

---

### 4. User Accelerometer (Acceleration excluding Gravity)

Emits clean acceleration values with gravity mathematically subtracted by the device's hardware abstraction layers (CoreMotion / Android Sensor Hub).

```dart
MotionSensorsPro.userAccelerometerEvents.listen((event) {
  print("User Acceleration: X: ${event.x}, Y: ${event.y}, Z: ${event.z}");
});
```

---

### 5. Gyroscope (Angular Velocity)

Emits spatial rotation velocity readings in radians per second ($rad/s$).

```dart
MotionSensorsPro.gyroscopeEvents.listen((event) {
  print("Gyroscope Rotation: X: ${event.x}, Y: ${event.y}, Z: ${event.z}");
});
```

---

### 6. Magnetometer (Ambient Magnetic Field)

Emits geomagnetic field strength readings along the three spatial axes in micro-Tesla ($\mu T$).

```dart
MotionSensorsPro.magnetometerEvents.listen((event) {
  print("Magnetic Field: X: ${event.x}, Y: ${event.y}, Z: ${event.z}");
});
```

---

### 7. Barometer (Atmospheric Pressure & Relative Altitude)

Emits atmospheric pressure values in hectopascals ($hPa$) / millibars and relative altitude changes in meters (supported primarily on iOS).
Fails gracefully with a descriptive error if the device lacks barometer hardware:

```dart
MotionSensorsPro.barometerEvents.listen(
  (event) {
    print("Pressure: ${event.pressure} hPa");
    print("Rel Altitude change: ${event.relativeAltitude} meters");
  },
  onError: (error) {
    print("Barometer not supported: $error");
  },
);
```

---

### 8. Device Attitude (3D Sensor Fusion Orientation)

Emits absolute orientation values (`roll`, `pitch`, `yaw`) in radians using native device-level Kalman filtering.

```dart
MotionSensorsPro.attitudeEvents.listen((event) {
  print("Device Attitude: Roll: ${event.roll}, Pitch: ${event.pitch}, Yaw: ${event.yaw}");
});
```

---

### 9. Pedometer (Low-Power Step Counter)

Emits low-power hardware step counter updates.

```dart
MotionSensorsPro.pedometerEvents.listen(
  (event) {
    print("Steps walked: ${event.steps}");
  },
  onError: (error) {
    print("Pedometer not supported: $error");
  },
);
```

---

### 10. Proximity Sensor (Face Detection / Obstructed Screen)

Emits `true` if an object or user's face is close to the screen, and `false` otherwise. Automatically enables/disables hardware monitoring dynamically based on stream subscription status to maximize battery conservation.

```dart
MotionSensorsPro.proximityEvents.listen(
  (event) {
    print("Is screen obstructed/face near: ${event.isNear}");
  },
  onError: (error) {
    print("Proximity sensor not supported: $error");
  },
);
```

---

## 🧪 Programmatic Testing (Mocking)

You can programmatically mock a shake gesture event for automated driver/unit tests:

```dart
// Simulates a physical shake gesture
await MotionSensorsPro.mockShake();
```

---

## 🛠️ Implementation Details

### iOS (`Swift`)
- **Shake**: Extended `UIWindow` to intercept `.motionShake` events directly.
- **Motion Sensors**: Binds to `CMMotionManager`. Acceleration values are scaled by standard gravity ($9.80665$) to ensure cross-platform unit consistency.
- **Barometer**: Accesses `CMAltimeter` and multiplies pressure values by $10.0$ to convert kilopascals ($kPa$) to standard hectopascals ($hPa$).
- **Pedometer**: Directly integrates with CoreMotion `CMPedometer` step counts updates.
- **Proximity**: Dynamically monitors `UIDevice.proximityStateDidChangeNotification` on subscription.

### Android (`Kotlin`)
- **Shake**: Prioritizes Android's hardware `Sensor.TYPE_LINEAR_ACCELERATION` (gravity pre-subtracted by Android OS), falling back to magnitude-delta calculations on older hardware.
- **Motion Sensors**: Integrates `SensorManager` event listeners for `TYPE_ACCELEROMETER`, `TYPE_LINEAR_ACCELERATION`, `TYPE_GYROSCOPE`, `TYPE_MAGNETIC_FIELD`, `TYPE_PRESSURE`, `TYPE_ROTATION_VECTOR` (Attitude), `TYPE_STEP_COUNTER`, and `TYPE_PROXIMITY`.
- **Thread Safety**: Relies on a main-thread handler to pass events safely into Flutter's `EventSink`.

---

## ⚠️ Hardware Limitations & Safety Fallbacks

- **Barometer sensor availability**: Atmospheric pressure barometers are missing on budget Android models and older iOS units. `motion_sensors_pro` checks hardware natively and emits a `SENSOR_UNSUPPORTED` stream exception rather than crashing the native process.
- **Desktop environment testing**: macOS desktop devices do not contain raw physical accelerometers, gyroscopes, or barometers. The plugin catches this and returns a `SENSOR_UNAVAILABLE` error to protect your code layout.
- **Android Linear Acceleration**: If `TYPE_LINEAR_ACCELERATION` is unavailable on legacy Android boards, the plugin falls back to compute high-pass delta coordinates on `TYPE_ACCELEROMETER` natively.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
