package com.builttoroam.dual_screen

import android.app.Activity
import android.content.Context
import android.view.View
import android.view.View.OnLayoutChangeListener
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

/** DualScreenPlugin */
public class DualScreenPlugin :
    FlutterPlugin,
    MethodCallHandler,
    EventChannel.StreamHandler,
    ActivityAware {
    private val METHOD_CHANNEL_NAME = "plugins.builttoroam.com/dual_screen/methods"
    private val EVENT_CHANNEL_NAME = "plugins.builttoroam.com/dual_screen/events"
    private val DISPLAY_MASK_SYSTEM_FEATURE = "com.microsoft.device.display.displaymask"
    private val IS_DUAL_SCREEN_DEVICE = "isDualScreenDevice"
    private val IS_APP_SPANNED = "isAppSpanned"
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var context: Context? = null
    private var activity: Activity? = null

    fun registerPlugin(context: Context?, messenger: BinaryMessenger?) {
        this.context = context
        MethodChannel(messenger, METHOD_CHANNEL_NAME).setMethodCallHandler(this)
        EventChannel(messenger, EVENT_CHANNEL_NAME).setStreamHandler(this)
    }

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        this.registerPlugin(binding.getApplicationContext(), binding.getBinaryMessenger())
    }

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            DualScreenPlugin().registerPlugin(registrar.context(), registrar.messenger())
        }
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            IS_DUAL_SCREEN_DEVICE -> {
                result.success(isDualScreenDevice())
            }
            IS_APP_SPANNED -> {
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
        activity?.getWindow()?.getDecorView()?.getRootView()?.addOnLayoutChangeListener(object : OnLayoutChangeListener {
            override fun onLayoutChange(
                v: View?,
                left: Int,
                top: Int,
                right: Int,
                bottom: Int,
                oldLeft: Int,
                oldTop: Int,
                oldRight: Int,
                oldBottom: Int
            ) {
                events?.success(isAppSpanned())
            }
        })
    }

    override fun onCancel(arguments: Any?) {
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.activity = binding.activity
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
        val packageManager = context?.getPackageManager()
        if (packageManager != null) {
            return packageManager.hasSystemFeature(
                DISPLAY_MASK_SYSTEM_FEATURE
            )
        }
        return false
    }

    fun isAppSpanned(): Boolean {
        if (isDualScreenDevice()) {
            var boundings = DisplayMask.fromResourcesRectApproximation(this.activity).getBoundingRects()
            if (boundings.isEmpty()) {
                return false
            }
            var drawingRect = android.graphics.Rect()
            activity?.getWindow()?.getDecorView()?.getRootView()?.getDrawingRect(drawingRect)
            // 0 is the first bounding rectangle
            return boundings.get(0).intersect(drawingRect)
        } else {
            return false
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        context = null
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }
}
