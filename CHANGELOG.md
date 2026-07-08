## 1.0.0

* **Stable Production Release**:
  * Unifies **high-speed native shake gesture classification** on iOS and Android with zero platform channel traffic when stationary.
  * Intercepts the native Xcode Simulator **Shake Gesture** command directly (`motionEnded` handler) for mock-free testing.
  * Exposes raw high-performance streams for:
    * **Accelerometer** (raw 3-axis acceleration with gravity in $m/s^2$)
    * **User Accelerometer** (gravity mathematically subtracted by OS in $m/s^2$)
    * **Gyroscope** (angular velocity in $rad/s$)
    * **Magnetometer** (geomagnetic field in $\mu T$)
    * **Barometer** (pressure in $hPa$ and relative altitude in meters)
  * Implements 3 bonus sensors:
    * **Device Attitude** (absolute 3D orientation: Pitch, Roll, Yaw in radians via Sensor Fusion)
    * **Pedometer** (low-power step count updates)
    * **Proximity Sensor** (face detection/screen obstruction tracking)
  * Implements dynamic sampling intervals via `MotionSensorsPro.setSensorInterval(Duration)`.
  * Fully supports **macOS** and **Web** with safe native fallback channel mappings and HTML5 DeviceMotion orientation mapping.
