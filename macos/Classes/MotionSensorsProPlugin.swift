import Cocoa
import FlutterMacOS

public class MotionSensorsProPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private static var eventSink: FlutterEventSink?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(name: "motion_sensors_pro", binaryMessenger: registrar.messenger)
    let instance = MotionSensorsProPlugin()
    registrar.addMethodCallDelegate(instance, channel: methodChannel)

    let eventChannel = FlutterEventChannel(name: "motion_sensors_pro/shake", binaryMessenger: registrar.messenger)
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "mockShake":
      MotionSensorsProPlugin.triggerShakeNotification()
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
