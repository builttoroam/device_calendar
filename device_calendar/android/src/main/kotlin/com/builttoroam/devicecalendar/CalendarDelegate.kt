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
import com.builttoroam.devicecalendar.common.Constants.Companion.ATTENDEE_EMAIL_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.ATTENDEE_EVENT_ID_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.ATTENDEE_ID_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.ATTENDEE_NAME_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.ATTENDEE_PROJECTION
import com.builttoroam.devicecalendar.common.Constants.Companion.ATTENDEE_TYPE_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION_ACCESS_LEVEL_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION_DISPLAY_NAME_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION_ID_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_ALL_DAY_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_BEGIN_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_DESCRIPTION_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_END_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_EVENT_LOCATION_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_ID_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_RECURRING_RULE_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_TITLE_INDEX
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


class CalendarDelegate : PluginRegistry.RequestPermissionsResultListener {

    private val RETRIEVE_CALENDARS_METHOD_CODE = 0
    private val RETRIEVE_EVENTS_METHOD_CODE = RETRIEVE_CALENDARS_METHOD_CODE + 1
    private val RETRIEVE_CALENDAR_METHOD_CODE = RETRIEVE_EVENTS_METHOD_CODE + 1
    private val CREATE_OR_UPDATE_EVENT_METHOD_CODE = RETRIEVE_CALENDAR_METHOD_CODE + 1
    private val DELETE_EVENT_METHOD_CODE = CREATE_OR_UPDATE_EVENT_METHOD_CODE + 1
    private val REQUEST_PERMISSIONS_METHOD_CODE = DELETE_EVENT_METHOD_CODE + 1
    private val PART_TEMPLATE = ";%s="
    private val BYMONTHDAY_PART = "BYMONTHDAY"
    private val BYMONTH_PART = "BYMONTH"
    private val BYWEEKNO_PART = "BYWEEKNO"
    private val BYSETPOS_PART = "BYSETPOS"

    private val _cachedParametersMap: MutableMap<Int, CalendarMethodsParametersCacheModel> = mutableMapOf()

    private var _activity: Activity? = null
    private var _context: Context? = null
    private var _gson: Gson? = null

    constructor(activity: Activity?, context: Context) {
        _activity = activity
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

        val cachedValues: CalendarMethodsParametersCacheModel? = _cachedParametersMap[requestCode]
        if (cachedValues == null) {
            // unlikely scenario where another plugin is potentially using the same request code but it's not one we are tracking so return to
            // indicate we're not handling the request
            return false
        }

        when (cachedValues.calendarDelegateMethodCode) {
            RETRIEVE_CALENDARS_METHOD_CODE -> {
                return handleRetrieveCalendarsRequest(permissionGranted, cachedValues, requestCode)
            }
            RETRIEVE_EVENTS_METHOD_CODE -> {
                return handleRetrieveEventsRequest(permissionGranted, cachedValues, requestCode)
            }
            RETRIEVE_CALENDAR_METHOD_CODE -> {
                return handleRetrieveCalendarRequest(permissionGranted, cachedValues, requestCode)
            }
            CREATE_OR_UPDATE_EVENT_METHOD_CODE -> {
                return handleCreateOrUpdateEventRequest(permissionGranted, cachedValues, requestCode)
            }
            DELETE_EVENT_METHOD_CODE -> {
                return handleDeleteEventRequest(permissionGranted, cachedValues, requestCode)
            }
            REQUEST_PERMISSIONS_METHOD_CODE -> {
                return handlePermissionsRequest(permissionGranted, cachedValues)
            }
        }

        return false
    }

    private fun handlePermissionsRequest(permissionGranted: Boolean, cachedValues: CalendarMethodsParametersCacheModel): Boolean {
        finishWithSuccess(permissionGranted, cachedValues.pendingChannelResult)
        return true
    }

    private fun handleDeleteEventRequest(permissionGranted: Boolean, cachedValues: CalendarMethodsParametersCacheModel, requestCode: Int): Boolean {
        if (permissionGranted) {
            deleteEvent(cachedValues.eventId, cachedValues.calendarId, cachedValues.pendingChannelResult)
        } else {
            finishWithError(NOT_AUTHORIZED, NOT_AUTHORIZED_MESSAGE, cachedValues.pendingChannelResult)
        }

        _cachedParametersMap.remove(requestCode)

        return true
    }

    private fun handleCreateOrUpdateEventRequest(permissionGranted: Boolean, cachedValues: CalendarMethodsParametersCacheModel, requestCode: Int): Boolean {
        if (permissionGranted) {
            createOrUpdateEvent(cachedValues.calendarId, cachedValues.event, cachedValues.pendingChannelResult)
        } else {
            finishWithError(NOT_AUTHORIZED, NOT_AUTHORIZED_MESSAGE, cachedValues.pendingChannelResult)
        }

        _cachedParametersMap.remove(requestCode)

        return true
    }

    private fun handleRetrieveCalendarRequest(permissionGranted: Boolean, cachedValues: CalendarMethodsParametersCacheModel, requestCode: Int): Boolean {
        if (permissionGranted) {
            retrieveCalendar(cachedValues.calendarId, cachedValues.pendingChannelResult)
        } else {
            finishWithError(NOT_AUTHORIZED, NOT_AUTHORIZED_MESSAGE, cachedValues.pendingChannelResult)
        }

        _cachedParametersMap.remove(requestCode)

        return true
    }

    private fun handleRetrieveEventsRequest(permissionGranted: Boolean, cachedValues: CalendarMethodsParametersCacheModel, requestCode: Int): Boolean {
        if (permissionGranted) {
            retrieveEvents(cachedValues.calendarId, cachedValues.calendarEventsStartDate, cachedValues.calendarEventsEndDate, cachedValues.calendarEventsIds, cachedValues.pendingChannelResult)
        } else {
            finishWithError(NOT_AUTHORIZED, NOT_AUTHORIZED_MESSAGE, cachedValues.pendingChannelResult)
        }

        _cachedParametersMap.remove(requestCode)

        return true
    }

    private fun handleRetrieveCalendarsRequest(permissionGranted: Boolean, cachedValues: CalendarMethodsParametersCacheModel, requestCode: Int): Boolean {
        if (permissionGranted) {
            retrieveCalendars(cachedValues.pendingChannelResult)
        } else {
            finishWithError(NOT_AUTHORIZED, NOT_AUTHORIZED_MESSAGE, cachedValues.pendingChannelResult)
        }

        _cachedParametersMap.remove(requestCode)

        return true
    }

    fun requestPermissions(pendingChannelResult: MethodChannel.Result) {
        if (arePermissionsGranted()) {
            finishWithSuccess(true, pendingChannelResult)
        } else {
            val parameters = CalendarMethodsParametersCacheModel(pendingChannelResult, REQUEST_PERMISSIONS_METHOD_CODE)
            requestPermissions(parameters)
        }
    }

    fun hasPermissions(pendingChannelResult: MethodChannel.Result) {
        finishWithSuccess(arePermissionsGranted(), pendingChannelResult)
    }

    @SuppressLint("MissingPermission")
    fun retrieveCalendars(pendingChannelResult: MethodChannel.Result) {
        if (arePermissionsGranted()) {
            val contentResolver: ContentResolver? = _context?.getContentResolver()
            val uri: Uri = CalendarContract.Calendars.CONTENT_URI
            val cursor: Cursor? = contentResolver?.query(uri, CALENDAR_PROJECTION, null, null, null)

            val calendars: MutableList<Calendar> = mutableListOf()

            try {
                while (cursor?.moveToNext() ?: false) {

                    val calendar = parseCalendar(cursor)
                    if (calendar == null) {
                        continue
                    }
                    calendars.add(calendar)
                }

                finishWithSuccess(_gson?.toJson(calendars), pendingChannelResult)
            } catch (e: Exception) {
                finishWithError(GENERIC_ERROR, e.message, pendingChannelResult)
                println(e.message)
            } finally {
                cursor?.close()
            }
        } else {
            val parameters = CalendarMethodsParametersCacheModel(pendingChannelResult, RETRIEVE_CALENDARS_METHOD_CODE)
            requestPermissions(parameters)
        }
    }

    fun retrieveCalendar(calendarId: String, pendingChannelResult: MethodChannel.Result, isInternalCall: Boolean = false): Calendar? {
        if (isInternalCall || arePermissionsGranted()) {
            val calendarIdNumber = calendarId.toLongOrNull()
            if (calendarIdNumber == null) {
                if (!isInternalCall) {
                    finishWithError(INVALID_ARGUMENT, CALENDAR_ID_INVALID_ARGUMENT_NOT_A_NUMBER_MESSAGE, pendingChannelResult)
                }
                return null
            }

            val contentResolver: ContentResolver? = _context?.getContentResolver()
            val uri: Uri = CalendarContract.Calendars.CONTENT_URI
            val cursor: Cursor? = contentResolver?.query(ContentUris.withAppendedId(uri, calendarIdNumber), CALENDAR_PROJECTION, null, null, null)

            try {
                if (cursor?.moveToFirst() ?: false) {
                    val calendar = parseCalendar(cursor)
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
                println(e.message)
            } finally {
                cursor?.close()
            }
        } else {
            val parameters = CalendarMethodsParametersCacheModel(pendingChannelResult, RETRIEVE_CALENDAR_METHOD_CODE, calendarId)
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

            val contentResolver: ContentResolver? = _context?.getContentResolver()
            val eventsUriBuilder = CalendarContract.Instances.CONTENT_URI.buildUpon()
            ContentUris.appendId(eventsUriBuilder, startDate ?: Date(0).time)
            ContentUris.appendId(eventsUriBuilder, endDate ?: Date(Long.MAX_VALUE).time)

            val eventsUri = eventsUriBuilder.build()
            val eventsCalendarQuery = "(${Events.CALENDAR_ID} = $calendarId)"
            val eventsNotDeletedQuery = "(${Events.DELETED} != 1)"
            val eventsIdsQueryElements = eventIds.map { "(${CalendarContract.Instances.EVENT_ID} = $it)" }
            val eventsIdsQuery = eventsIdsQueryElements.joinToString(" OR ")

            var eventsSelectionQuery = "$eventsCalendarQuery AND $eventsNotDeletedQuery"
            if (!eventsIdsQuery.isNullOrEmpty()) {
                eventsSelectionQuery += " AND ($eventsIdsQuery)"
            }
            val eventsSortOrder = Events.DTSTART + " ASC"
            val eventsCursor = contentResolver?.query(eventsUri, EVENT_PROJECTION, eventsSelectionQuery, null, eventsSortOrder)

            val events: MutableList<Event> = mutableListOf()

            try {
                if (eventsCursor?.moveToFirst() ?: false) {
                    do {
                        val event = parseEvent(calendarId, eventsCursor)
                        if (event == null) {
                            continue
                        }

                        events.add(event)

                    } while (eventsCursor?.moveToNext() ?: false)

                    updateEventAttendees(events, contentResolver, pendingChannelResult)
                }
            } catch (e: Exception) {
                finishWithError(GENERIC_ERROR, e.message, pendingChannelResult)
                println(e.message)
            } finally {
                eventsCursor?.close()
            }

            finishWithSuccess(_gson?.toJson(events), pendingChannelResult)
        } else {
            val parameters = CalendarMethodsParametersCacheModel(pendingChannelResult, RETRIEVE_EVENTS_METHOD_CODE, calendarId, startDate, endDate)
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

            val contentResolver: ContentResolver? = _context?.getContentResolver()
            val values = ContentValues()
            val duration: String? = null
            values.put(Events.DTSTART, event.start)
            values.put(Events.DTEND, event.end)
            values.put(Events.TITLE, event.title)
            values.put(Events.DESCRIPTION, event.description)
            values.put(Events.CALENDAR_ID, calendarId)
            values.put(Events.DURATION, duration)

            // MK using current device time zone
            val calendar: java.util.Calendar = java.util.Calendar.getInstance()
            val currentTimeZone: TimeZone = calendar.timeZone
            values.put(Events.EVENT_TIMEZONE, currentTimeZone.displayName)
            if (event.recurrenceRule != null) {
                val recurrenceRuleParams = buildRecurrenceRuleParams(event.recurrenceRule!!)
                values.put(Events.RRULE, recurrenceRuleParams)
            }
            try {
                var eventId: Long? = event.eventId?.toLongOrNull()
                if (eventId == null) {
                    val uri = contentResolver?.insert(Events.CONTENT_URI, values)
                    // get the event ID that is the last element in the Uri
                    eventId = java.lang.Long.parseLong(uri?.getLastPathSegment())
                } else {
                    contentResolver?.update(ContentUris.withAppendedId(Events.CONTENT_URI, eventId), values, null, null)
                }

                finishWithSuccess(eventId.toString(), pendingChannelResult)
            } catch (e: Exception) {
                finishWithError(GENERIC_ERROR, e.message, pendingChannelResult)
                println(e.message)
            }
        } else {
            val parameters = CalendarMethodsParametersCacheModel(pendingChannelResult, CREATE_OR_UPDATE_EVENT_METHOD_CODE, calendarId)
            parameters.event = event
            requestPermissions(parameters)
        }
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

            val contentResolver: ContentResolver? = _context?.getContentResolver()

            val eventsUriWithId = ContentUris.withAppendedId(Events.CONTENT_URI, eventIdNumber)
            val deleteSucceeded = contentResolver?.delete(eventsUriWithId, null, null) ?: 0

            finishWithSuccess(deleteSucceeded > 0, pendingChannelResult)
        } else {
            val parameters = CalendarMethodsParametersCacheModel(pendingChannelResult, DELETE_EVENT_METHOD_CODE, calendarId)
            parameters.eventId = eventId
            requestPermissions(parameters)
        }
    }

    private fun arePermissionsGranted(): Boolean {
        if (atLeastAPI(23)) {
            val writeCalendarPermissionGranted = _activity?.checkSelfPermission(Manifest.permission.WRITE_CALENDAR) == PackageManager.PERMISSION_GRANTED
            val readCalendarPermissionGranted = _activity?.checkSelfPermission(Manifest.permission.READ_CALENDAR) == PackageManager.PERMISSION_GRANTED

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
            _activity?.requestPermissions(arrayOf(Manifest.permission.WRITE_CALENDAR, Manifest.permission.READ_CALENDAR), requestCode)
        }
    }

    private fun parseCalendar(cursor: Cursor?): Calendar? {
        if (cursor == null) {
            return null
        }

        val calId = cursor.getLong(CALENDAR_PROJECTION_ID_INDEX)
        val displayName = cursor.getString(CALENDAR_PROJECTION_DISPLAY_NAME_INDEX)
        val accessLevel = cursor.getInt(CALENDAR_PROJECTION_ACCESS_LEVEL_INDEX)

        val calendar = Calendar(calId.toString(), displayName)
        calendar.isReadOnly = isCalendarReadOnly(accessLevel)

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

        val event = Event()
        event.title = title
        event.eventId = eventId.toString()
        event.calendarId = calendarId
        event.description = description
        event.start = begin
        event.end = end
        event.allDay = allDay
        event.location = location
        event.recurrenceRule = parseRecurrenceRuleString(recurringRule)
        return event
    }

    private fun parseRecurrenceRuleString(recurrenceRuleString: String?): RecurrenceRule? {
        if (recurrenceRuleString == null) {
            return null
        }
        val rfcRecurrenceRule = org.dmfs.rfc5545.recur.RecurrenceRule(recurrenceRuleString!!)
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
                recurrenceRule.daysOfTheWeek = (rfcRecurrenceRule.byDayPart?.map {
                    DayOfWeek.values().find { dayOfWeek -> dayOfWeek.ordinal == it.weekday.ordinal }
                })?.filterNotNull()?.toMutableList()
            }
        }

        val rfcRecurrenceRuleString = rfcRecurrenceRule.toString()
        if (rfcRecurrenceRule.freq == Freq.MONTHLY) {
            recurrenceRule.daysOfTheMonth = convertCalendarPartToNumericValues(rfcRecurrenceRuleString, BYMONTHDAY_PART)
        }

        if (rfcRecurrenceRule.freq == Freq.YEARLY) {
            recurrenceRule.monthsOfTheYear = convertCalendarPartToNumericValues(rfcRecurrenceRuleString, BYMONTH_PART)
            recurrenceRule.weeksOfTheYear = convertCalendarPartToNumericValues(rfcRecurrenceRuleString, BYWEEKNO_PART)
        }

        recurrenceRule.setPositions = convertCalendarPartToNumericValues(rfcRecurrenceRuleString, BYSETPOS_PART)
        return recurrenceRule
    }

    private fun convertCalendarPartToNumericValues(rfcRecurrenceRuleString: String, partName: String): MutableList<Int>? {
        val partIndex = rfcRecurrenceRuleString.indexOf(partName)
        if (partIndex == -1) {
            return null
        }

        return (rfcRecurrenceRuleString.substring(partIndex).split(";").firstOrNull()?.split("=")?.lastOrNull()?.split(",")?.map {
            it.toInt()
        })?.toMutableList()
    }

    private fun parseAttendee(cursor: Cursor?): Attendee? {
        if (cursor == null) {
            return null
        }

        val id = cursor.getLong(ATTENDEE_ID_INDEX)
        val eventId = cursor.getLong(ATTENDEE_EVENT_ID_INDEX)
        val name = cursor.getString(ATTENDEE_NAME_INDEX)
        val email = cursor.getString(ATTENDEE_EMAIL_INDEX)
        val type = cursor.getInt(ATTENDEE_TYPE_INDEX)

        val attendee = Attendee(name)
        attendee.id = id
        attendee.eventId = eventId
        attendee.email = email
        attendee.attendanceRequired = type == CalendarContract.Attendees.TYPE_REQUIRED

        return attendee
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
    private fun updateEventAttendees(events: MutableList<Event>, contentResolver: ContentResolver?, pendingChannelResult: MethodChannel.Result) {

        if (events == null) {
            return
        }

        val eventsMapById = events.associateBy { it.eventId }
        val attendeesQueryEventIds = eventsMapById.values.map { "(${CalendarContract.Attendees.EVENT_ID} = ${it.eventId})" }
        val attendeesQuery = attendeesQueryEventIds.joinToString(" OR ")
        val attendeesCursor = contentResolver?.query(CalendarContract.Attendees.CONTENT_URI, ATTENDEE_PROJECTION, attendeesQuery, null, null);

        try {
            if (attendeesCursor?.moveToFirst() ?: false) {
                do {
                    val attendee = parseAttendee(attendeesCursor)
                    if (attendee == null) {
                        continue
                    }

                    if (eventsMapById.containsKey(attendee.eventId.toString())) {
                        val attendeeEvent = eventsMapById[attendee.eventId.toString()]
                        attendeeEvent?.attendees?.add(attendee)
                    }

                } while (attendeesCursor?.moveToNext() ?: false)
            }
        } catch (e: Exception) {
            finishWithError(GENERIC_ERROR, e.message, pendingChannelResult)
            println(e.message)
        } finally {
            attendeesCursor?.close();
        }

    }

    @Synchronized
    private fun generateUniqueRequestCodeAndCacheParameters(parameters: CalendarMethodsParametersCacheModel): Int {
        // TODO we can ran out of Int's at some point so this probably should re-use some of the freed ones
        val uniqueRequestCode: Int = (_cachedParametersMap.keys?.max() ?: 0) + 1
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


        when (recurrenceRule.recurrenceFrequency) {
            RecurrenceFrequency.WEEKLY, RecurrenceFrequency.MONTHLY, RecurrenceFrequency.YEARLY -> {
                if (recurrenceRule.daysOfTheWeek?.isEmpty() == true) {
                    rr.byDayPart = null
                } else {
                    rr.byDayPart = recurrenceRule.daysOfTheWeek?.mapNotNull { dayOfWeek ->
                        Weekday.values().firstOrNull {
                            it.ordinal == dayOfWeek.ordinal
                        }
                    }?.map {
                        org.dmfs.rfc5545.recur.RecurrenceRule.WeekdayNum(0, it)
                    }
                }
            }
        }

        if (recurrenceRule.totalOccurrences != null) {
            rr.count = recurrenceRule.totalOccurrences!!
        } else if (recurrenceRule.endDate != null) {
            val calendar = java.util.Calendar.getInstance();
            calendar.timeInMillis = recurrenceRule.endDate!!
            val dateFormat = SimpleDateFormat("yyyyMMdd")
            dateFormat.timeZone = calendar.timeZone
            rr.until = DateTime(calendar.timeZone, recurrenceRule.endDate!!)
        }

        var rrString = rr.toString()
        if (recurrenceRule.recurrenceFrequency == RecurrenceFrequency.MONTHLY && recurrenceRule.daysOfTheMonth != null && recurrenceRule.daysOfTheMonth!!.isNotEmpty()) {
            rrString = rrString.addPartWithValues(BYMONTHDAY_PART, recurrenceRule.daysOfTheMonth)
        }

        if (recurrenceRule.recurrenceFrequency == RecurrenceFrequency.YEARLY) {
            if (recurrenceRule.monthsOfTheYear != null && recurrenceRule.monthsOfTheYear!!.isNotEmpty()) {
                rrString = rrString.addPartWithValues(BYMONTH_PART, recurrenceRule.monthsOfTheYear)
            }

            if (recurrenceRule.weeksOfTheYear != null && recurrenceRule.weeksOfTheYear!!.isNotEmpty()) {
                rrString = rrString.addPartWithValues(BYWEEKNO_PART, recurrenceRule.weeksOfTheYear)
            }
        }

        rrString = rrString.addPartWithValues(BYSETPOS_PART, recurrenceRule.setPositions)
        return rrString
    }


    private fun String.addPartWithValues(partName: String, values: List<Int>?): String {
        if (values != null && values.isNotEmpty()) {
            return this + PART_TEMPLATE.format(partName) + values.joinToString(",")
        }

        return this
    }
}