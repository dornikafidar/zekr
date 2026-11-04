package com.zekr.zekr

import android.content.Context
import android.hardware.GeomagneticField
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Handler
import android.os.Looper
import android.view.Surface
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, "zekr/geomag")
            .setMethodCallHandler { call, result ->
                if (call.method != "declination") return@setMethodCallHandler result.notImplemented()
                val lat = call.argument<Double>("lat") ?: return@setMethodCallHandler result.error("args", null, null)
                val lng = call.argument<Double>("lng") ?: return@setMethodCallHandler result.error("args", null, null)
                val alt = call.argument<Double>("alt") ?: 0.0
                val field = GeomagneticField(lat.toFloat(), lng.toFloat(), alt.toFloat(), System.currentTimeMillis())
                result.success(field.declination.toDouble())
            }
        EventChannel(messenger, "zekr/heading").setStreamHandler(HeadingStream())
    }

    /**
     * Magnetic yaw from TYPE_ROTATION_VECTOR + getOrientation — Android's own
     * tilt-compensated compass heading (stable through pitch/roll). Near
     * vertical (±90° pitch) Euler yaw locks with roll; we still emit pitch so
     * Flutter can freeze and warn. No custom axis blending.
     */
    private inner class HeadingStream : EventChannel.StreamHandler, SensorEventListener {
        private val sm = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        private val main = Handler(Looper.getMainLooper())
        private var sink: EventChannel.EventSink? = null
        private var accuracyDeg = 45.0
        private val r = FloatArray(9)
        private val mapped = FloatArray(9)
        private val orient = FloatArray(3)
        private val rv = FloatArray(4)

        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
            val sensor = sm.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
                ?: sm.getDefaultSensor(Sensor.TYPE_GEOMAGNETIC_ROTATION_VECTOR)
            if (sensor == null) {
                events.error("no_sensor", "no rotation vector", null)
                return
            }
            sink = events
            sm.registerListener(this, sensor, SensorManager.SENSOR_DELAY_GAME)
        }

        override fun onCancel(arguments: Any?) {
            sm.unregisterListener(this)
            sink = null
        }

        override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {
            accuracyDeg = when (accuracy) {
                SensorManager.SENSOR_STATUS_ACCURACY_HIGH -> 15.0
                SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM -> 30.0
                SensorManager.SENSOR_STATUS_ACCURACY_LOW -> 45.0
                SensorManager.SENSOR_STATUS_UNRELIABLE -> 90.0
                else -> 45.0
            }
        }

        override fun onSensorChanged(event: SensorEvent) {
            val v = if (event.values.size > 4) {
                System.arraycopy(event.values, 0, rv, 0, 4)
                rv
            } else {
                event.values
            }
            SensorManager.getRotationMatrixFromVector(r, v)

            // Match current display rotation (portrait lock → usually ROTATION_0).
            @Suppress("DEPRECATION")
            val rotation = windowManager.defaultDisplay.rotation
            val (axisX, axisY) = when (rotation) {
                Surface.ROTATION_90 -> SensorManager.AXIS_Y to SensorManager.AXIS_MINUS_X
                Surface.ROTATION_180 -> SensorManager.AXIS_MINUS_X to SensorManager.AXIS_MINUS_Y
                Surface.ROTATION_270 -> SensorManager.AXIS_MINUS_Y to SensorManager.AXIS_X
                else -> SensorManager.AXIS_X to SensorManager.AXIS_Y
            }
            SensorManager.remapCoordinateSystem(r, axisX, axisY, mapped)
            SensorManager.getOrientation(mapped, orient)

            var deg = Math.toDegrees(orient[0].toDouble())
            if (deg < 0) deg += 360.0
            val pitchDeg = Math.toDegrees(orient[1].toDouble())
            val payload = listOf(deg, accuracyDeg, pitchDeg)
            main.post { sink?.success(payload) }
        }
    }
}
