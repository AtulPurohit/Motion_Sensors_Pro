import Cocoa
import FlutterMacOS

public class MotionSensorsProPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private static var eventSink: FlutterEventSink?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger = registrar.messenger
    let methodChannel = FlutterMethodChannel(name: "motion_sensors_pro", binaryMessenger: messenger)
    let instance = MotionSensorsProPlugin()
    registrar.addMethodCallDelegate(instance, channel: methodChannel)

    // Shake Gesture
    let eventChannel = FlutterEventChannel(name: "motion_sensors_pro/shake", binaryMessenger: messenger)
    eventChannel.setStreamHandler(instance)

    // Fallback registration for all 8 raw streams on macOS to prevent missing channel exception
    let rawChannels = [
      "motion_sensors_pro/accelerometer",
      "motion_sensors_pro/user_accelerometer",
      "motion_sensors_pro/gyroscope",
      "motion_sensors_pro/magnetometer",
      "motion_sensors_pro/barometer",
      "motion_sensors_pro/attitude",
      "motion_sensors_pro/pedometer",
      "motion_sensors_pro/proximity"
    ]
    for channelName in rawChannels {
      let channel = FlutterEventChannel(name: channelName, binaryMessenger: messenger)
      channel.setStreamHandler(FallbackStreamHandler())
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "mockShake":
      MotionSensorsProPlugin.triggerShakeNotification()
      result(nil)
    case "setSensorInterval":
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    MotionSensorsProPlugin.eventSink = events
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(didReceiveShakeNotification),
      name: NSNotification.Name("UIDeviceShakeNotification"),
      object: nil
    )
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name("UIDeviceShakeNotification"), object: nil)
    MotionSensorsProPlugin.eventSink = nil
    return nil
  }

  @objc private func didReceiveShakeNotification() {
    DispatchQueue.main.async {
      MotionSensorsProPlugin.eventSink?(true)
    }
  }

  public static func triggerShakeNotification() {
    NotificationCenter.default.post(name: NSNotification.Name("UIDeviceShakeNotification"), object: nil)
  }
}

class FallbackStreamHandler: NSObject, FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    return FlutterError(code: "SENSOR_UNAVAILABLE", message: "Hardware sensors are not available on macOS desktop platforms.", details: nil)
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    return nil
  }
}
