import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:motion_sensors_pro/motion_sensors_pro.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFFFFB800),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
      ),
      home: const SensorDashboard(),
    );
  }
}

class SensorDashboard extends StatefulWidget {
  const SensorDashboard({super.key});

  @override
  State<SensorDashboard> createState() => _SensorDashboardState();
}

class _SensorDashboardState extends State<SensorDashboard> {
  // Real-time sensor state values
  AccelerometerEvent? _accelerometer;
  UserAccelerometerEvent? _userAccelerometer;
  GyroscopeEvent? _gyroscope;
  MagnetometerEvent? _magnetometer;
  BarometerEvent? _barometer;
  AttitudeEvent? _attitude;
  PedometerEvent? _pedometer;
  ProximityEvent? _proximity;
  int _shakeCount = 0;

  // Stream Subscriptions
  StreamSubscription<void>? _shakeSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<UserAccelerometerEvent>? _userAccelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<MagnetometerEvent>? _magSub;
  StreamSubscription<BarometerEvent>? _baroSub;
  StreamSubscription<AttitudeEvent>? _attitudeSub;
  StreamSubscription<PedometerEvent>? _pedometerSub;
  StreamSubscription<ProximityEvent>? _proximitySub;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    // 1. Shake Gesture
    _shakeSub = MotionSensorsPro.onShake.listen((_) {
      setState(() {
        _shakeCount++;
      });
    });

    // 2. Accelerometer
    _accelSub = MotionSensorsPro.accelerometerEvents.listen((event) {
      setState(() => _accelerometer = event);
    });

    // 3. User Accelerometer
    _userAccelSub = MotionSensorsPro.userAccelerometerEvents.listen((event) {
      setState(() => _userAccelerometer = event);
    });

    // 4. Gyroscope
    _gyroSub = MotionSensorsPro.gyroscopeEvents.listen((event) {
      setState(() => _gyroscope = event);
    });

    // 5. Magnetometer
    _magSub = MotionSensorsPro.magnetometerEvents.listen((event) {
      setState(() => _magnetometer = event);
    });

    // 6. Barometer (with graceful fallback handling)
    _baroSub = MotionSensorsPro.barometerEvents.listen(
      (event) {
        setState(() => _barometer = event);
      },
      onError: (error) {
        debugPrint('[Barometer] Error/Unsupported: $error');
      },
    );

    // 7. Attitude / 3D Orientation
    _attitudeSub = MotionSensorsPro.attitudeEvents.listen((event) {
      setState(() => _attitude = event);
    });

    // 8. Pedometer
    _pedometerSub = MotionSensorsPro.pedometerEvents.listen(
      (event) {
        setState(() => _pedometer = event);
      },
      onError: (error) {
        debugPrint('[Pedometer] Error/Unsupported: $error');
      },
    );

    // 9. Proximity
    _proximitySub = MotionSensorsPro.proximityEvents.listen(
      (event) {
        setState(() => _proximity = event);
      },
      onError: (error) {
        debugPrint('[Proximity] Error/Unsupported: $error');
      },
    );
  }

  @override
  void dispose() {
    _shakeSub?.cancel();
    _accelSub?.cancel();
    _userAccelSub?.cancel();
    _gyroSub?.cancel();
    _magSub?.cancel();
    _baroSub?.cancel();
    _attitudeSub?.cancel();
    _pedometerSub?.cancel();
    _proximitySub?.cancel();
    super.dispose();
  }

  Widget _buildSensorCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> lines,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...lines.map((line) => Text(
                        line,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Courier',
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motion Sensors Pro Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header stats block
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              margin: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB800), Color(0xFFFF5C2A)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.vibration_rounded, size: 40, color: Colors.white),
                  const SizedBox(height: 8),
                  const Text(
                    'SHAKE COUNTER',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_shakeCount',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 36),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => MotionSensorsPro.mockShake(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    icon: const Icon(Icons.science_outlined, size: 16),
                    label: const Text('Simulate Mock Shake'),
                  ),
                ],
              ),
            ),

            // Accel Card
            _buildSensorCard(
              title: 'Accelerometer (Includes Gravity)',
              icon: Icons.speed_rounded,
              color: Colors.cyan,
              lines: _accelerometer == null
                  ? ['Waiting for stream...']
                  : [
                      'X: ${_accelerometer!.x.toStringAsFixed(4)} m/s²',
                      'Y: ${_accelerometer!.y.toStringAsFixed(4)} m/s²',
                      'Z: ${_accelerometer!.z.toStringAsFixed(4)} m/s²',
                    ],
            ),

            // User Accel Card
            _buildSensorCard(
              title: 'User Accelerometer (Gravity Excluded)',
              icon: Icons.directions_run_rounded,
              color: Colors.lightGreenAccent,
              lines: _userAccelerometer == null
                  ? ['Waiting for stream...']
                  : [
                      'X: ${_userAccelerometer!.x.toStringAsFixed(4)} m/s²',
                      'Y: ${_userAccelerometer!.y.toStringAsFixed(4)} m/s²',
                      'Z: ${_userAccelerometer!.z.toStringAsFixed(4)} m/s²',
                    ],
            ),

            // Gyro Card
            _buildSensorCard(
              title: 'Gyroscope (Angular Velocity)',
              icon: Icons.screen_rotation_rounded,
              color: Colors.orange,
              lines: _gyroscope == null
                  ? ['Waiting for stream...']
                  : [
                      'X: ${_gyroscope!.x.toStringAsFixed(4)} rad/s',
                      'Y: ${_gyroscope!.y.toStringAsFixed(4)} rad/s',
                      'Z: ${_gyroscope!.z.toStringAsFixed(4)} rad/s',
                    ],
            ),

            // Magnetometer Card
            _buildSensorCard(
              title: 'Magnetometer (Magnetic Field)',
              icon: Icons.explore_rounded,
              color: Colors.purpleAccent,
              lines: _magnetometer == null
                  ? ['Waiting for stream...']
                  : [
                      'X: ${_magnetometer!.x.toStringAsFixed(4)} µT',
                      'Y: ${_magnetometer!.y.toStringAsFixed(4)} µT',
                      'Z: ${_magnetometer!.z.toStringAsFixed(4)} µT',
                    ],
            ),

            // Barometer Card
            _buildSensorCard(
              title: 'Barometer (Atmospheric Pressure)',
              icon: Icons.air_rounded,
              color: Colors.pinkAccent,
              lines: _barometer == null
                  ? ['Unsupported or waiting for stream...']
                  : [
                      'Pressure: ${_barometer!.pressure.toStringAsFixed(2)} hPa',
                      'Rel Altitude: ${_barometer!.relativeAltitude.toStringAsFixed(2)} m',
                    ],
            ),

            // Attitude/Orientation Card
            _buildSensorCard(
              title: 'Device Attitude (3D Sensor Fusion)',
              icon: Icons.grid_goldenratio_rounded,
              color: Colors.yellowAccent,
              lines: _attitude == null
                  ? ['Waiting for stream...']
                  : [
                      'Roll (Z-tilt): ${(_attitude!.roll * 180 / math.pi).toStringAsFixed(2)}°',
                      'Pitch (X-tilt): ${(_attitude!.pitch * 180 / math.pi).toStringAsFixed(2)}°',
                      'Yaw (Y-rotation): ${(_attitude!.yaw * 180 / math.pi).toStringAsFixed(2)}°',
                    ],
            ),

            // Pedometer Card
            _buildSensorCard(
              title: 'Pedometer (Step Counter)',
              icon: Icons.directions_walk_rounded,
              color: Colors.lightBlueAccent,
              lines: _pedometer == null
                  ? ['Waiting for steps...']
                  : [
                      'Steps count: ${_pedometer!.steps}',
                    ],
            ),

            // Proximity Card
            _buildSensorCard(
              title: 'Proximity Sensor (Face Detection)',
              icon: Icons.visibility_rounded,
              color: Colors.deepOrangeAccent,
              lines: _proximity == null
                  ? ['Waiting for proximity sensor...']
                  : [
                      'Object is near: ${_proximity!.isNear ? "YES 🔴" : "NO 🟢"}',
                    ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
