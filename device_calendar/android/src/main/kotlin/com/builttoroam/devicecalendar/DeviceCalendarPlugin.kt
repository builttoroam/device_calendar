package com.builttoroam.devicecalendar

import android.app.Activity
import android.content.Context
import com.builttoroam.devicecalendar.models.Event

import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.PluginRegistry.Registrar


const val CHANNEL_NAME = "plugins.builttoroam.com/device_calendar"


class DeviceCalendarPlugin() : MethodCallHandler {

    private lateinit var _registrar: Registrar
    private lateinit var _calendarDelegate: CalendarDelegate

    // Methods
    val REQUEST_PERMISSIONS_METHOD = "requestPermissions"
    val HAS_PERMISSIONS_METHOD = "hasPermissions"
    val RETRIEVE_CALENDARS_METHOD = "retrieveCalendars"
    val RETRIEVE_EVENTS_METHOD = "retrieveEvents"
    val DELETE_EVENT_METHOD = "deleteEvent"
    val CREATE_OR_UPDATE_EVENT_METHOD = "createOrUpdateEvent"

    // Method arguments
    val CALENDAR_ID_ARGUMENT = "calendarId"
    val CALENDAR_EVENTS_START_DATE_ARGUMENT = "startDate"
    val CALENDAR_EVENTS_END_DATE_ARGUMENT = "endDate"
    val CALENDAR_EVENTS_IDS_ARGUMENT = "eventIds"
    val EVENT_ID_ARGUMENT = "eventId"
    val EVENT_TITLE_ARGUMENT = "eventTitle"
    val EVENT_DESCRIPTION_ARGUMENT = "eventDescription"
    val EVENT_START_DATE_ARGUMENT = "eventStartDate"
    val EVENT_END_DATE_ARGUMENT = "eventEndDate"

    private constructor(registrar: Registrar, calendarDelegate: CalendarDelegate) : this() {
        _registrar = registrar
        _calendarDelegate = calendarDelegate
    }

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar): Unit {
            val context: Context = registrar.context()
            val activity: Activity = registrar.activity()

            val calendarDelegate = CalendarDelegate(activity, context)
            val instance = DeviceCalendarPlugin(registrar, calendarDelegate)

            val channel = MethodChannel(registrar.messenger(), "device_calendar")
            channel.setMethodCallHandler(instance)

            val calendarsChannel = MethodChannel(registrar.messenger(), CHANNEL_NAME)
            calendarsChannel.setMethodCallHandler(instance)

            registrar.addRequestPermissionsResultListener(calendarDelegate)
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result): Unit {
        when (call.method) {
            REQUEST_PERMISSIONS_METHOD -> {
                _calendarDelegate.requestPermissions(result)
            }
            HAS_PERMISSIONS_METHOD -> {
                _calendarDelegate.hasPermissions(result)
            }
            RETRIEVE_CALENDARS_METHOD -> {
                _calendarDelegate.retrieveCalendars(result)
            }
            RETRIEVE_EVENTS_METHOD -> {
                val calendarId = call.argument<String>(CALENDAR_ID_ARGUMENT)
                val startDate = call.argument<Long>(CALENDAR_EVENTS_START_DATE_ARGUMENT)
                val endDate = call.argument<Long>(CALENDAR_EVENTS_END_DATE_ARGUMENT)
                val eventIds = call.argument<List<String>>(CALENDAR_EVENTS_IDS_ARGUMENT) ?: listOf()

                _calendarDelegate.retrieveEvents(calendarId!!, startDate, endDate, eventIds, result)
            }
            CREATE_OR_UPDATE_EVENT_METHOD -> {
                val calendarId = call.argument<String>(CALENDAR_ID_ARGUMENT)
                val eventId = call.argument<String>(EVENT_ID_ARGUMENT)
                val eventTitle = call.argument<String>(EVENT_TITLE_ARGUMENT)
                val eventDescription = call.argument<String>(EVENT_DESCRIPTION_ARGUMENT)
                val eventStart = call.argument<Long>(EVENT_START_DATE_ARGUMENT)
                val eventEnd = call.argument<Long>(EVENT_END_DATE_ARGUMENT)

                val event = Event(eventTitle!!)
                event.calendarId = calendarId
                event.eventId = eventId
                event.description = eventDescription
                event.start = eventStart!!
                event.end = eventEnd!!

                _calendarDelegate.createOrUpdateEvent(calendarId!!, event, result)
            }
            DELETE_EVENT_METHOD -> {
                val calendarId = call.argument<String>(CALENDAR_ID_ARGUMENT)
                val eventId = call.argument<String>(EVENT_ID_ARGUMENT)

                _calendarDelegate.deleteEvent(calendarId!!, eventId!!, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }
}
