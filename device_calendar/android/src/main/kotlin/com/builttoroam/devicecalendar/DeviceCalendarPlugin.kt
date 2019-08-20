package com.builttoroam.devicecalendar

import android.app.Activity
import android.content.Context
import com.builttoroam.devicecalendar.common.DayOfWeek
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
    private val requestPermissionsMethod = "requestPermissions"
    private val hasPermissionsMethod = "hasPermissions"
    private val retrieveCalendarsMethod = "retrieveCalendars"
    private val retrieveEventsMethod = "retrieveEvents"
    private val deleteEventMethod = "deleteEvent"
    private val createOrUpdateEventMethod = "createOrUpdateEvent"

    // Method arguments
    private val calendarIdArgument = "calendarId"
    private val calendarEventsStartDateArgument = "startDate"
    private val calendarEventsEndDateArgument = "endDate"
    private val calendarEventIdsArgument = "eventIds"
    private val eventIdArgument = "eventId"
    private val eventTitleArgument = "eventTitle"
    private val eventLocationArgument = "eventLocation"
    private val eventDescriptionArgument = "eventDescription"
    private val eventStartDateArgument = "eventStartDate"
    private val eventEndDateArgument = "eventEndDate"
    private val recurrenceRuleArgument = "recurrenceRule"
    private val recurrenceFrequencyArgument = "recurrenceFrequency"
    private val totalOccurrencesArgument = "totalOccurrences"
    private val intervalArgument = "interval"
    private val endDateArgument = "endDate"
    private val daysOfTheWeekArgument = "daysOfTheWeek"
    private val daysOfTheMonthArgument = "daysOfTheMonth"
    private val monthsOfTheYearArgument = "monthsOfTheYear"
    private val weeksOfTheYearArgument = "weeksOfTheYear"
    private val setPositionsArgument = "setPositions"

    private constructor(registrar: Registrar, calendarDelegate: CalendarDelegate) : this() {
        _registrar = registrar
        _calendarDelegate = calendarDelegate
    }

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
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
    
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            requestPermissionsMethod -> {
                _calendarDelegate.requestPermissions(result)
            }
            hasPermissionsMethod -> {
                _calendarDelegate.hasPermissions(result)
            }
            retrieveCalendarsMethod -> {
                _calendarDelegate.retrieveCalendars(result)
            }
            retrieveEventsMethod -> {
                val calendarId = call.argument<String>(calendarIdArgument)
                val startDate = call.argument<Long>(calendarEventsStartDateArgument)
                val endDate = call.argument<Long>(calendarEventsEndDateArgument)
                val eventIds = call.argument<List<String>>(calendarEventIdsArgument) ?: listOf()

                _calendarDelegate.retrieveEvents(calendarId!!, startDate, endDate, eventIds, result)
            }
            createOrUpdateEventMethod -> {
                val calendarId = call.argument<String>(calendarIdArgument)
                val event = parseEventArgs(call, calendarId)

                _calendarDelegate.createOrUpdateEvent(calendarId!!, event, result)
            }
            deleteEventMethod -> {
                val calendarId = call.argument<String>(calendarIdArgument)
                val eventId = call.argument<String>(eventIdArgument)

                _calendarDelegate.deleteEvent(calendarId!!, eventId!!, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun parseEventArgs(call: MethodCall, calendarId: String?): Event {
        val event = Event()
        event.title = call.argument<String>(eventTitleArgument)
        event.calendarId = calendarId
        event.eventId = call.argument<String>(eventIdArgument)
        event.description = call.argument<String>(eventDescriptionArgument)
        event.start = call.argument<Long>(eventStartDateArgument)!!
        event.end = call.argument<Long>(eventEndDateArgument)!!
        event.location = call.argument<String>(eventLocationArgument)

        if (call.hasArgument(recurrenceRuleArgument) && call.argument<Map<String, Any>>(recurrenceRuleArgument) != null) {
            val recurrenceRule = parseRecurrenceRuleArgs(call)
            event.recurrenceRule = recurrenceRule
        }

        return event
    }

    private fun parseRecurrenceRuleArgs(call: MethodCall): RecurrenceRule {
        val recurrenceRuleArgs = call.argument<Map<String, Any>>(recurrenceRuleArgument)!!
        val recurrenceFrequencyIndex = recurrenceRuleArgs[recurrenceFrequencyArgument] as Int
        val recurrenceRule = RecurrenceRule(RecurrenceFrequency.values()[recurrenceFrequencyIndex])
        if (recurrenceRuleArgs.containsKey(totalOccurrencesArgument)) {
            recurrenceRule.totalOccurrences = recurrenceRuleArgs[totalOccurrencesArgument] as Int
        }

        if (recurrenceRuleArgs.containsKey(intervalArgument)) {
            recurrenceRule.interval = recurrenceRuleArgs[intervalArgument] as Int
        }

        if (recurrenceRuleArgs.containsKey(endDateArgument)) {
            recurrenceRule.endDate = recurrenceRuleArgs[endDateArgument] as Long
        }

        if (recurrenceRuleArgs.containsKey(daysOfTheWeekArgument)) {
            recurrenceRule.daysOfTheWeek = recurrenceRuleArgs[daysOfTheWeekArgument].toListOf<Int>()?.map { DayOfWeek.values()[it] }?.toMutableList()
        }

        if (recurrenceRuleArgs.containsKey(daysOfTheMonthArgument)) {
            recurrenceRule.daysOfTheMonth = recurrenceRuleArgs[daysOfTheMonthArgument].toMutableListOf()
        }

        if (recurrenceRuleArgs.containsKey(monthsOfTheYearArgument)) {
            recurrenceRule.monthsOfTheYear = recurrenceRuleArgs[monthsOfTheYearArgument].toMutableListOf()
        }

        if (recurrenceRuleArgs.containsKey(weeksOfTheYearArgument)) {
            recurrenceRule.weeksOfTheYear = recurrenceRuleArgs[weeksOfTheYearArgument].toMutableListOf()
        }

        if (recurrenceRuleArgs.containsKey(setPositionsArgument)) {
            recurrenceRule.setPositions = recurrenceRuleArgs[setPositionsArgument].toMutableListOf()
        }

        return recurrenceRule
    }

    private inline fun <reified T : Any> Any?.toListOf(): List<T>? {
        return (this as List<*>?)?.filterIsInstance<T>()?.toList()
    }

    private inline fun <reified T : Any> Any?.toMutableListOf(): MutableList<T>? {
        return this?.toListOf<T>()?.toMutableList()
    }
}
