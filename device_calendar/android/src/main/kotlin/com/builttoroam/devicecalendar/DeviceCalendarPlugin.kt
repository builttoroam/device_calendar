package com.builttoroam.devicecalendar

import android.app.Activity
import android.content.Context
import android.provider.CalendarContract

import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.PluginRegistry.Registrar


// Projection array. Creating indices for this array instead of doing
// dynamic lookups improves performance.
val EVENT_PROJECTION: Array<String> = arrayOf(
        CalendarContract.Calendars._ID,                           // 0
        CalendarContract.Calendars.ACCOUNT_NAME,                  // 1
        CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,         // 2
        CalendarContract.Calendars.OWNER_ACCOUNT                  // 3
);

// The indices for the projection array above.
val PROJECTION_ID_INDEX: Int = 0;
val PROJECTION_ACCOUNT_NAME_INDEX: Int = 1;
val PROJECTION_DISPLAY_NAME_INDEX: Int = 2;
val PROJECTION_OWNER_ACCOUNT_INDEX: Int = 3;

class DeviceCalendarPlugin() : MethodCallHandler {

    private lateinit var _registrar: Registrar;
    private lateinit var _calendarService: CalendarService;

    private constructor(registrar: Registrar, calendarService: CalendarService) : this() {
        _registrar = registrar;
        _calendarService = calendarService;
    }

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar): Unit {
            val context: Context = registrar.context();
            val activity: Activity = registrar.activity();

            val calendarService: CalendarService = CalendarService(activity, context);
            val instance: DeviceCalendarPlugin = DeviceCalendarPlugin(registrar, calendarService);

            val channel = MethodChannel(registrar.messenger(), "device_calendar")
            channel.setMethodCallHandler(instance)

            val calendarsChannel = MethodChannel(registrar.messenger(), "plugins.flutter.io/calendars")
            calendarsChannel.setMethodCallHandler(instance)

            registrar.addRequestPermissionsResultListener(calendarService);
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result): Unit {
        _calendarService.setPendingResult(result);

        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "retrieve" -> {
                val calendars = _calendarService.retrieveCalendars();

                // result.success("OK");
            }
            else -> {
                result.notImplemented()
            }
        }
    }
}
