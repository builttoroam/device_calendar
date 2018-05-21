package com.builttoroam.devicecalendar

import android.app.Activity
import android.content.Context
import android.provider.CalendarContract

import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.PluginRegistry.Registrar


const val CHANNEL_NAME = "plugins.builttoroam.com/device_calendar";


class DeviceCalendarPlugin() : MethodCallHandler {

    private lateinit var _registrar: Registrar;
    private lateinit var _calendarService: CalendarService;

    // Methods
    val RETRIEVE_CALENDARS_METHOD = "retrieveCalendars";
    val RETRIEVE_CALENDAR_EVENTS_METHOD = "retrieveEvents";

    // Method arguments
    val CALENDAR_ID_ARGUMENT = "calendarId";

    private constructor(registrar: Registrar, calendarService: CalendarService) : this() {
        _registrar = registrar;
        _calendarService = calendarService;
    }

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar): Unit {
            val context: Context = registrar.context();
            val activity: Activity = registrar.activity();

            val calendarService = CalendarService(activity, context);
            val instance = DeviceCalendarPlugin(registrar, calendarService);

            val channel = MethodChannel(registrar.messenger(), "device_calendar")
            channel.setMethodCallHandler(instance)

            val calendarsChannel = MethodChannel(registrar.messenger(), CHANNEL_NAME)
            calendarsChannel.setMethodCallHandler(instance)

            registrar.addRequestPermissionsResultListener(calendarService);
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result): Unit {
        _calendarService.setPendingResult(result);

        when (call.method) {
            RETRIEVE_CALENDARS_METHOD -> {
                val calendars = _calendarService.retrieveCalendars();
            }
            RETRIEVE_CALENDAR_EVENTS_METHOD -> {
                val calendarId = call.argument<String>(CALENDAR_ID_ARGUMENT);
                if (calendarId?.isNullOrEmpty() ?: true) {
                    result.error("invalid_argument", "Calendar ID argument has not been specified or is invalid", null);
                } else {
                    val events = _calendarService.retrieveEvents(calendarId);
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }
}
