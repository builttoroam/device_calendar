package com.builttoroam.devicecalendar

import android.app.Activity
import android.content.Context
import com.builttoroam.devicecalendar.common.RecurrenceFrequency
import com.builttoroam.devicecalendar.models.Event
import com.builttoroam.devicecalendar.models.RecurrenceRule

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
    private val REQUEST_PERMISSIONS_METHOD = "requestPermissions"
    private val HAS_PERMISSIONS_METHOD = "hasPermissions"
    private val RETRIEVE_CALENDARS_METHOD = "retrieveCalendars"
    private val RETRIEVE_EVENTS_METHOD = "retrieveEvents"
    private val DELETE_EVENT_METHOD = "deleteEvent"
    private val CREATE_OR_UPDATE_EVENT_METHOD = "createOrUpdateEvent"

    // Method arguments
    private val CALENDAR_ID_ARGUMENT = "calendarId"
    private val CALENDAR_EVENTS_START_DATE_ARGUMENT = "startDate"
    private val CALENDAR_EVENTS_END_DATE_ARGUMENT = "endDate"
    private val CALENDAR_EVENTS_IDS_ARGUMENT = "eventIds"
    private val EVENT_ID_ARGUMENT = "eventId"
    private val EVENT_TITLE_ARGUMENT = "eventTitle"
    private val EVENT_DESCRIPTION_ARGUMENT = "eventDescription"
    private val EVENT_START_DATE_ARGUMENT = "eventStartDate"
    private val EVENT_END_DATE_ARGUMENT = "eventEndDate"
    private val RECURRENCE_RULE_ARGUMENT = "recurrenceRule"
    private val RECURRENCE_FREQUENCY_ARGUMENT = "recurrenceFrequency"
    private val TOTAL_OCCURRENCES_ARGUMENT = "totalOccurrences"
    private val INTERVAL_ARGUMENT = "interval"
    private val END_DATE_ARGUMENT = "endDate"


    private constructor(registrar: Registrar, calendarDelegate: CalendarDelegate) : this() {
        _registrar = registrar
        _calendarDelegate = calendarDelegate
    }

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar): Unit {
            val context: Context = registrar.context()
            val activity: Activity? = registrar.activity()

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

                if(call.hasArgument(RECURRENCE_RULE_ARGUMENT) && call.argument<Map<String, Any>>(RECURRENCE_RULE_ARGUMENT) != null) {
                    val recurrenceRuleArgs = call.argument<Map<String, Any>>(RECURRENCE_RULE_ARGUMENT)!!
                    val recurrenceFrequencyIndex = recurrenceRuleArgs[RECURRENCE_FREQUENCY_ARGUMENT] as Int
                    val recurrenceRule = RecurrenceRule(RecurrenceFrequency.values()[recurrenceFrequencyIndex])
                    if(recurrenceRuleArgs.containsKey(TOTAL_OCCURRENCES_ARGUMENT)) {
                        recurrenceRule.totalOccurrences = recurrenceRuleArgs[TOTAL_OCCURRENCES_ARGUMENT] as Int
                    }

                    if(recurrenceRuleArgs.containsKey(INTERVAL_ARGUMENT)) {
                        recurrenceRule.interval = recurrenceRuleArgs[INTERVAL_ARGUMENT] as Int
                    }

                    if (recurrenceRuleArgs.containsKey(END_DATE_ARGUMENT)) {
                        recurrenceRule.endDate = recurrenceRuleArgs[END_DATE_ARGUMENT] as Long
                    }

                    event.recurrenceRule = recurrenceRule
                }

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
