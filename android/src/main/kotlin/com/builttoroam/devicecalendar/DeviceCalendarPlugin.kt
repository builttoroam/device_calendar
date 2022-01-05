package com.builttoroam.devicecalendar

import android.app.Activity
import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import com.builttoroam.devicecalendar.common.Constants
import com.builttoroam.devicecalendar.common.ByWeekDayEntry
import com.builttoroam.devicecalendar.common.RecurrenceFrequency
import com.builttoroam.devicecalendar.models.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

const val CHANNEL_NAME = "plugins.builttoroam.com/device_calendar"

class DeviceCalendarPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var activity: Activity? = null

    // Methods
    private val REQUEST_PERMISSIONS_METHOD = "requestPermissions"
    private val HAS_PERMISSIONS_METHOD = "hasPermissions"
    private val RETRIEVE_CALENDARS_METHOD = "retrieveCalendars"
    private val RETRIEVE_EVENTS_METHOD = "retrieveEvents"
    private val DELETE_EVENT_METHOD = "deleteEvent"
    private val DELETE_EVENT_INSTANCE_METHOD = "deleteEventInstance"
    private val CREATE_OR_UPDATE_EVENT_METHOD = "createOrUpdateEvent"
    private val CREATE_CALENDAR_METHOD = "createCalendar"
    private val DELETE_CALENDAR_METHOD = "deleteCalendar"

    // Method arguments
    private val CALENDAR_ID_ARGUMENT = "calendarId"
    private val CALENDAR_NAME_ARGUMENT = "calendarName"
    private val START_DATE_ARGUMENT = "startDate"
    private val END_DATE_ARGUMENT = "endDate"
    private val EVENT_IDS_ARGUMENT = "eventIds"
    private val EVENT_ID_ARGUMENT = "eventId"
    private val EVENT_TITLE_ARGUMENT = "eventTitle"
    private val EVENT_LOCATION_ARGUMENT = "eventLocation"
    private val EVENT_URL_ARGUMENT = "eventURL"
    private val EVENT_DESCRIPTION_ARGUMENT = "eventDescription"
    private val EVENT_ALL_DAY_ARGUMENT = "eventAllDay"
    private val EVENT_START_DATE_ARGUMENT = "eventStartDate"
    private val EVENT_END_DATE_ARGUMENT = "eventEndDate"
    private val EVENT_START_TIMEZONE_ARGUMENT = "eventStartTimeZone"
    private val EVENT_END_TIMEZONE_ARGUMENT = "eventEndTimeZone"
    private val RECURRENCE_RULE_ARGUMENT = "recurrenceRule"
    private val RECURRENCE_FREQUENCY_ARGUMENT = "recurrenceFrequency"
    private val COUNT_ARGUMENT = "count"
    private val UNTIL_ARGUMENT = "until"
    private val INTERVAL_ARGUMENT = "interval"
    private val BY_WEEK_DAYS_ARGUMENT = "byWeekDays"
    private val BY_MONTH_DAYS_ARGUMENT = "byMonthDays"
    private val BY_YEAR_DAYS_ARGUMENT = "byYearDays"
    private val BY_WEEKS_ARGUMENT = "byWeeks"
    private val BY_MONTH_ARGUMENT = "byMonths"
    private val BY_SET_POSITION_ARGUMENT = "bySetPositions"
    private val ATTENDEES_ARGUMENT = "attendees"
    private val EMAIL_ADDRESS_ARGUMENT = "emailAddress"
    private val NAME_ARGUMENT = "name"
    private val ROLE_ARGUMENT = "role"
    private val REMINDERS_ARGUMENT = "reminders"
    private val MINUTES_ARGUMENT = "minutes"
    private val FOLLOWING_INSTANCES = "followingInstances"
    private val CALENDAR_COLOR_ARGUMENT = "calendarColor"
    private val LOCAL_ACCOUNT_NAME_ARGUMENT = "localAccountName"
    private val EVENT_AVAILABILITY_ARGUMENT = "availability"

    private lateinit var _calendarDelegate: CalendarDelegate

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        _calendarDelegate = CalendarDelegate(binding, context!!)
        binding.addRequestPermissionsResultListener(_calendarDelegate)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        _calendarDelegate = CalendarDelegate(binding, context!!)
        binding.addRequestPermissionsResultListener(_calendarDelegate)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
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
                val startDate = call.argument<Long>(START_DATE_ARGUMENT)
                val endDate = call.argument<Long>(END_DATE_ARGUMENT)
                val eventIds = call.argument<List<String>>(EVENT_IDS_ARGUMENT) ?: listOf()
                _calendarDelegate.retrieveEvents(calendarId!!, startDate, endDate, eventIds, result)
            }
            CREATE_OR_UPDATE_EVENT_METHOD -> {
                val calendarId = call.argument<String>(CALENDAR_ID_ARGUMENT)
                val event = parseEventArgs(call, calendarId)
                _calendarDelegate.createOrUpdateEvent(calendarId!!, event, result)
            }
            DELETE_EVENT_METHOD -> {
                val calendarId = call.argument<String>(CALENDAR_ID_ARGUMENT)
                val eventId = call.argument<String>(EVENT_ID_ARGUMENT)

                _calendarDelegate.deleteEvent(calendarId!!, eventId!!, result)
            }
            DELETE_EVENT_INSTANCE_METHOD -> {
                val calendarId = call.argument<String>(CALENDAR_ID_ARGUMENT)
                val eventId = call.argument<String>(EVENT_ID_ARGUMENT)
                val startDate = call.argument<Long>(EVENT_START_DATE_ARGUMENT)
                val endDate = call.argument<Long>(EVENT_END_DATE_ARGUMENT)
                val followingInstances = call.argument<Boolean>(FOLLOWING_INSTANCES)

                _calendarDelegate.deleteEvent(
                    calendarId!!,
                    eventId!!,
                    result,
                    startDate,
                    endDate,
                    followingInstances
                )
            }
            CREATE_CALENDAR_METHOD -> {
                val calendarName = call.argument<String>(CALENDAR_NAME_ARGUMENT)
                val calendarColor = call.argument<String>(CALENDAR_COLOR_ARGUMENT)
                val localAccountName = call.argument<String>(LOCAL_ACCOUNT_NAME_ARGUMENT)

                _calendarDelegate.createCalendar(
                    calendarName!!,
                    calendarColor,
                    localAccountName!!,
                    result
                )
            }
            DELETE_CALENDAR_METHOD -> {
                val calendarId = call.argument<String>(CALENDAR_ID_ARGUMENT)
                _calendarDelegate.deleteCalendar(calendarId!!, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun parseEventArgs(call: MethodCall, calendarId: String?): Event {
        val event = Event()
        event.eventTitle = call.argument<String>(EVENT_TITLE_ARGUMENT)
        event.calendarId = calendarId
        event.eventId = call.argument<String>(EVENT_ID_ARGUMENT)
        event.eventDescription = call.argument<String>(EVENT_DESCRIPTION_ARGUMENT)
        event.eventAllDay = call.argument<Boolean>(EVENT_ALL_DAY_ARGUMENT) ?: false
        event.eventStartDate = call.argument<Long>(EVENT_START_DATE_ARGUMENT)!!
        event.eventEndDate = call.argument<Long>(EVENT_END_DATE_ARGUMENT)!!
        event.eventStartTimeZone = call.argument<String>(EVENT_START_TIMEZONE_ARGUMENT)
        event.eventEndTimeZone = call.argument<String>(EVENT_END_TIMEZONE_ARGUMENT)
        event.eventLocation = call.argument<String>(EVENT_LOCATION_ARGUMENT)
        event.eventURL = call.argument<String>(EVENT_URL_ARGUMENT)
        event.availability = parseAvailability(call.argument<String>(EVENT_AVAILABILITY_ARGUMENT))

        if (call.hasArgument(RECURRENCE_RULE_ARGUMENT) && call.argument<Map<String, Any>>(
                RECURRENCE_RULE_ARGUMENT
            ) != null
        ) {
            val recurrenceRule = parseRecurrenceRuleArgs(call)
            Log.d("RecurrenceRule on Parse Event Args", recurrenceRule.toDebugString())
            event.recurrenceRule = recurrenceRule
        }

        if (call.hasArgument(ATTENDEES_ARGUMENT) && call.argument<List<Map<String, Any>>>(
                ATTENDEES_ARGUMENT
            ) != null
        ) {
            event.attendees = mutableListOf()
            val attendeesArgs = call.argument<List<Map<String, Any>>>(ATTENDEES_ARGUMENT)!!
            for (attendeeArgs in attendeesArgs) {
                event.attendees.add(
                    Attendee(
                        attendeeArgs[EMAIL_ADDRESS_ARGUMENT] as String,
                        attendeeArgs[NAME_ARGUMENT] as String?,
                        attendeeArgs[ROLE_ARGUMENT] as Int,
                        null, null
                    )
                )
            }
        }

        if (call.hasArgument(REMINDERS_ARGUMENT) && call.argument<List<Map<String, Any>>>(
                REMINDERS_ARGUMENT
            ) != null
        ) {
            event.reminders = mutableListOf()
            val remindersArgs = call.argument<List<Map<String, Any>>>(REMINDERS_ARGUMENT)!!
            for (reminderArgs in remindersArgs) {
                event.reminders.add(Reminder(reminderArgs[MINUTES_ARGUMENT] as Int))
            }
        }

        return event
    }

    private fun parseRecurrenceRuleArgs(call: MethodCall): RecurrenceRule {
        val recurrenceRuleArgs = call.argument<Map<String, Any>>(RECURRENCE_RULE_ARGUMENT)!!
        val recurrenceFrequencyIndex = recurrenceRuleArgs[RECURRENCE_FREQUENCY_ARGUMENT] as Int
        val recurrenceFrequency = getFrequencyByNumber(recurrenceFrequencyIndex)
        val recurrenceRule = RecurrenceRule(recurrenceFrequency)
        Log.d("ANDROID_parseRecurrenceRuleArgs:", "Arguments from Flutter: $recurrenceRuleArgs")

        if (recurrenceRuleArgs.containsKey(COUNT_ARGUMENT)) {
            recurrenceRule.count = recurrenceRuleArgs[COUNT_ARGUMENT] as Int?
        }

        if (recurrenceRuleArgs.containsKey(INTERVAL_ARGUMENT)) {
            recurrenceRule.interval = recurrenceRuleArgs[INTERVAL_ARGUMENT] as Int
        }

        if (recurrenceRuleArgs.containsKey(UNTIL_ARGUMENT)) {
            recurrenceRule.until = recurrenceRuleArgs[UNTIL_ARGUMENT] as Long?
        }

        if (recurrenceRuleArgs.containsKey(BY_WEEK_DAYS_ARGUMENT)) {

            recurrenceRule.byWeekDays =
                recurrenceRuleArgs[BY_WEEK_DAYS_ARGUMENT].toListOf<Map<String, Int>>()?.map {
                    ByWeekDayEntry(it["day"] ?: 0, it["occurrence"])
                }?.toMutableList()
        }

        if (recurrenceRuleArgs.containsKey(BY_MONTH_DAYS_ARGUMENT)) {
            recurrenceRule.byMonthDays =
                recurrenceRuleArgs[BY_MONTH_DAYS_ARGUMENT] as MutableList<Int>?
        }

        if (recurrenceRuleArgs.containsKey(BY_YEAR_DAYS_ARGUMENT)) {
            recurrenceRule.byYearDays =
                recurrenceRuleArgs[BY_YEAR_DAYS_ARGUMENT] as MutableList<Int>?
        }

        if (recurrenceRuleArgs.containsKey(BY_WEEKS_ARGUMENT)) {
            recurrenceRule.byWeeks = recurrenceRuleArgs[BY_WEEKS_ARGUMENT] as MutableList<Int>?
        }

        if (recurrenceRuleArgs.containsKey(BY_MONTH_ARGUMENT)) {
            recurrenceRule.byMonths = recurrenceRuleArgs[BY_MONTH_ARGUMENT] as MutableList<Int>?
        }

        if (recurrenceRuleArgs.containsKey(BY_SET_POSITION_ARGUMENT)) {
            recurrenceRule.bySetPositions =
                recurrenceRuleArgs[BY_SET_POSITION_ARGUMENT] as MutableList<Int>?
        }
        Log.d(
            "ANDROID_parseRecurrenceRuleArgs:",
            "Recurrence Rule result: ${recurrenceRule.toDebugString()}"
        )
        return recurrenceRule
    }

    private inline fun <reified T : Any> Any?.toListOf(): List<T>? {
        return (this as List<*>?)?.filterIsInstance<T>()?.toList()
    }

//  private inline fun <reified T : Any> Any?.toMutableListOf(): MutableList<T>? {
//    return this?.toListOf<T>()?.toMutableList()
//  }

    private fun parseAvailability(value: String?): Availability? =
        if (value == null || value == Constants.AVAILABILITY_UNAVAILABLE) {
            null
        } else {
            Availability.valueOf(value)
        }

    private fun getFrequencyByNumber(index: Int): RecurrenceFrequency {
        return when (index) {
            0 -> RecurrenceFrequency.YEARLY
            1 -> RecurrenceFrequency.MONTHLY
            2 -> RecurrenceFrequency.WEEKLY
            3 -> RecurrenceFrequency.DAILY
            4 -> RecurrenceFrequency.HOURLY
            5 -> RecurrenceFrequency.MINUTELY
            6 -> RecurrenceFrequency.SECONDLY
            else -> {
                Log.d("ANDROID", "Error getting correct Frequency by Number, fall back to YEARLY")
                RecurrenceFrequency.YEARLY
            }
        }
    }

}