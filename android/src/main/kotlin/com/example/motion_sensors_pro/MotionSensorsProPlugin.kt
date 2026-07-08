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
    private lateinit var shakeEventChannel: EventChannel
    private var sensorManager: SensorManager? = null
    private var accelerometer: Sensor? = null
    private var eventSink: EventChannel.EventSink? = null

    // Configuration
    private var sensorDelayUs = SensorManager.SENSOR_DELAY_UI // Default: ~60,000 microseconds

    // Shake logic states
    private var lastUpdate: Long = 0
    private var lastX = 0f
    private var lastY = 0f
    private var lastZ = 0f
    private val shakeThreshold = 13.0f // m/s^2
    @Volatile private var lastShakeTime: Long = 0

    // Stored list of raw sensor handlers to dynamically update delay
    private val activeHandlers = mutableListOf<SensorStreamHandler>()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        val context = flutterPluginBinding.applicationContext
        val messenger = flutterPluginBinding.binaryMessenger
        sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        
        // Linear acceleration (gravity pre-subtracted)
        accelerometer = sensorManager?.getDefaultSensor(Sensor.TYPE_LINEAR_ACCELERATION) 
            ?: sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

        // Main config/mock method channel
        methodChannel = MethodChannel(messenger, "motion_sensors_pro")
        methodChannel.setMethodCallHandler(this)

        // Shake gesture channel
        shakeEventChannel = EventChannel(messenger, "motion_sensors_pro/shake")
        shakeEventChannel.setStreamHandler(this)

        // Initialize and bind the 5 raw sensor event channels
        val rawChannels = mapOf(
            "motion_sensors_pro/accelerometer" to Sensor.TYPE_ACCELEROMETER,
            "motion_sensors_pro/user_accelerometer" to Sensor.TYPE_LINEAR_ACCELERATION,
            "motion_sensors_pro/gyroscope" to Sensor.TYPE_GYROSCOPE,
            "motion_sensors_pro/magnetometer" to Sensor.TYPE_MAGNETIC_FIELD,
            "motion_sensors_pro/barometer" to Sensor.TYPE_PRESSURE
        )

        for ((channelName, sensorType) in rawChannels) {
            val channel = EventChannel(messenger, channelName)
            val handler = SensorStreamHandler(sensorType)
            channel.setStreamHandler(handler)
            activeHandlers.add(handler)
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "mockShake" -> {
                triggerShakeEvent()
                result.success(null)
            }
            "setSensorInterval" -> {
                val microseconds = call.argument<Int>("microseconds")
                if (microseconds != null) {
                    sensorDelayUs = microseconds
                    // Dynamically update sampling rate for any active raw streams!
                    for (handler in activeHandlers) {
                        handler.updateSensorRegistration()
                    }
                }
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    // --- Shake Gesture Stream Handler ---
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
                if (now - lastShakeTime > 1000) {
                    lastShakeTime = now
                    triggerShakeEvent()
                }
            }
        } else if (event.sensor.type == Sensor.TYPE_ACCELEROMETER) {
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
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            eventSink?.success(true)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        shakeEventChannel.setStreamHandler(null)
        sensorManager?.unregisterListener(this)
        for (handler in activeHandlers) {
            sensorManager?.unregisterListener(handler)
        }
        sensorManager = null
        accelerometer = null
    }

    // --- Elegant Inner Class to handle the 5 Raw Sensor streams cleanly ---
    inner class SensorStreamHandler(private val sensorType: Int) : EventChannel.StreamHandler, SensorEventListener {
        private var sensor: Sensor? = null
        private var streamSink: EventChannel.EventSink? = null

        init {
            sensor = sensorManager?.getDefaultSensor(sensorType)
        }

        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            streamSink = events
            sensor?.let {
                sensorManager?.registerListener(this, it, sensorDelayUs)
            } ?: run {
                // If sensor type is not supported on this specific device, finish stream cleanly
                events?.error("SENSOR_UNSUPPORTED", "Sensor type $sensorType is not supported on this device.", null)
            }
        }

        override fun onCancel(arguments: Any?) {
            sensor?.let {
                sensorManager?.unregisterListener(this, it)
            }
            streamSink = null
        }

        override fun onSensorChanged(event: SensorEvent) {
            // Package floats as dynamic list of doubles
            val dataList = event.values.map { it.toDouble() }
            
            // Barometer has a single pressure value. For API compatibility, 
            // we pass [pressure, relativeAltitude] where relativeAltitude is 0.0 on Android
            val payload = if (sensorType == Sensor.TYPE_PRESSURE) {
                listOf(dataList[0], 0.0)
            } else {
                dataList
            }

            android.os.Handler(android.os.Looper.getMainLooper()).post {
                streamSink?.success(payload)
            }
        }

        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

        fun updateSensorRegistration() {
            if (streamSink != null && sensor != null) {
                sensorManager?.unregisterListener(this, sensor!!)
                sensorManager?.registerListener(this, sensor!!, sensorDelayUs)
            }
        }
    }
}
