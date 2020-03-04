package com.builttoroam.dual_screen

import android.app.Activity
import android.content.Context
import android.os.SystemClock
import androidx.annotation.NonNull
import com.microsoft.device.display.DisplayMask
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit


/** DualScreenPlugin */
public class DualScreenPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler,
        ActivityAware {
    private val METHOD_CHANNEL_NAME = "plugins.builttoroam.com/dual_screen/methods"
    private val EVENT_CHANNEL_NAME = "plugins.builttoroam.com/dual_screen/events"
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var applicationContext: Context? = null
    private var activity: Activity? = null

    fun registerPlugin(context: Context?, messenger: BinaryMessenger?) {
        activity = this.activity
        applicationContext = context
        MethodChannel(messenger, METHOD_CHANNEL_NAME).setMethodCallHandler(this)
        EventChannel(messenger, EVENT_CHANNEL_NAME).setStreamHandler(this)
    }

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        this.registerPlugin(binding.getApplicationContext(), binding.getBinaryMessenger());
    }

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            DualScreenPlugin().registerPlugin(registrar.context(), registrar.messenger())
        }
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "isDualScreenDevice" -> {
                result.success(isDualScreenDevice())
            }
            "isAppSpanned" -> {
                if (isDualScreenDevice()) {
                    result.success(isAppSpanned())
                } else {
                    result.success(false)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventSink?) {
        events!!.success(isAppSpanned())
    }

    override fun onCancel(arguments: Any?) {
        TODO("not implemented")
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.activity = binding.activity;
    }


    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        this.activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        this.activity = null
    }

    override fun onDetachedFromActivity() {
        this.activity = null
    }

    fun isDualScreenDevice(): Boolean {
        return applicationContext?.getPackageManager()!!.hasSystemFeature("com.microsoft.device.display.displaymask")
    }

    fun isAppSpanned(): Boolean {
        var boundings = DisplayMask.fromResourcesRectApproximation(this.activity).getBoundingRects()
        if (boundings.isEmpty()) {
            return false
        }
        var drawingRect = android.graphics.Rect()
        activity?.getWindow()?.getDecorView()?.getRootView()?.getDrawingRect(drawingRect)
        return boundings.get(0).intersect(drawingRect)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = null
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }
}
