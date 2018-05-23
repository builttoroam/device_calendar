package com.builttoroam.devicecalendar

import android.app.Activity
import android.content.Context
import com.builttoroam.devicecalendar.common.ErrorCodes
import com.builttoroam.devicecalendar.common.ErrorMessages.Companion.CALENDAR_ID_INVALID_ARGUMENT_NOT_SPECIFIED_MESSAGE
import com.builttoroam.devicecalendar.common.ErrorMessages.Companion.CREATE_EVENT_ARGUMENTS_NOT_VALID_MESSAGE
import com.builttoroam.devicecalendar.common.ErrorMessages.Companion.EVENT_ID_INVALID_ARGUMENT_NOT_SPECIFIED_MESSAGE

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
    val DELETE_CALENDAR_EVENT_METHOD = "deleteEvent";
    val CREATE_CALENDAR_EVENT_METHOD = "createEvent";

    // Method arguments
    val CALENDAR_ID_ARGUMENT = "calendarId";
    val EVENT_ID_ARGUMENT = "eventId";
    val EVENT_TITLE_ARGUMENT = "eventTitle";
    val EVENT_START_DATE_ARGUMENT = "eventStartDate";
    val EVENT_END_DATE_ARGUMENT = "eventEndDate";

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
                _calendarService.retrieveCalendars();
            }
            RETRIEVE_CALENDAR_EVENTS_METHOD -> {
                val calendarId = call.argument<String>(CALENDAR_ID_ARGUMENT);
                if (calendarId == null || calendarId.isEmpty()) {
                    result.error(ErrorCodes.INVALID_ARGUMENT, CALENDAR_ID_INVALID_ARGUMENT_NOT_SPECIFIED_MESSAGE, null);
                } else {
                    _calendarService.retrieveEvents(calendarId);
                }
            }
            CREATE_CALENDAR_EVENT_METHOD -> {
                val calendarId = call.argument<String>(CALENDAR_ID_ARGUMENT);
                val eventTitle = call.argument<String>(EVENT_TITLE_ARGUMENT);
                val eventStart = call.argument<Long>(EVENT_START_DATE_ARGUMENT);
                val eventEnd = call.argument<Long>(EVENT_END_DATE_ARGUMENT);

                if (calendarId == null || calendarId.isEmpty() || eventTitle == null || eventTitle.isEmpty()) {
                    result.error(ErrorCodes.INVALID_ARGUMENT, CREATE_EVENT_ARGUMENTS_NOT_VALID_MESSAGE, null);
                    return;
                }

                _calendarService.createEvent(calendarId, eventTitle, eventStart, eventEnd);
            }
            DELETE_CALENDAR_EVENT_METHOD -> {
                val calendarId = call.argument<String>(CALENDAR_ID_ARGUMENT);
                val eventId = call.argument<String>(EVENT_ID_ARGUMENT);
                if (calendarId == null || calendarId.isEmpty()) {
                    result.error(ErrorCodes.INVALID_ARGUMENT, CALENDAR_ID_INVALID_ARGUMENT_NOT_SPECIFIED_MESSAGE, null);
                    return;
                }
                if (eventId == null || eventId.isEmpty()) {
                    result.error(ErrorCodes.INVALID_ARGUMENT, EVENT_ID_INVALID_ARGUMENT_NOT_SPECIFIED_MESSAGE, null);
                    return;
                }

                _calendarService.deleteEvent(calendarId, eventId);
            }
            else -> {
                result.notImplemented()
            }
        }
    }
}
