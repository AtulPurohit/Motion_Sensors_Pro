import Flutter
import UIKit

public class MotionSensorsProPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  // Note: eventSink is a static var so the UIWindow extension can reach it
  // without holding a reference to the plugin instance.
  fileprivate static var eventSink: FlutterEventSink?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(
      name: "motion_sensors_pro",
      binaryMessenger: registrar.messenger()
    )
    let instance = MotionSensorsProPlugin()
    registrar.addMethodCallDelegate(instance, channel: methodChannel)

    let eventChannel = FlutterEventChannel(
      name: "motion_sensors_pro/shake",
      binaryMessenger: registrar.messenger()
    )
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

  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
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
    NotificationCenter.default.removeObserver(
      self,
      name: NSNotification.Name("UIDeviceShakeNotification"),
      object: nil
    )
    MotionSensorsProPlugin.eventSink = nil
    return nil
  }

  @objc private func didReceiveShakeNotification() {
    // Guard: only fire if a Flutter listener is active.
    // Without this check, events posted after onCancel() is called can crash
    // if the EventSink has already been cleaned up.
    guard MotionSensorsProPlugin.eventSink != nil else { return }
    DispatchQueue.main.async {
      MotionSensorsProPlugin.eventSink?(true)
    }
  }

  public static func triggerShakeNotification() {
    // Guard: only post the notification if a listener is subscribed.
    // This prevents spurious NotificationCenter posts when no Flutter
    // stream listener is active (e.g. during mockShake() in tests).
    guard eventSink != nil else { return }
    NotificationCenter.default.post(
      name: NSNotification.Name("UIDeviceShakeNotification"),
      object: nil
    )
  }
}

// UIWindow extension to intercept native shake gestures.
//
// Using `open override` on UIWindow is intentional: this is the standard
// Flutter plugin pattern for capturing motionEnded on iOS. The `super.motionEnded`
// call at the end ensures other UIWindow subclasses (including Flutter's own
// FlutterView) still receive the event and are not broken.
extension UIWindow {
  open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
    if motion == .motionShake {
      // Only post if there is an active subscriber — avoids unnecessary
      // NotificationCenter traffic when the Dart stream has no listeners.
      if MotionSensorsProPlugin.eventSink != nil {
        MotionSensorsProPlugin.triggerShakeNotification()
      }
    }
    super.motionEnded(motion, with: event)
  }
}
