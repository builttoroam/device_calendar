package com.builttoroam.devicecalendar

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.content.ContentResolver
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.provider.CalendarContract
import android.provider.CalendarContract.Events
import io.flutter.plugin.common.PluginRegistry.Registrar
import com.builttoroam.devicecalendar.common.Constants.Companion.ATTENDEE_EMAIL_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.ATTENDEE_NAME_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.ATTENDEE_PROJECTION
import com.builttoroam.devicecalendar.common.Constants.Companion.ATTENDEE_RELATIONSHIP_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.ATTENDEE_STATUS_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.ATTENDEE_TYPE_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION_ACCESS_LEVEL_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION_COLOR_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION_DISPLAY_NAME_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION_ID_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION_IS_PRIMARY_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION_OLDER_API
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_ALL_DAY_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_BEGIN_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_DESCRIPTION_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_END_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_EVENT_LOCATION_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_CUSTOM_APP_URI_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_ID_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_RECURRING_RULE_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_TITLE_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.REMINDER_MINUTES_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.REMINDER_PROJECTION
import com.builttoroam.devicecalendar.common.DayOfWeek
import com.builttoroam.devicecalendar.common.ErrorCodes.Companion.GENERIC_ERROR
import com.builttoroam.devicecalendar.common.ErrorCodes.Companion.INVALID_ARGUMENT
import com.builttoroam.devicecalendar.common.ErrorCodes.Companion.NOT_ALLOWED
import com.builttoroam.devicecalendar.common.ErrorCodes.Companion.NOT_AUTHORIZED
import com.builttoroam.devicecalendar.common.ErrorCodes.Companion.NOT_FOUND
import com.builttoroam.devicecalendar.common.ErrorMessages
import com.builttoroam.devicecalendar.common.ErrorMessages.Companion.CALENDAR_ID_INVALID_ARGUMENT_NOT_A_NUMBER_MESSAGE
import com.builttoroam.devicecalendar.common.ErrorMessages.Companion.CREATE_EVENT_ARGUMENTS_NOT_VALID_MESSAGE
import com.builttoroam.devicecalendar.common.ErrorMessages.Companion.NOT_AUTHORIZED_MESSAGE
import com.builttoroam.devicecalendar.common.RecurrenceFrequency
import com.builttoroam.devicecalendar.models.*
import com.builttoroam.devicecalendar.models.Calendar
import com.google.gson.Gson
import com.google.gson.GsonBuilder
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import org.dmfs.rfc5545.DateTime
import org.dmfs.rfc5545.Weekday
import org.dmfs.rfc5545.recur.Freq
import java.text.SimpleDateFormat
import java.util.*
import com.builttoroam.devicecalendar.models.CalendarMethodsParametersCacheModel

class CalendarDelegate : PluginRegistry.RequestPermissionsResultListener {
    private val RETRIEVE_CALENDARS_REQUEST_CODE = 0
    private val RETRIEVE_EVENTS_REQUEST_CODE = RETRIEVE_CALENDARS_REQUEST_CODE + 1
    private val RETRIEVE_CALENDAR_REQUEST_CODE = RETRIEVE_EVENTS_REQUEST_CODE + 1
    private val CREATE_OR_UPDATE_EVENT_REQUEST_CODE = RETRIEVE_CALENDAR_REQUEST_CODE + 1
    private val DELETE_EVENT_REQUEST_CODE = CREATE_OR_UPDATE_EVENT_REQUEST_CODE + 1
    private val REQUEST_PERMISSIONS_REQUEST_CODE = DELETE_EVENT_REQUEST_CODE + 1
    private val PART_TEMPLATE = ";%s="
    private val BYMONTHDAY_PART = "BYMONTHDAY"
    private val BYMONTH_PART = "BYMONTH"
    private val BYSETPOS_PART = "BYSETPOS"

    private val _cachedParametersMap: MutableMap<Int, CalendarMethodsParametersCacheModel> = mutableMapOf()
    private var _registrar: Registrar? = null
    private var _context: Context? = null
    private var _gson: Gson? = null

    constructor(activity: Registrar?, context: Context) {
        _registrar = activity
        _context = context
        val gsonBuilder = GsonBuilder()
        gsonBuilder.registerTypeAdapter(RecurrenceFrequency::class.java, RecurrenceFrequencySerializer())
        gsonBuilder.registerTypeAdapter(DayOfWeek::class.java, DayOfWeekSerializer())
        _gson = gsonBuilder.create()
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray): Boolean {
        val permissionGranted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED

        if (!_cachedParametersMap.containsKey(requestCode)) {
            // this plugin doesn't handle this request code
            return false
        }

        val cachedValues: CalendarMethodsParametersCacheModel = _cachedParametersMap[requestCode]
                ?: // unlikely scenario where another plugin is potentially using the same request code but it's not one we are tracking so return to
                // indicate we're not handling the request
                return false

        try {
            if (!permissionGranted) {
                finishWithError(NOT_AUTHORIZED, NOT_AUTHORIZED_MESSAGE, cachedValues.pendingChannelResult)
                return false
            }

            when (cachedValues.calendarDelegateMethodCode) {
                RETRIEVE_CALENDARS_REQUEST_CODE -> {
                    retrieveCalendars(cachedValues.pendingChannelResult)
                }
                RETRIEVE_EVENTS_REQUEST_CODE -> {
                    retrieveEvents(cachedValues.calendarId, cachedValues.calendarEventsStartDate, cachedValues.calendarEventsEndDate, cachedValues.calendarEventsIds, cachedValues.pendingChannelResult)
                }
                RETRIEVE_CALENDAR_REQUEST_CODE -> {
                    retrieveCalendar(cachedValues.calendarId, cachedValues.pendingChannelResult)
                }
                CREATE_OR_UPDATE_EVENT_REQUEST_CODE -> {
                    createOrUpdateEvent(cachedValues.calendarId, cachedValues.event, cachedValues.pendingChannelResult)
                }
                DELETE_EVENT_REQUEST_CODE -> {
                    deleteEvent(cachedValues.eventId, cachedValues.calendarId, cachedValues.pendingChannelResult)
                }
                REQUEST_PERMISSIONS_REQUEST_CODE -> {
                    finishWithSuccess(permissionGranted, cachedValues.pendingChannelResult)
                }
            }

            return true
        }
        finally {
            _cachedParametersMap.remove(cachedValues.calendarDelegateMethodCode)
        }
    }

    fun requestPermissions(pendingChannelResult: MethodChannel.Result) {
        if (arePermissionsGranted()) {
            finishWithSuccess(true, pendingChannelResult)
        } else {
            val parameters = CalendarMethodsParametersCacheModel(pendingChannelResult, REQUEST_PERMISSIONS_REQUEST_CODE)
            requestPermissions(parameters)
        }
    }

    fun hasPermissions(pendingChannelResult: MethodChannel.Result) {
        finishWithSuccess(arePermissionsGranted(), pendingChannelResult)
    }

    @SuppressLint("MissingPermission")
    fun retrieveCalendars(pendingChannelResult: MethodChannel.Result) {
        if (arePermissionsGranted()) {
            val contentResolver: ContentResolver? = _context?.contentResolver
            val uri: Uri = CalendarContract.Calendars.CONTENT_URI
             val cursor: Cursor? = if (atLeastAPI(17)) {
                contentResolver?.query(uri, CALENDAR_PROJECTION, null, null, null)
            } else {
                contentResolver?.query(uri, CALENDAR_PROJECTION_OLDER_API, null, null, null)
            }
            val calendars: MutableList<Calendar> = mutableListOf()
            try {
                while (cursor?.moveToNext() == true) {
                    val calendar = parseCalendarRow(cursor) ?: continue
                    calendars.add(calendar)
                }

                finishWithSuccess(_gson?.toJson(calendars), pendingChannelResult)
            } catch (e: Exception) {
                finishWithError(GENERIC_ERROR, e.message, pendingChannelResult)
            } finally {
                cursor?.close()
            }
        } else {
            val parameters = CalendarMethodsParametersCacheModel(pendingChannelResult, RETRIEVE_CALENDARS_REQUEST_CODE)
            requestPermissions(parameters)
        }
    }

    private fun retrieveCalendar(calendarId: String, pendingChannelResult: MethodChannel.Result, isInternalCall: Boolean = false): Calendar? {
        if (isInternalCall || arePermissionsGranted()) {
            val calendarIdNumber = calendarId.toLongOrNull()
            if (calendarIdNumber == null) {
                if (!isInternalCall) {
                    finishWithError(INVALID_ARGUMENT, CALENDAR_ID_INVALID_ARGUMENT_NOT_A_NUMBER_MESSAGE, pendingChannelResult)
                }
                return null
            }

            val contentResolver: ContentResolver? = _context?.contentResolver
            val uri: Uri = CalendarContract.Calendars.CONTENT_URI
            
            val cursor: Cursor? = if (atLeastAPI(17)) {
                contentResolver?.query(ContentUris.withAppendedId(uri, calendarIdNumber), CALENDAR_PROJECTION, null, null, null)
            } else {
                contentResolver?.query(ContentUris.withAppendedId(uri, calendarIdNumber), CALENDAR_PROJECTION_OLDER_API, null, null, null)
            }

            try {
                if (cursor?.moveToFirst() == true) {
                    val calendar = parseCalendarRow(cursor)
                    if (isInternalCall) {
                        return calendar
                    } else {
                        finishWithSuccess(_gson?.toJson(calendar), pendingChannelResult)
                    }
                } else {
                    if (!isInternalCall) {
                        finishWithError(NOT_FOUND, "The calendar with the ID $calendarId could not be found", pendingChannelResult)
                    }
                }
            } catch (e: Exception) {
                finishWithError(GENERIC_ERROR, e.message, pendingChannelResult)
            } finally {
                cursor?.close()
            }
        } else {
            val parameters = CalendarMethodsParametersCacheModel(pendingChannelResult, RETRIEVE_CALENDAR_REQUEST_CODE, calendarId)
            requestPermissions(parameters)
        }

        return null
    }

    @SuppressLint("MissingPermission")
    fun retrieveEvents(calendarId: String, startDate: Long?, endDate: Long?, eventIds: List<String>, pendingChannelResult: MethodChannel.Result) {
        if (startDate == null && endDate == null && eventIds.isEmpty()) {
            finishWithError(INVALID_ARGUMENT, ErrorMessages.RETRIEVE_EVENTS_ARGUMENTS_NOT_VALID_MESSAGE, pendingChannelResult)
            return
        }

        if (arePermissionsGranted()) {
            val calendar = retrieveCalendar(calendarId, pendingChannelResult, true)
            if (calendar == null) {
                finishWithError(NOT_FOUND, "Couldn't retrieve the Calendar with ID $calendarId", pendingChannelResult)
                return
            }

            val contentResolver: ContentResolver? = _context?.contentResolver
            val eventsUriBuilder = CalendarContract.Instances.CONTENT_URI.buildUpon()
            ContentUris.appendId(eventsUriBuilder, startDate ?: Date(0).time)
            ContentUris.appendId(eventsUriBuilder, endDate ?: Date(Long.MAX_VALUE).time)

            val eventsUri = eventsUriBuilder.build()
            val eventsCalendarQuery = "(${Events.CALENDAR_ID} = $calendarId)"
            val eventsNotDeletedQuery = "(${Events.DELETED} != 1)"
            val eventsIdsQueryElements = eventIds.map { "(${CalendarContract.Instances.EVENT_ID} = $it)" }
            val eventsIdsQuery = eventsIdsQueryElements.joinToString(" OR ")

            var eventsSelectionQuery = "$eventsCalendarQuery AND $eventsNotDeletedQuery"
            if (eventsIdsQuery.isNotEmpty()) {
                eventsSelectionQuery += " AND ($eventsIdsQuery)"
            }
            val eventsSortOrder = Events.DTSTART + " ASC"
            val eventsCursor = contentResolver?.query(eventsUri, EVENT_PROJECTION, eventsSelectionQuery, null, eventsSortOrder)

            val events: MutableList<Event> = mutableListOf()

            try {
                if (eventsCursor?.moveToFirst() == true) {
                    do {
                        val event = parseEvent(calendarId, eventsCursor) ?: continue
                        events.add(event)

                    } while (eventsCursor.moveToNext())

                    for (event in events) {
                        val attendees = retrieveAttendees(event.eventId!!, contentResolver)
                        event.organizer = attendees.firstOrNull { it.isOrganizer != null && it.isOrganizer }
                        event.attendees = attendees
                        event.reminders = retrieveReminders(event.eventId!!, contentResolver)
                    }
                }
            } catch (e: Exception) {
                finishWithError(GENERIC_ERROR, e.message, pendingChannelResult)
            } finally {
                eventsCursor?.close()
            }

            finishWithSuccess(_gson?.toJson(events), pendingChannelResult)
        } else {
            val parameters = CalendarMethodsParametersCacheModel(pendingChannelResult, RETRIEVE_EVENTS_REQUEST_CODE, calendarId, startDate, endDate)
            requestPermissions(parameters)
        }

        return
    }

    @SuppressLint("MissingPermission")
    fun createOrUpdateEvent(calendarId: String, event: Event?, pendingChannelResult: MethodChannel.Result) {
        if (arePermissionsGranted()) {
            if (event == null) {
                finishWithError(GENERIC_ERROR, CREATE_EVENT_ARGUMENTS_NOT_VALID_MESSAGE, pendingChannelResult)
                return
            }

            val calendar = retrieveCalendar(calendarId, pendingChannelResult, true)
            if (calendar == null) {
                finishWithError(NOT_FOUND, "Couldn't retrieve the Calendar with ID $calendarId", pendingChannelResult)
                return
            }

            val contentResolver: ContentResolver? = _context?.contentResolver
            val values = buildEventContentValues(event, calendarId)
            try {
                var eventId: Long? = event.eventId?.toLongOrNull()
                if (eventId == null) {
                    val uri = contentResolver?.insert(Events.CONTENT_URI, values)
                    // get the event ID that is the last element in the Uri
                    eventId = java.lang.Long.parseLong(uri?.lastPathSegment!!)
                    insertAttendees(event.attendees, eventId, contentResolver)
                    insertReminders(event.reminders, eventId, contentResolver)
                } else {
                    contentResolver?.update(ContentUris.withAppendedId(Events.CONTENT_URI, eventId), values, null, null)
                    val existingAttendees = retrieveAttendees(eventId.toString(), contentResolver)
                    val attendeesToDelete = if (event.attendees.isNotEmpty()) existingAttendees.filter { existingAttendee -> event.attendees.all { it.emailAddress != existingAttendee.emailAddress } } else existingAttendees
                    for (attendeeToDelete in attendeesToDelete) {
                        deleteAttendee(eventId, attendeeToDelete, contentResolver)
                    }

                    val attendeesToInsert = event.attendees.filter { existingAttendees.all { existingAttendee -> existingAttendee.emailAddress != it.emailAddress } }
                    insertAttendees(attendeesToInsert, eventId, contentResolver)
                    deleteExistingReminders(contentResolver, eventId)
                    insertReminders(event.reminders, eventId, contentResolver!!)
                }

                finishWithSuccess(eventId.toString(), pendingChannelResult)
            } catch (e: Exception) {
                finishWithError(GENERIC_ERROR, e.message, pendingChannelResult)
            }
        } else {
            val parameters = CalendarMethodsParametersCacheModel(pendingChannelResult, CREATE_OR_UPDATE_EVENT_REQUEST_CODE, calendarId)
            parameters.event = event
            requestPermissions(parameters)
        }
    }

    private fun deleteExistingReminders(contentResolver: ContentResolver?, eventId: Long) {
        val cursor = CalendarContract.Reminders.query(contentResolver, eventId, arrayOf(
                CalendarContract.Reminders._ID
        ))
        while (cursor != null && cursor.moveToNext()) {
            var reminderUri: Uri? = null
            val reminderId = cursor.getLong(0)
            if (reminderId > 0) {
                reminderUri = ContentUris.withAppendedId(CalendarContract.Reminders.CONTENT_URI, reminderId)
            }
            if (reminderUri != null) {
                contentResolver?.delete(reminderUri, null, null)
            }
        }
        cursor?.close()
    }

    @SuppressLint("MissingPermission")
    private fun insertReminders(reminders: List<Reminder>, eventId: Long?, contentResolver: ContentResolver) {
        if (reminders.isEmpty()) {
            return
        }
        val remindersContentValues = reminders.map {
            ContentValues().apply {
                put(CalendarContract.Reminders.EVENT_ID, eventId)
                put(CalendarContract.Reminders.MINUTES, it.minutes)
                put(CalendarContract.Reminders.METHOD, CalendarContract.Reminders.METHOD_ALERT)
            }
        }.toTypedArray()
        contentResolver.bulkInsert(CalendarContract.Reminders.CONTENT_URI, remindersContentValues)
    }

    private fun buildEventContentValues(event: Event, calendarId: String): ContentValues {
        val values = ContentValues()
        val duration: String? = null
        values.put(Events.ALL_DAY, event.allDay)
        values.put(Events.DTSTART, event.start!!)
        if (event.allDay) {
            values.put(Events.DTEND, event.start!!)
        }
        else {
            values.put(Events.DTEND, event.end!!)
        }
        values.put(Events.TITLE, event.title)
        values.put(Events.DESCRIPTION, event.description)
        values.put(Events.EVENT_LOCATION, event.location)
        values.put(Events.CUSTOM_APP_URI, event.url)
        values.put(Events.CALENDAR_ID, calendarId)
        values.put(Events.DURATION, duration)

        // MK using current device time zone
        val currentTimeZone: TimeZone = java.util.Calendar.getInstance().timeZone
        values.put(Events.EVENT_TIMEZONE, currentTimeZone.displayName)
        if (event.recurrenceRule != null) {
            val recurrenceRuleParams = buildRecurrenceRuleParams(event.recurrenceRule!!)
            values.put(Events.RRULE, recurrenceRuleParams)
        }
        return values
    }

    @SuppressLint("MissingPermission")
    private fun insertAttendees(attendees: List<Attendee>, eventId: Long?, contentResolver: ContentResolver?) {
        if (attendees.isEmpty()) {
            return
        }

        val attendeesValues = attendees.map {
            ContentValues().apply {
                put(CalendarContract.Attendees.ATTENDEE_NAME, it.name)
                put(CalendarContract.Attendees.ATTENDEE_EMAIL, it.emailAddress)
                put(
                        CalendarContract.Attendees.ATTENDEE_RELATIONSHIP,
                        CalendarContract.Attendees.RELATIONSHIP_ATTENDEE
                )
                put(CalendarContract.Attendees.ATTENDEE_TYPE, it.role)
                put(
                        CalendarContract.Attendees.ATTENDEE_STATUS,
                        CalendarContract.Attendees.ATTENDEE_STATUS_INVITED
                )
                put(CalendarContract.Attendees.EVENT_ID, eventId)
            }
        }.toTypedArray()

        contentResolver?.bulkInsert(CalendarContract.Attendees.CONTENT_URI, attendeesValues)
    }

    @SuppressLint("MissingPermission")
    private fun deleteAttendee(eventId: Long, attendee: Attendee, contentResolver: ContentResolver?) {
        val selection = "(" + CalendarContract.Attendees.EVENT_ID + " = ?) AND (" + CalendarContract.Attendees.ATTENDEE_EMAIL + " = ?)"
        val selectionArgs = arrayOf(eventId.toString() + "", attendee.emailAddress)
        contentResolver?.delete(CalendarContract.Attendees.CONTENT_URI, selection, selectionArgs)

    }

    fun deleteEvent(calendarId: String, eventId: String, pendingChannelResult: MethodChannel.Result) {
        if (arePermissionsGranted()) {
            val existingCal = retrieveCalendar(calendarId, pendingChannelResult, true)
            if (existingCal == null) {
                finishWithError(NOT_FOUND, "The calendar with the ID $calendarId could not be found", pendingChannelResult)
                return
            }

            if (existingCal.isReadOnly) {
                finishWithError(NOT_ALLOWED, "Calendar with ID $calendarId is read-only", pendingChannelResult)
                return
            }

            val eventIdNumber = eventId.toLongOrNull()
            if (eventIdNumber == null) {
                finishWithError(INVALID_ARGUMENT, CALENDAR_ID_INVALID_ARGUMENT_NOT_A_NUMBER_MESSAGE, pendingChannelResult)
                return
            }

            val contentResolver: ContentResolver? = _context?.contentResolver
            val eventsUriWithId = ContentUris.withAppendedId(Events.CONTENT_URI, eventIdNumber)
            val deleteSucceeded = contentResolver?.delete(eventsUriWithId, null, null) ?: 0
            finishWithSuccess(deleteSucceeded > 0, pendingChannelResult)
        } else {
            val parameters = CalendarMethodsParametersCacheModel(pendingChannelResult, DELETE_EVENT_REQUEST_CODE, calendarId)
            parameters.eventId = eventId
            requestPermissions(parameters)
        }
    }

    private fun arePermissionsGranted(): Boolean {
        if (atLeastAPI(23)) {
            val writeCalendarPermissionGranted = _registrar!!.activity().checkSelfPermission(Manifest.permission.WRITE_CALENDAR) == PackageManager.PERMISSION_GRANTED
            val readCalendarPermissionGranted = _registrar!!.activity().checkSelfPermission(Manifest.permission.READ_CALENDAR) == PackageManager.PERMISSION_GRANTED
            return writeCalendarPermissionGranted && readCalendarPermissionGranted
        }

        return true
    }

    private fun requestPermissions(parameters: CalendarMethodsParametersCacheModel) {
        val requestCode: Int = generateUniqueRequestCodeAndCacheParameters(parameters)
        requestPermissions(requestCode)
    }

    private fun requestPermissions(requestCode: Int) {
        if (atLeastAPI(23)) {
            _registrar!!.activity().requestPermissions(arrayOf(Manifest.permission.WRITE_CALENDAR, Manifest.permission.READ_CALENDAR), requestCode)
        }
    }

    private fun parseCalendarRow(cursor: Cursor?): Calendar? {
        if (cursor == null) {
            return null
        }

        val calId = cursor.getLong(CALENDAR_PROJECTION_ID_INDEX)
        val displayName = cursor.getString(CALENDAR_PROJECTION_DISPLAY_NAME_INDEX)
        val accessLevel = cursor.getInt(CALENDAR_PROJECTION_ACCESS_LEVEL_INDEX)
        val calendarColor = cursor.getInt(CALENDAR_PROJECTION_COLOR_INDEX)


        val calendar = Calendar(calId.toString(), displayName, calendarColor)
        calendar.isReadOnly = isCalendarReadOnly(accessLevel)
        if (atLeastAPI(17)) {
            val isPrimary = cursor.getString(CALENDAR_PROJECTION_IS_PRIMARY_INDEX)
            calendar.isDefault = isPrimary == "1"
        }
        else {
            calendar.isDefault = false
        }
        return calendar
    }

    private fun parseEvent(calendarId: String, cursor: Cursor?): Event? {
        if (cursor == null) {
            return null
        }

        val eventId = cursor.getLong(EVENT_PROJECTION_ID_INDEX)
        val title = cursor.getString(EVENT_PROJECTION_TITLE_INDEX)
        val description = cursor.getString(EVENT_PROJECTION_DESCRIPTION_INDEX)
        val begin = cursor.getLong(EVENT_PROJECTION_BEGIN_INDEX)
        val end = cursor.getLong(EVENT_PROJECTION_END_INDEX)
        val recurringRule = cursor.getString(EVENT_PROJECTION_RECURRING_RULE_INDEX)
        val allDay = cursor.getInt(EVENT_PROJECTION_ALL_DAY_INDEX) > 0
        val location = cursor.getString(EVENT_PROJECTION_EVENT_LOCATION_INDEX)
        var url = cursor.getString(EVENT_PROJECTION_CUSTOM_APP_URI_INDEX)

        val event = Event()
        event.title = title ?: "New Event"
        event.eventId = eventId.toString()
        event.calendarId = calendarId
        event.description = description
        event.start = begin
        event.end = end
        event.allDay = allDay
        event.location = location
        event.url = url
        event.recurrenceRule = parseRecurrenceRuleString(recurringRule)
        return event
    }

    private fun parseRecurrenceRuleString(recurrenceRuleString: String?): RecurrenceRule? {
        if (recurrenceRuleString == null) {
            return null
        }

        val rfcRecurrenceRule = org.dmfs.rfc5545.recur.RecurrenceRule(recurrenceRuleString)
        val frequency = when (rfcRecurrenceRule.freq) {
            Freq.YEARLY -> RecurrenceFrequency.YEARLY
            Freq.MONTHLY -> RecurrenceFrequency.MONTHLY
            Freq.WEEKLY -> RecurrenceFrequency.WEEKLY
            Freq.DAILY -> RecurrenceFrequency.DAILY
            else -> null
        }

        val recurrenceRule = RecurrenceRule(frequency!!)
        if (rfcRecurrenceRule.count != null) {
            recurrenceRule.totalOccurrences = rfcRecurrenceRule.count
        }

        recurrenceRule.interval = rfcRecurrenceRule.interval
        if (rfcRecurrenceRule.until != null) {
            recurrenceRule.endDate = rfcRecurrenceRule.until.timestamp
        }

        when (rfcRecurrenceRule.freq) {
            Freq.WEEKLY, Freq.MONTHLY, Freq.YEARLY -> {
                recurrenceRule.daysOfWeek = rfcRecurrenceRule.byDayPart?.mapNotNull {
                    DayOfWeek.values().find { dayOfWeek -> dayOfWeek.ordinal == it.weekday.ordinal }
                }?.toMutableList()
            }
        }

        val rfcRecurrenceRuleString = rfcRecurrenceRule.toString()
        if (rfcRecurrenceRule.freq == Freq.MONTHLY || rfcRecurrenceRule.freq == Freq.YEARLY) {
            // Get week number value from BYSETPOS
            recurrenceRule.weekOfMonth = convertCalendarPartToNumericValues(rfcRecurrenceRuleString, BYSETPOS_PART)

            // If value is not found in BYSETPOS and not repeating by nth day or nth month
            // Get the week number value from the BYDAY position
            if (recurrenceRule.weekOfMonth == null && rfcRecurrenceRule.byDayPart != null) {
                recurrenceRule.weekOfMonth = rfcRecurrenceRule.byDayPart.first().pos
            }

            recurrenceRule.dayOfMonth = convertCalendarPartToNumericValues(rfcRecurrenceRuleString, BYMONTHDAY_PART)

            if (rfcRecurrenceRule.freq == Freq.YEARLY) {
                recurrenceRule.monthOfYear = convertCalendarPartToNumericValues(rfcRecurrenceRuleString, BYMONTH_PART)
            }
        }

        return recurrenceRule
    }

    private fun convertCalendarPartToNumericValues(rfcRecurrenceRuleString: String, partName: String): Int? {
        val partIndex = rfcRecurrenceRuleString.indexOf(partName)
        if (partIndex == -1) {
            return null
        }

        return rfcRecurrenceRuleString.substring(partIndex).split(";").firstOrNull()?.split("=")?.lastOrNull()?.split(",")?.map {
            it.toInt()
        }?.firstOrNull()
    }

    private fun parseAttendeeRow(cursor: Cursor?): Attendee? {
        if (cursor == null) {
            return null
        }

        return Attendee(
                cursor.getString(ATTENDEE_EMAIL_INDEX),
                cursor.getString(ATTENDEE_NAME_INDEX),
                cursor.getInt(ATTENDEE_TYPE_INDEX),
                cursor.getInt(ATTENDEE_STATUS_INDEX),
                cursor.getInt(ATTENDEE_RELATIONSHIP_INDEX) == CalendarContract.Attendees.RELATIONSHIP_ORGANIZER)
    }

    private fun parseReminderRow(cursor: Cursor?): Reminder? {
        if (cursor == null) {
            return null
        }

        return Reminder(cursor.getInt(REMINDER_MINUTES_INDEX))
    }

    private fun isCalendarReadOnly(accessLevel: Int): Boolean {
        return when (accessLevel) {
            Events.CAL_ACCESS_CONTRIBUTOR,
            Events.CAL_ACCESS_ROOT,
            Events.CAL_ACCESS_OWNER,
            Events.CAL_ACCESS_EDITOR
            -> false
            else -> true
        }
    }

    @SuppressLint("MissingPermission")
    private fun retrieveAttendees(eventId: String, contentResolver: ContentResolver?): MutableList<Attendee> {
        val attendees: MutableList<Attendee> = mutableListOf()
        val attendeesQuery = "(${CalendarContract.Attendees.EVENT_ID} = ${eventId})"
        val attendeesCursor = contentResolver?.query(CalendarContract.Attendees.CONTENT_URI, ATTENDEE_PROJECTION, attendeesQuery, null, null)
        attendeesCursor.use { cursor ->
            if (cursor?.moveToFirst() == true) {
                do {
                    val attendee = parseAttendeeRow(attendeesCursor) ?: continue
                    attendees.add(attendee)
                } while (cursor.moveToNext())
            }
        }

        return attendees
    }

    @SuppressLint("MissingPermission")
    private fun retrieveReminders(eventId: String, contentResolver: ContentResolver?) : MutableList<Reminder> {
        val reminders: MutableList<Reminder> = mutableListOf()
        val remindersQuery = "(${CalendarContract.Reminders.EVENT_ID} = ${eventId})"
        val remindersCursor = contentResolver?.query(CalendarContract.Reminders.CONTENT_URI, REMINDER_PROJECTION, remindersQuery, null, null)
        remindersCursor.use { cursor ->
            if (cursor?.moveToFirst() == true) {
                do {
                    val reminder = parseReminderRow(remindersCursor) ?: continue
                    reminders.add(reminder)
                } while (cursor.moveToNext())
            }
        }

        return reminders
    }

    @Synchronized
    private fun generateUniqueRequestCodeAndCacheParameters(parameters: CalendarMethodsParametersCacheModel): Int {
        // TODO we can ran out of Int's at some point so this probably should re-use some of the freed ones
        val uniqueRequestCode: Int = (_cachedParametersMap.keys.max() ?: 0) + 1
        parameters.ownCacheKey = uniqueRequestCode
        _cachedParametersMap[uniqueRequestCode] = parameters

        return uniqueRequestCode
    }

    private fun <T> finishWithSuccess(result: T, pendingChannelResult: MethodChannel.Result) {
        pendingChannelResult.success(result)
        clearCachedParameters(pendingChannelResult)
    }

    private fun finishWithError(errorCode: String, errorMessage: String?, pendingChannelResult: MethodChannel.Result) {
        pendingChannelResult.error(errorCode, errorMessage, null)
        clearCachedParameters(pendingChannelResult)
    }

    private fun clearCachedParameters(pendingChannelResult: MethodChannel.Result) {
        val cachedParameters = _cachedParametersMap.values.filter { it.pendingChannelResult == pendingChannelResult }.toList()
        for (cachedParameter in cachedParameters) {
            if (_cachedParametersMap.containsKey(cachedParameter.ownCacheKey)) {
                _cachedParametersMap.remove(cachedParameter.ownCacheKey)
            }
        }
    }

    private fun atLeastAPI(api: Int): Boolean {
        return api <= android.os.Build.VERSION.SDK_INT
    }

    private fun buildRecurrenceRuleParams(recurrenceRule: RecurrenceRule): String {
        val frequencyParam = when (recurrenceRule.recurrenceFrequency) {
            RecurrenceFrequency.DAILY -> Freq.DAILY
            RecurrenceFrequency.WEEKLY -> Freq.WEEKLY
            RecurrenceFrequency.MONTHLY -> Freq.MONTHLY
            RecurrenceFrequency.YEARLY -> Freq.YEARLY
        }
        val rr = org.dmfs.rfc5545.recur.RecurrenceRule(frequencyParam)
        if (recurrenceRule.interval != null) {
            rr.interval = recurrenceRule.interval!!
        }

        if (recurrenceRule.recurrenceFrequency == RecurrenceFrequency.WEEKLY ||
            recurrenceRule.weekOfMonth != null && (recurrenceRule.recurrenceFrequency == RecurrenceFrequency.MONTHLY || recurrenceRule.recurrenceFrequency == RecurrenceFrequency.YEARLY)) {
            rr.byDayPart = buildByDayPart(recurrenceRule)
        }

        if (recurrenceRule.totalOccurrences != null) {
            rr.count = recurrenceRule.totalOccurrences!!
        } else if (recurrenceRule.endDate != null) {
            val calendar = java.util.Calendar.getInstance()
            calendar.timeInMillis = recurrenceRule.endDate!!
            val dateFormat = SimpleDateFormat("yyyyMMdd")
            dateFormat.timeZone = calendar.timeZone
            rr.until = DateTime(calendar.timeZone, recurrenceRule.endDate!!)
        }

        var rrString = rr.toString()

        if (recurrenceRule.monthOfYear != null && recurrenceRule.recurrenceFrequency == RecurrenceFrequency.YEARLY) {
            rrString = rrString.addPartWithValues(BYMONTH_PART, recurrenceRule.monthOfYear)
        }

        if (recurrenceRule.recurrenceFrequency == RecurrenceFrequency.MONTHLY || recurrenceRule.recurrenceFrequency == RecurrenceFrequency.YEARLY) {
            if (recurrenceRule.weekOfMonth == null) {
                rrString = rrString.addPartWithValues(BYMONTHDAY_PART, recurrenceRule.dayOfMonth)
            }
        }

        return rrString
    }

    private fun buildByDayPart(recurrenceRule: RecurrenceRule): List<org.dmfs.rfc5545.recur.RecurrenceRule.WeekdayNum>? {
        if (recurrenceRule.daysOfWeek?.isEmpty() == true) {
            return null
        }

        return recurrenceRule.daysOfWeek?.mapNotNull { dayOfWeek ->
            Weekday.values().firstOrNull {
                it.ordinal == dayOfWeek.ordinal
            }
        }?.map {
            org.dmfs.rfc5545.recur.RecurrenceRule.WeekdayNum(recurrenceRule.weekOfMonth?: 0, it)
        }
    }

    private fun String.addPartWithValues(partName: String, values: Int?): String {
        if (values != null) {
            return this + PART_TEMPLATE.format(partName) + values
        }

        return this
    }
}