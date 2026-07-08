package com.example.motion_sensors_pro

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlin.math.sqrt

/** MotionSensorsProPlugin */
class MotionSensorsProPlugin :
    FlutterPlugin,
    MethodCallHandler,
    EventChannel.StreamHandler,
    SensorEventListener {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var sensorManager: SensorManager? = null
    private var accelerometer: Sensor? = null
    private var eventSink: EventChannel.EventSink? = null

    private var lastUpdate: Long = 0
    private var lastX = 0f
    private var lastY = 0f
    private var lastZ = 0f
    private val shakeThreshold = 13.0f // m/s^2 (excluding gravity / relative diff)
    @Volatile private var lastShakeTime: Long = 0 // @Volatile prevents multi-core race where two rapid shakes both pass the 1s cooldown check

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        val context = flutterPluginBinding.applicationContext
        sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        // Linear acceleration has gravity pre-subtracted by the Android OS!
        accelerometer = sensorManager?.getDefaultSensor(Sensor.TYPE_LINEAR_ACCELERATION) 
            ?: sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER) // Fallback to raw accelerometer if linear is not supported

        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "motion_sensors_pro")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "motion_sensors_pro/shake")
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "mockShake") {
            triggerShakeEvent()
            result.success(null)
        } else {
            result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        accelerometer?.let {
            sensorManager?.registerListener(this, it, SensorManager.SENSOR_DELAY_UI)
        }
    }

    override fun onCancel(arguments: Any?) {
        sensorManager?.unregisterListener(this)
        eventSink = null
    }

    override fun onSensorChanged(event: SensorEvent) {
        if (event.sensor.type == Sensor.TYPE_LINEAR_ACCELERATION) {
            val x = event.values[0]
            val y = event.values[1]
            val z = event.values[2]
            val acceleration = sqrt((x * x + y * y + z * z).toDouble()).toFloat()
            if (acceleration > shakeThreshold) {
                val now = System.currentTimeMillis()
                if (now - lastShakeTime > 1000) { // 1 sec cooldown
                    lastShakeTime = now
                    triggerShakeEvent()
                }
            }
        } else if (event.sensor.type == Sensor.TYPE_ACCELEROMETER) {
            // Fallback: compute vector magnitude of delta acceleration
            // The original formula abs(x+y+z - lastX-lastY-lastZ) is incorrect:
            // it can cancel out when axes move in opposite directions.
            // Proper approach: magnitude of the delta vector (dx, dy, dz).
            val curTime = System.currentTimeMillis()
            if ((curTime - lastUpdate) > 100) {
                val diffTime = curTime - lastUpdate
                lastUpdate = curTime
                val x = event.values[0]
                val y = event.values[1]
                val z = event.values[2]
                val dx = x - lastX
                val dy = y - lastY
                val dz = z - lastZ
                val deltaMagnitude = sqrt((dx * dx + dy * dy + dz * dz).toDouble()).toFloat()
                val speed = deltaMagnitude / diffTime * 10000
                if (speed > 800) {
                    val now = System.currentTimeMillis()
                    if (now - lastShakeTime > 1000) {
                        lastShakeTime = now
                        triggerShakeEvent()
                    }
                }
                lastX = x
                lastY = y
                lastZ = z
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    private fun triggerShakeEvent() {
        // Run on the main UI thread to ensure thread safety with Flutter EventSink
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            eventSink?.success(true)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        sensorManager?.unregisterListener(this)
        sensorManager = null
        accelerometer = null
    }
}
