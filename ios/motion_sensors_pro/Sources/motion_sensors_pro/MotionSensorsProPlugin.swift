import Flutter
import UIKit
import CoreMotion

public class MotionSensorsProPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  // Static eventSink specifically for window shake tracking
  fileprivate static var shakeEventSink: FlutterEventSink?

  // Shared CoreMotion managers
  private let motionManager = CMMotionManager()
  private let altimeter = CMAltimeter()
  private let pedometer = CMPedometer()
  private let queue = OperationQueue()

  // Configuration: Default interval corresponds to SENSOR_DELAY_UI (~20ms / 50Hz)
  public var sensorDelaySeconds: TimeInterval = 0.02

  // Strong references to raw stream handlers to prevent garbage collection
  private var streamHandlers: [SensorStreamHandler] = []

  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger = registrar.messenger()

    // Main Method Channel
    let methodChannel = FlutterMethodChannel(
      name: "motion_sensors_pro",
      binaryMessenger: messenger
    )
    let instance = MotionSensorsProPlugin()
    registrar.addMethodCallDelegate(instance, channel: methodChannel)

    // Shake Gesture Event Channel
    let shakeEventChannel = FlutterEventChannel(
      name: "motion_sensors_pro/shake",
      binaryMessenger: messenger
    )
    shakeEventChannel.setStreamHandler(instance)

    // Raw Sensor Channels (5 original + 3 bonus)
    let rawChannels = [
      ("motion_sensors_pro/accelerometer", "accelerometer"),
      ("motion_sensors_pro/user_accelerometer", "user_accelerometer"),
      ("motion_sensors_pro/gyroscope", "gyroscope"),
      ("motion_sensors_pro/magnetometer", "magnetometer"),
      ("motion_sensors_pro/barometer", "barometer"),
      ("motion_sensors_pro/attitude", "attitude"),
      ("motion_sensors_pro/pedometer", "pedometer"),
      ("motion_sensors_pro/proximity", "proximity")
    ]

    for (channelName, sensorType) in rawChannels {
      let channel = FlutterEventChannel(name: channelName, binaryMessenger: messenger)
      let handler = SensorStreamHandler(
        sensorType: sensorType,
        motionManager: instance.motionManager,
        altimeter: instance.altimeter,
        pedometer: instance.pedometer,
        queue: instance.queue,
        parent: instance
      )
      channel.setStreamHandler(handler)
      instance.streamHandlers.add(handler)
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "mockShake":
      MotionSensorsProPlugin.triggerShakeNotification()
      result(nil)
    case "setSensorInterval":
      if let args = call.arguments as? [String: Any],
         let microseconds = args["microseconds"] as? Double {
        sensorDelaySeconds = microseconds / 1_000_000.0
        // Dynamically set interval properties in the running motion manager
        motionManager.accelerometerUpdateInterval = sensorDelaySeconds
        motionManager.gyroUpdateInterval = sensorDelaySeconds
        motionManager.magnetometerUpdateInterval = sensorDelaySeconds
        motionManager.deviceMotionUpdateInterval = sensorDelaySeconds
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // --- Shake Event Stream Handling ---
  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    MotionSensorsProPlugin.shakeEventSink = events
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(didReceiveShakeNotification),
      name: NSNotification.Name("UIDeviceShakeNotification"),
      object: nil
    )
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    NotificationCenter.default.removeObserver(
      self,
      name: NSNotification.Name("UIDeviceShakeNotification"),
      object: nil
    )
    MotionSensorsProPlugin.shakeEventSink = nil
    return nil
  }

  @objc private func didReceiveShakeNotification() {
    guard MotionSensorsProPlugin.shakeEventSink != nil else { return }
    DispatchQueue.main.async {
      MotionSensorsProPlugin.shakeEventSink?(true)
    }
  }

  public static func triggerShakeNotification() {
    guard shakeEventSink != nil else { return }
    NotificationCenter.default.post(
      name: NSNotification.Name("UIDeviceShakeNotification"),
      object: nil
    )
  }
}

// --- Dynamic Raw Sensor Stream Handlers on iOS ---
class SensorStreamHandler: NSObject, FlutterStreamHandler {
  private let sensorType: String
  private let motionManager: CMMotionManager
  private let altimeter: CMAltimeter
  private let pedometer: CMPedometer
  private let queue: OperationQueue
  private weak var parent: MotionSensorsProPlugin?

  // Callback sink for proximity notifications
  private var proximityEventSink: FlutterEventSink?

  init(
    sensorType: String,
    motionManager: CMMotionManager,
    altimeter: CMAltimeter,
    pedometer: CMPedometer,
    queue: OperationQueue,
    parent: MotionSensorsProPlugin
  ) {
    self.sensorType = sensorType
    self.motionManager = motionManager
    self.altimeter = altimeter
    self.pedometer = pedometer
    self.queue = queue
    self.parent = parent
  }

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    let delay = parent?.sensorDelaySeconds ?? 0.02

    switch sensorType {
    case "accelerometer":
      guard motionManager.isAccelerometerAvailable else {
        return FlutterError(code: "SENSOR_UNAVAILABLE", message: "Accelerometer is not available on this device", details: nil)
      }
      motionManager.accelerometerUpdateInterval = delay
      motionManager.startAccelerometerUpdates(to: queue) { data, error in
        guard let data = data else { return }
        // Convert to m/s^2 (multiply by standard gravity factor 9.80665)
        let g = 9.80665
        events([data.acceleration.x * g, data.acceleration.y * g, data.acceleration.z * g])
      }

    case "user_accelerometer":
      guard motionManager.isDeviceMotionAvailable else {
        return FlutterError(code: "SENSOR_UNAVAILABLE", message: "Device motion is not available on this device", details: nil)
      }
      motionManager.deviceMotionUpdateInterval = delay
      motionManager.startDeviceMotionUpdates(to: queue) { motion, error in
        guard let motion = motion else { return }
        let g = 9.80665
        events([motion.userAcceleration.x * g, motion.userAcceleration.y * g, motion.userAcceleration.z * g])
      }

    case "gyroscope":
      guard motionManager.isGyroAvailable else {
        return FlutterError(code: "SENSOR_UNAVAILABLE", message: "Gyroscope is not available on this device", details: nil)
      }
      motionManager.gyroUpdateInterval = delay
      motionManager.startGyroUpdates(to: queue) { data, error in
        guard let data = data else { return }
        events([data.rotationRate.x, data.rotationRate.y, data.rotationRate.z])
      }

    case "magnetometer":
      guard motionManager.isMagnetometerAvailable else {
        return FlutterError(code: "SENSOR_UNAVAILABLE", message: "Magnetometer is not available on this device", details: nil)
      }
      motionManager.magnetometerUpdateInterval = delay
      motionManager.startMagnetometerUpdates(to: queue) { data, error in
        guard let data = data else { return }
        events([data.magneticField.x, data.magneticField.y, data.magneticField.z])
      }

    case "barometer":
      if #available(iOS 8.0, *), CMAltimeter.isRelativeAltitudeAvailable() {
        altimeter.startRelativeAltitudeUpdates(to: queue) { data, error in
          guard let data = data else { return }
          // Convert kPa (kilopascals) to hPa (hectopascals/millibars) by multiplying by 10
          let hPa = data.pressure.doubleValue * 10.0
          events([hPa, data.relativeAltitude.doubleValue])
        }
      } else {
        return FlutterError(code: "SENSOR_UNSUPPORTED", message: "Barometer (relative altitude updates) is not available on this device", details: nil)
      }

    case "attitude":
      guard motionManager.isDeviceMotionAvailable else {
        return FlutterError(code: "SENSOR_UNAVAILABLE", message: "Device motion is not available on this device", details: nil)
      }
      motionManager.deviceMotionUpdateInterval = delay
      motionManager.startDeviceMotionUpdates(to: queue) { motion, error in
        guard let motion = motion else { return }
        events([motion.attitude.roll, motion.attitude.pitch, motion.attitude.yaw])
      }

    case "pedometer":
      guard CMPedometer.isStepCountingAvailable() else {
        return FlutterError(code: "SENSOR_UNSUPPORTED", message: "Step counting is not supported on this device", details: nil)
      }
      pedometer.startUpdates(from: Date()) { data, error in
        guard let data = data else { return }
        events(data.numberOfSteps.intValue)
      }

    case "proximity":
      DispatchQueue.main.async {
        UIDevice.current.isProximityMonitoringEnabled = true
        events(UIDevice.current.proximityState ? 1 : 0)
        
        NotificationCenter.default.addObserver(
          self,
          selector: #selector(self.proximityStateChanged(_:)),
          name: UIDevice.proximityStateDidChangeNotification,
          object: nil
        )
        self.proximityEventSink = events
      }

    default:
      break
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    switch sensorType {
    case "accelerometer":
      motionManager.stopAccelerometerUpdates()
    case "user_accelerometer", "attitude":
      motionManager.stopDeviceMotionUpdates()
    case "gyroscope":
      motionManager.stopGyroUpdates()
    case "magnetometer":
      motionManager.stopMagnetometerUpdates()
    case "barometer":
      if #available(iOS 8.0, *) {
        altimeter.stopRelativeAltitudeUpdates()
      }
    case "pedometer":
      pedometer.stopUpdates()
    case "proximity":
      DispatchQueue.main.async {
        UIDevice.current.isProximityMonitoringEnabled = false
        NotificationCenter.default.removeObserver(
          self,
          name: UIDevice.proximityStateDidChangeNotification,
          object: nil
        )
        self.proximityEventSink = nil
      }
    default:
      break
    }
    return nil
  }

  @objc private func proximityStateChanged(_ notification: Notification) {
    guard let events = proximityEventSink else { return }
    let isNear = UIDevice.current.proximityState
    events(isNear ? 1 : 0)
  }
}

// UIWindow shake interception remains in place
extension UIWindow {
  open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
    if motion == .motionShake {
      if MotionSensorsProPlugin.shakeEventSink != nil {
        MotionSensorsProPlugin.triggerShakeNotification()
      }
    }
    super.motionEnded(motion, with: event)
  }
}

// Helper extension to dynamically append handlers
extension Array {
  mutating func add(_ element: Element) {
    self.append(element)
  }
}
