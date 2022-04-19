package com.builttoroam.devicecalendar

import android.Manifest
import android.annotation.SuppressLint
import android.content.ContentResolver
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.database.Cursor
import android.graphics.Color
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.CalendarContract
import android.provider.CalendarContract.CALLER_IS_SYNCADAPTER
import android.provider.CalendarContract.Events
import android.text.format.DateUtils
import com.builttoroam.devicecalendar.common.CalendarType
import com.builttoroam.devicecalendar.common.Constants.Companion.ATTENDEE_CALENDAR_ID
import com.builttoroam.devicecalendar.common.Constants.Companion.ATTENDEE_EMAIL_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.ATTENDEE_EVENT_ID_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.ATTENDEE_ID_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.ATTENDEE_NAME_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.ATTENDEE_PROJECTION
import com.builttoroam.devicecalendar.common.Constants.Companion.ATTENDEE_RELATIONSHIP_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.ATTENDEE_STATUS_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.ATTENDEE_TYPE_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_ALLOWED_ATTENDEE_TYPES_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION_ACCESS_LEVEL_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION_ACCOUNT_NAME_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION_ACCOUNT_TYPE_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION_COLOR_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION_DISPLAY_NAME_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION_ID_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION_IS_PRIMARY_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION_OLDER_API
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION_OWNER_ACCOUNT_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_INSTANCE_DELETION
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_INSTANCE_DELETION_BEGIN_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_INSTANCE_DELETION_END_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_INSTANCE_DELETION_ID_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_INSTANCE_DELETION_LAST_DATE_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_INSTANCE_DELETION_RRULE_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_ALL_DAY_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_AVAILABILITY_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_BEGIN_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_CALENDAR_ID
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_CUSTOM_APP_URI_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_DESCRIPTION_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_END_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_END_TIMEZONE_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_EVENT_LOCATION_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_ID_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_ORGANIZER
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_RECURRING_RULE_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_START_TIMEZONE_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_TITLE_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.REMINDER_EVENT_ID
import com.builttoroam.devicecalendar.common.Constants.Companion.REMINDER_MINUTES_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.REMINDER_PROJECTION
import com.builttoroam.devicecalendar.common.Constants.Companion.SEARCH_CREATED_STEP
import com.builttoroam.devicecalendar.common.DayOfWeek
import com.builttoroam.devicecalendar.common.ErrorCodes.Companion.GENERIC_ERROR
import com.builttoroam.devicecalendar.common.ErrorCodes.Companion.INVALID_ARGUMENT
import com.builttoroam.devicecalendar.common.ErrorCodes.Companion.NOT_ALLOWED
import com.builttoroam.devicecalendar.common.ErrorCodes.Companion.NOT_AUTHORIZED
import com.builttoroam.devicecalendar.common.ErrorCodes.Companion.NOT_FOUND
import com.builttoroam.devicecalendar.common.ErrorMessages
import com.builttoroam.devicecalendar.common.ErrorMessages.Companion.CALENDAR_ID_INVALID_ARGUMENT_NOT_A_NUMBER_MESSAGE
import com.builttoroam.devicecalendar.common.ErrorMessages.Companion.CREATE_EVENT_ARGUMENTS_NOT_VALID_MESSAGE
import com.builttoroam.devicecalendar.common.ErrorMessages.Companion.EVENT_ID_CANNOT_BE_NULL_ON_DELETION_MESSAGE
import com.builttoroam.devicecalendar.common.ErrorMessages.Companion.NOT_AUTHORIZED_MESSAGE
import com.builttoroam.devicecalendar.common.RecurrenceFrequency
import com.builttoroam.devicecalendar.models.*
import com.builttoroam.devicecalendar.models.Calendar
import com.google.gson.Gson
import com.google.gson.GsonBuilder
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.*
import org.dmfs.rfc5545.DateTime
import org.dmfs.rfc5545.Weekday
import org.dmfs.rfc5545.recur.Freq
import java.text.SimpleDateFormat
import java.util.*
import kotlin.coroutines.CoroutineContext
import kotlin.coroutines.EmptyCoroutineContext

class CalendarDelegate : PluginRegistry.RequestPermissionsResultListener {
    private val RETRIEVE_CALENDARS_REQUEST_CODE = 0
    private val RETRIEVE_EVENTS_REQUEST_CODE = RETRIEVE_CALENDARS_REQUEST_CODE + 1
    private val RETRIEVE_CALENDAR_REQUEST_CODE = RETRIEVE_EVENTS_REQUEST_CODE + 1
    private val CREATE_OR_UPDATE_EVENT_REQUEST_CODE = RETRIEVE_CALENDAR_REQUEST_CODE + 1
    private val DELETE_EVENT_REQUEST_CODE = CREATE_OR_UPDATE_EVENT_REQUEST_CODE + 1
    private val REQUEST_PERMISSIONS_REQUEST_CODE = DELETE_EVENT_REQUEST_CODE + 1
    private val DELETE_CALENDAR_REQUEST_CODE = REQUEST_PERMISSIONS_REQUEST_CODE + 1
    private val PART_TEMPLATE = ";%s="
    private val BYMONTHDAY_PART = "BYMONTHDAY"
    private val BYMONTH_PART = "BYMONTH"
    private val BYSETPOS_PART = "BYSETPOS"

    private val _cachedParametersMap: MutableMap<Int, CalendarMethodsParametersCacheModel> =
        mutableMapOf()
    private var _binding: ActivityPluginBinding? = null
    private var _context: Context? = null
    private var _gson: Gson? = null

    private val uiThreadHandler = Handler(Looper.getMainLooper())

    constructor(binding: ActivityPluginBinding?, context: Context) {
        _binding = binding
        _context = context
        val gsonBuilder = GsonBuilder()
        gsonBuilder.registerTypeAdapter(
            RecurrenceFrequency::class.java,
            RecurrenceFrequencySerializer()
        )
        gsonBuilder.registerTypeAdapter(DayOfWeek::class.java, DayOfWeekSerializer())
        gsonBuilder.registerTypeAdapter(Availability::class.java, AvailabilitySerializer())
        _gson = gsonBuilder.create()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ): Boolean {
        val permissionGranted =
            grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED

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
                finishWithError(
                    NOT_AUTHORIZED,
                    NOT_AUTHORIZED_MESSAGE,
                    cachedValues.isAsync,
                    cachedValues.pendingChannelResult
                )
                return false
            }

            when (cachedValues.calendarDelegateMethodCode) {
                RETRIEVE_CALENDARS_REQUEST_CODE -> {
                    retrieveCalendars(cachedValues.isAsync, cachedValues.pendingChannelResult)
                }
                RETRIEVE_EVENTS_REQUEST_CODE -> {
                    retrieveEvents(
                        cachedValues.calendarIds,
                        cachedValues.calendarEventsStartDate,
                        cachedValues.calendarEventsEndDate,
                        cachedValues.calendarEventsIds,
                        cachedValues.isAsync,
                        cachedValues.pendingChannelResult
                    )
                }
                RETRIEVE_CALENDAR_REQUEST_CODE -> {
                    retrieveCalendar(
                        cachedValues.calendarId,
                        cachedValues.isAsync,
                        cachedValues.pendingChannelResult
                    )
                }
                CREATE_OR_UPDATE_EVENT_REQUEST_CODE -> {
                    createOrUpdateEvent(
                        cachedValues.calendarId,
                        cachedValues.event,
                        cachedValues.isAsync,
                        cachedValues.pendingChannelResult
                    )
                }
                DELETE_EVENT_REQUEST_CODE -> {
                    deleteEvent(
                        cachedValues.calendarId,
                        cachedValues.eventId,
                        cachedValues.isAsync,
                        cachedValues.pendingChannelResult
                    )
                }
                REQUEST_PERMISSIONS_REQUEST_CODE -> {
                    finishWithSuccess(
                        permissionGranted,
                        cachedValues.isAsync,
                        cachedValues.pendingChannelResult
                    )
                }
                DELETE_CALENDAR_REQUEST_CODE -> {
                    deleteCalendar(
                        cachedValues.calendarId,
                        cachedValues.isAsync,
                        cachedValues.pendingChannelResult
                    )
                }
            }

            return true
        } finally {
            _cachedParametersMap.remove(cachedValues.calendarDelegateMethodCode)
        }
    }

    fun requestPermissions(isAsync: Boolean, pendingChannelResult: MethodChannel.Result) {
        if (arePermissionsGranted()) {
            finishWithSuccess(true, isAsync, pendingChannelResult)
        } else {
            val parameters = CalendarMethodsParametersCacheModel(
                pendingChannelResult,
                REQUEST_PERMISSIONS_REQUEST_CODE,
                isAsync = isAsync
            )
            requestPermissions(parameters)
        }
    }

    fun hasPermissions(isAsync: Boolean, pendingChannelResult: MethodChannel.Result) {
        finishWithSuccess(arePermissionsGranted(), isAsync, pendingChannelResult)
    }

    @SuppressLint("MissingPermission")
    fun retrieveCalendars(isAsync: Boolean, pendingChannelResult: MethodChannel.Result) {
        if (arePermissionsGranted()) {
            val exceptionHandler = CoroutineExceptionHandler { _, exception ->
                finishWithError(GENERIC_ERROR, exception.message, isAsync, pendingChannelResult)
            }
            var calendars = listOf<Calendar>()
            GlobalScope.maybeLaunch(isAsync, exceptionHandler, isNeedJob = true) {
                calendars = getAllCalendars(isAsync, pendingChannelResult)
            }?.invokeOnCompletion { cause ->
                finishWithSuccess(
                    _gson?.toJson(calendars)?.toString(),
                    isAsync,
                    pendingChannelResult
                )
            }
        } else {
            val parameters = CalendarMethodsParametersCacheModel(
                pendingChannelResult,
                RETRIEVE_CALENDARS_REQUEST_CODE,
                isAsync = isAsync,
            )
            requestPermissions(parameters)
        }
    }

    private fun getAllCalendars(
        isAsync: Boolean,
        pendingChannelResult: MethodChannel.Result
    ): List<Calendar> {
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
            return calendars
        } catch (e: Exception) {
            finishWithError(GENERIC_ERROR, e.message, isAsync, pendingChannelResult)
        } finally {
            cursor?.close()
        }
        return emptyList()
    }

    private fun retrieveCalendar(
        calendarId: String,
        isAsync: Boolean,
        pendingChannelResult: MethodChannel.Result,
        isInternalCall: Boolean = false
    ): Calendar? {
        if (isInternalCall || arePermissionsGranted()) {
            val calendarIdNumber = calendarId.toLongOrNull()
            if (calendarIdNumber == null) {
                if (!isInternalCall) {
                    finishWithError(
                        INVALID_ARGUMENT,
                        CALENDAR_ID_INVALID_ARGUMENT_NOT_A_NUMBER_MESSAGE,
                        isAsync,
                        pendingChannelResult
                    )
                }
                return null
            }

            val contentResolver: ContentResolver? = _context?.contentResolver
            val uri: Uri = CalendarContract.Calendars.CONTENT_URI

            val cursor: Cursor? = if (atLeastAPI(17)) {
                contentResolver?.query(
                    ContentUris.withAppendedId(uri, calendarIdNumber),
                    CALENDAR_PROJECTION,
                    null,
                    null,
                    null
                )
            } else {
                contentResolver?.query(
                    ContentUris.withAppendedId(uri, calendarIdNumber),
                    CALENDAR_PROJECTION_OLDER_API,
                    null,
                    null,
                    null
                )
            }

            try {
                if (cursor?.moveToFirst() == true) {
                    val calendar = parseCalendarRow(cursor)
                    if (isInternalCall) {
                        return calendar
                    } else {
                        finishWithSuccess(
                            _gson?.toJson(calendar)?.toString(),
                            isAsync,
                            pendingChannelResult
                        )
                    }
                } else {
                    if (!isInternalCall) {
                        finishWithError(
                            NOT_FOUND,
                            "The calendar with the ID $calendarId could not be found",
                            isAsync,
                            pendingChannelResult
                        )
                    }
                }
            } catch (e: Exception) {
                finishWithError(GENERIC_ERROR, e.message, isAsync, pendingChannelResult)
            } finally {
                cursor?.close()
            }
        } else {
            val parameters = CalendarMethodsParametersCacheModel(
                pendingChannelResult,
                RETRIEVE_CALENDAR_REQUEST_CODE,
                calendarId
            )
            requestPermissions(parameters)
        }

        return null
    }

    fun deleteCalendar(
        calendarId: String,
        isAsync: Boolean,
        pendingChannelResult: MethodChannel.Result,
        isInternalCall: Boolean = false
    ) {
        if (isInternalCall || arePermissionsGranted()) {

            val exceptionHandler = CoroutineExceptionHandler { _, exception ->
                finishWithError(GENERIC_ERROR, exception.message, isAsync, pendingChannelResult)
            }
            GlobalScope.maybeLaunch(isAsync, exceptionHandler) {
                val calendarIdNumber = calendarId.toLongOrNull()
                if (calendarIdNumber == null) {
                    if (!isInternalCall) {
                        finishWithError(
                            INVALID_ARGUMENT,
                            CALENDAR_ID_INVALID_ARGUMENT_NOT_A_NUMBER_MESSAGE,
                            isAsync,
                            pendingChannelResult
                        )
                    }
                    return@maybeLaunch
                }

                val contentResolver: ContentResolver? = _context?.contentResolver

                val calendar = retrieveCalendar(calendarId, isAsync, pendingChannelResult, true);
                if (calendar != null) {
                    val calenderUriWithId = ContentUris.withAppendedId(
                        CalendarContract.Calendars.CONTENT_URI,
                        calendarIdNumber
                    )
                    val deleteSucceeded =
                        contentResolver?.delete(calenderUriWithId, null, null) ?: 0
                    finishWithSuccess(deleteSucceeded > 0, isAsync, pendingChannelResult)
                } else {
                    if (!isInternalCall) {
                        finishWithError(
                            NOT_FOUND,
                            "The calendar with the ID $calendarId could not be found",
                            isAsync,
                            pendingChannelResult
                        )
                    }
                }
            }
        } else {
            val parameters = CalendarMethodsParametersCacheModel(
                pendingChannelResult = pendingChannelResult,
                calendarDelegateMethodCode = DELETE_CALENDAR_REQUEST_CODE,
                calendarId = calendarId
            )
            requestPermissions(parameters)
        }
    }

    fun createCalendar(
        calendarName: String,
        calendarColor: String?,
        localAccountName: String,
        isAsync: Boolean,
        pendingChannelResult: MethodChannel.Result
    ) {

        val exceptionHandler = CoroutineExceptionHandler { _, exception ->
            finishWithError(GENERIC_ERROR, exception.message, isAsync, pendingChannelResult)
        }
        GlobalScope.maybeLaunch(isAsync, exceptionHandler) {
            val contentResolver: ContentResolver? = _context?.contentResolver

            var uri = CalendarContract.Calendars.CONTENT_URI
            uri = uri.buildUpon()
                .appendQueryParameter(CALLER_IS_SYNCADAPTER, "true")
                .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_NAME, localAccountName)
                .appendQueryParameter(
                    CalendarContract.Calendars.ACCOUNT_TYPE,
                    CalendarContract.ACCOUNT_TYPE_LOCAL
                )
                .build()
            val values = ContentValues()
            values.put(CalendarContract.Calendars.NAME, calendarName)
            values.put(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME, calendarName)
            values.put(CalendarContract.Calendars.ACCOUNT_NAME, localAccountName)
            values.put(CalendarContract.Calendars.ACCOUNT_TYPE, CalendarContract.ACCOUNT_TYPE_LOCAL)
            values.put(
                CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL,
                CalendarContract.Calendars.CAL_ACCESS_OWNER
            )
            values.put(
                CalendarContract.Calendars.CALENDAR_COLOR, Color.parseColor(
                    (calendarColor
                        ?: "0xFFFF0000").replace("0x", "#")
                )
            ) // Red colour as a default
            values.put(CalendarContract.Calendars.OWNER_ACCOUNT, localAccountName)
            values.put(
                CalendarContract.Calendars.CALENDAR_TIME_ZONE,
                java.util.Calendar.getInstance().timeZone.id
            )

            val result = contentResolver?.insert(uri, values)
            // Get the calendar ID that is the last element in the Uri
            val calendarId = java.lang.Long.parseLong(result?.lastPathSegment!!)

            finishWithSuccess(calendarId.toString(), isAsync, pendingChannelResult)
        }
    }

    fun retrieveEvents(
        calendarIds: List<String>?,
        startDate: Long?,
        endDate: Long?,
        eventIds: List<String>,
        isAsync: Boolean,
        pendingChannelResult: MethodChannel.Result
    ) {
        if (startDate == null && endDate == null && eventIds.isEmpty()) {
            finishWithError(
                INVALID_ARGUMENT,
                ErrorMessages.RETRIEVE_EVENTS_ARGUMENTS_NOT_VALID_MESSAGE,
                isAsync,
                pendingChannelResult
            )
            return
        }

        if (arePermissionsGranted()) {
            val calendars = getAllCalendars(isAsync, pendingChannelResult).associateBy { it.id }
            val contentResolver: ContentResolver? = _context?.contentResolver
            val eventsUriBuilder = CalendarContract.Instances.CONTENT_URI.buildUpon()
            ContentUris.appendId(eventsUriBuilder, startDate ?: Date(0).time)
            ContentUris.appendId(eventsUriBuilder, endDate ?: Date(Long.MAX_VALUE).time)

            val eventsUri = eventsUriBuilder.build()
            val eventsCalendarQuery =
                calendarIds?.let { "(${Events.CALENDAR_ID} in (${it.joinToString(", ")}))" }
            val eventsNotDeletedQuery = "(${Events.DELETED} != 1)"
            val eventsIdsQuery =
                "(${CalendarContract.Instances.EVENT_ID} IN (${eventIds.joinToString()}))"

            var eventsSelectionQuery =
                eventsCalendarQuery?.let { "$eventsCalendarQuery AND $eventsNotDeletedQuery" }
                    ?: eventsNotDeletedQuery
            if (eventIds.isNotEmpty()) {
                eventsSelectionQuery += " AND ($eventsIdsQuery)"
            }
            val eventsSortOrder = Events.DTSTART + " DESC"

            val eventsCursor = contentResolver?.query(
                eventsUri,
                EVENT_PROJECTION,
                eventsSelectionQuery,
                null,
                eventsSortOrder
            )

            val events: MutableList<Event> = mutableListOf()

            val exceptionHandler = CoroutineExceptionHandler { _, exception ->
                finishWithError(GENERIC_ERROR, exception.message, isAsync, pendingChannelResult)
            }

            GlobalScope.maybeLaunch(isAsync, exceptionHandler, isNeedJob = true) {
                while (eventsCursor?.moveToNext() == true) {
                    val event = parseEvent(eventsCursor, calendars) ?: continue
                    events.add(event)
                }
                addAttendees(calendars, events, contentResolver)
                addReminders(events, contentResolver)
            }?.invokeOnCompletion { cause ->
                eventsCursor?.close()
                if (cause == null) {
                    finishWithSuccess(
                        _gson?.toJson(events)?.toString(),
                        isAsync,
                        pendingChannelResult
                    )
                }
            }
        } else {
            val parameters = CalendarMethodsParametersCacheModel(
                pendingChannelResult,
                RETRIEVE_EVENTS_REQUEST_CODE,
                calendarIds = calendarIds,
                calendarEventsStartDate = startDate,
                calendarEventsEndDate = endDate,
                isAsync = isAsync
            )
            requestPermissions(parameters)
        }

        return
    }

    fun createOrUpdateEvent(
        calendarId: String,
        event: Event?,
        isAsync: Boolean,
        pendingChannelResult: MethodChannel.Result,
        startDate: Long? = null,
        endDate: Long? = null,
        followingInstances: Boolean? = null
    ) {
        if (arePermissionsGranted()) {
            var eventId: Long? = event?.eventId?.toLongOrNull()

            val exceptionHandler = CoroutineExceptionHandler { _, exception ->
                finishWithError(GENERIC_ERROR, exception.message, isAsync, pendingChannelResult)
            }
            GlobalScope.maybeLaunch(isAsync, exceptionHandler, isNeedJob = true) {
                if (event == null) {
                    finishWithError(
                        GENERIC_ERROR,
                        CREATE_EVENT_ARGUMENTS_NOT_VALID_MESSAGE,
                        isAsync,
                        pendingChannelResult
                    )
                    return@maybeLaunch
                }

                val calendar = retrieveCalendar(calendarId, isAsync, pendingChannelResult, true)
                if (calendar == null) {
                    finishWithError(
                        NOT_FOUND,
                        "Couldn't retrieve the Calendar with ID $calendarId",
                        isAsync,
                        pendingChannelResult
                    )
                    return@maybeLaunch
                }

                val contentResolver: ContentResolver? = _context?.contentResolver
                val values = buildEventContentValues(event, calendarId)
                if (eventId == null) {
                    val uri = contentResolver?.insert(Events.CONTENT_URI, values)
                    // get the event ID that is the last element in the Uri
                    eventId = java.lang.Long.parseLong(uri?.lastPathSegment!!)
                    insertAttendees(event.attendees, eventId, contentResolver)
                    insertReminders(event.reminders, eventId, contentResolver)
                } else {
                    var id = eventId!!
                    if (startDate != null || endDate != null || followingInstances != null) {
                        deleteEventProcess(
                            calendarId = calendarId,
                            eventId = id.toString(),
                            isAsync = isAsync,
                            pendingChannelResult = pendingChannelResult,
                            startDate = startDate,
                            endDate = endDate,
                            followingInstances = followingInstances,
                            isInternalCall = true,
                        )
                        if (followingInstances != true) {
                            values.remove(Events.RRULE)
                        }
                        val uri = contentResolver?.insert(Events.CONTENT_URI, values)
                        // get the event ID that is the last element in the Uri
                        eventId = java.lang.Long.parseLong(uri?.lastPathSegment!!)
                        id = eventId!!
                    } else {
                        contentResolver?.update(
                            ContentUris.withAppendedId(Events.CONTENT_URI, id),
                            values,
                            null,
                            null
                        )
                    }
                    val existingAttendees =
                        retrieveAttendees(calendar, eventId.toString(), contentResolver)
                    val attendeesToDelete =
                        if (event.attendees.isNotEmpty()) existingAttendees.filter { existingAttendee -> event.attendees.all { it.emailAddress != existingAttendee.emailAddress } } else existingAttendees
                    for (attendeeToDelete in attendeesToDelete) {
                        deleteAttendee(id, attendeeToDelete, contentResolver)
                    }

                    val attendeesToInsert =
                        event.attendees.filter { existingAttendees.all { existingAttendee -> existingAttendee.emailAddress != it.emailAddress } }
                    insertAttendees(attendeesToInsert, eventId, contentResolver)
                    deleteExistingReminders(contentResolver, id)
                    insertReminders(event.reminders, eventId, contentResolver!!)

                    val existingSelfAttendee = existingAttendees.firstOrNull {
                        it.emailAddress == calendar.ownerAccount
                    }
                    val newSelfAttendee = event.attendees.firstOrNull {
                        it.emailAddress == calendar.ownerAccount
                    }
                    if (existingSelfAttendee != null && newSelfAttendee != null &&
                        newSelfAttendee.attendanceStatus != null &&
                        existingSelfAttendee.attendanceStatus != newSelfAttendee.attendanceStatus
                    ) {
                        updateAttendeeStatus(id, newSelfAttendee, contentResolver)
                    }
                }
            }?.invokeOnCompletion { cause ->
                if (cause == null) {
                    retrieveEvents(
                        listOf(event!!.calendarId!!),
                        event.eventStartDate,
                        event.eventStartDate!! + SEARCH_CREATED_STEP,
                        listOf(eventId.toString()),
                        isAsync,
                        pendingChannelResult
                    )
                }
            }
        } else {
            val parameters = CalendarMethodsParametersCacheModel(
                pendingChannelResult,
                CREATE_OR_UPDATE_EVENT_REQUEST_CODE,
                calendarId
            )
            parameters.event = event
            requestPermissions(parameters)
        }
    }

    private fun deleteExistingReminders(contentResolver: ContentResolver?, eventId: Long) {
        val cursor = CalendarContract.Reminders.query(
            contentResolver, eventId, arrayOf(
                CalendarContract.Reminders._ID
            )
        )
        while (cursor != null && cursor.moveToNext()) {
            var reminderUri: Uri? = null
            val reminderId = cursor.getLong(0)
            if (reminderId > 0) {
                reminderUri =
                    ContentUris.withAppendedId(CalendarContract.Reminders.CONTENT_URI, reminderId)
            }
            if (reminderUri != null) {
                contentResolver?.delete(reminderUri, null, null)
            }
        }
        cursor?.close()
    }

    @SuppressLint("MissingPermission")
    private fun insertReminders(
        reminders: List<Reminder>,
        eventId: Long?,
        contentResolver: ContentResolver
    ) {
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
        values.put(Events.ALL_DAY, event.eventAllDay)
        values.put(Events.DTSTART, event.eventStartDate!!)
        values.put(Events.EVENT_TIMEZONE, getTimeZone(event.eventStartTimeZone).id)
        values.put(Events.DTEND, event.eventEndDate!!)
        values.put(Events.EVENT_END_TIMEZONE, getTimeZone(event.eventEndTimeZone).id)
        values.put(Events.TITLE, event.eventTitle)
        values.put(Events.DESCRIPTION, event.eventDescription)
        values.put(Events.EVENT_LOCATION, event.eventLocation)
        values.put(Events.CUSTOM_APP_URI, event.eventURL)
        values.put(Events.CALENDAR_ID, calendarId)
        values.put(Events.DURATION, duration)
        values.put(Events.AVAILABILITY, getAvailability(event.availability))

        if (event.recurrenceRule != null) {
            val recurrenceRuleParams = buildRecurrenceRuleParams(event.recurrenceRule!!)
            values.put(Events.RRULE, recurrenceRuleParams)
        }
        return values
    }

    private fun getTimeZone(timeZoneString: String?): TimeZone {
        val deviceTimeZone: TimeZone = java.util.Calendar.getInstance().timeZone
        var timeZone = TimeZone.getTimeZone(timeZoneString ?: deviceTimeZone.id)

        // Invalid time zone names defaults to GMT so update that to be device's time zone
        if (timeZone.id == "GMT" && timeZoneString != "GMT") {
            timeZone = TimeZone.getTimeZone(deviceTimeZone.id)
        }

        return timeZone
    }

    private fun getAvailability(availability: Availability?): Int? = when (availability) {
        Availability.BUSY -> Events.AVAILABILITY_BUSY
        Availability.FREE -> Events.AVAILABILITY_FREE
        Availability.TENTATIVE -> Events.AVAILABILITY_TENTATIVE
        else -> null
    }

    @SuppressLint("MissingPermission")
    private fun insertAttendees(
        attendees: List<Attendee>,
        eventId: Long?,
        contentResolver: ContentResolver?
    ) {
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
                    it.attendanceStatus
                )
                put(CalendarContract.Attendees.EVENT_ID, eventId)
            }
        }.toTypedArray()

        contentResolver?.bulkInsert(CalendarContract.Attendees.CONTENT_URI, attendeesValues)
    }

    @SuppressLint("MissingPermission")
    private fun deleteAttendee(
        eventId: Long,
        attendee: Attendee,
        contentResolver: ContentResolver?
    ) {
        val selection =
            "(" + CalendarContract.Attendees.EVENT_ID + " = ?) AND (" + CalendarContract.Attendees.ATTENDEE_EMAIL + " = ?)"
        val selectionArgs = arrayOf(eventId.toString() + "", attendee.emailAddress)
        contentResolver?.delete(CalendarContract.Attendees.CONTENT_URI, selection, selectionArgs)

    }

    private fun updateAttendeeStatus(
        eventId: Long,
        attendee: Attendee,
        contentResolver: ContentResolver?
    ) {
        val selection =
            "(" + CalendarContract.Attendees.EVENT_ID + " = ?) AND (" + CalendarContract.Attendees.ATTENDEE_EMAIL + " = ?)"
        val selectionArgs = arrayOf(eventId.toString() + "", attendee.emailAddress)
        val values = ContentValues()
        values.put(CalendarContract.Attendees.ATTENDEE_STATUS, attendee.attendanceStatus)
        contentResolver?.update(
            CalendarContract.Attendees.CONTENT_URI,
            values,
            selection,
            selectionArgs
        )
    }

    private fun deleteEventProcess(
        calendarId: String,
        eventId: String,
        isAsync: Boolean,
        pendingChannelResult: MethodChannel.Result,
        startDate: Long? = null,
        endDate: Long? = null,
        followingInstances: Boolean? = null,
        isInternalCall: Boolean = false
    ) {
        val existingCal = retrieveCalendar(calendarId, isAsync, pendingChannelResult, true)
        if (existingCal == null) {
            if (!isInternalCall) finishWithError(
                NOT_FOUND,
                "The calendar with the ID $calendarId could not be found",
                isAsync,
                pendingChannelResult
            )
            return
        }

        if (existingCal.isReadOnly) {
            if (!isInternalCall) finishWithError(
                NOT_ALLOWED,
                "Calendar with ID $calendarId is read-only",
                isAsync,
                pendingChannelResult
            )
            return
        }

        val eventIdNumber = eventId.toLongOrNull()
        if (eventIdNumber == null) {
            if (!isInternalCall) finishWithError(
                INVALID_ARGUMENT,
                EVENT_ID_CANNOT_BE_NULL_ON_DELETION_MESSAGE,
                isAsync,
                pendingChannelResult
            )
            return
        }

        val contentResolver: ContentResolver? = _context?.contentResolver
        if (startDate == null && endDate == null && followingInstances == null) { // Delete all instances
            val eventsUriWithId =
                ContentUris.withAppendedId(Events.CONTENT_URI, eventIdNumber)
            val deleteSucceeded = contentResolver?.delete(eventsUriWithId, null, null) ?: 0
            if (!isInternalCall) finishWithSuccess(
                deleteSucceeded > 0,
                isAsync,
                pendingChannelResult
            )
        } else {
            if (!followingInstances!!) { // Only this instance
                val exceptionUriWithId =
                    ContentUris.withAppendedId(Events.CONTENT_EXCEPTION_URI, eventIdNumber)
                val values = ContentValues()
                val instanceCursor = CalendarContract.Instances.query(
                    contentResolver,
                    EVENT_INSTANCE_DELETION,
                    startDate!!,
                    endDate!!
                )

                while (instanceCursor.moveToNext()) {
                    val foundEventID =
                        instanceCursor.getLong(EVENT_INSTANCE_DELETION_ID_INDEX)

                    if (eventIdNumber == foundEventID) {
                        values.put(
                            Events.ORIGINAL_INSTANCE_TIME,
                            instanceCursor.getLong(EVENT_INSTANCE_DELETION_BEGIN_INDEX)
                        )
                        values.put(Events.STATUS, Events.STATUS_CANCELED)
                    }
                }

                val deleteSucceeded = contentResolver?.insert(exceptionUriWithId, values)
                instanceCursor.close()
                if (!isInternalCall) finishWithSuccess(
                    deleteSucceeded != null,
                    isAsync,
                    pendingChannelResult
                )
            } else { // This and following instances
                val eventsUriWithId =
                    ContentUris.withAppendedId(Events.CONTENT_URI, eventIdNumber)
                val values = ContentValues()
                val instanceCursor = CalendarContract.Instances.query(
                    contentResolver,
                    EVENT_INSTANCE_DELETION,
                    startDate!!,
                    endDate!!
                )

                while (instanceCursor.moveToNext()) {
                    val foundEventID =
                        instanceCursor.getLong(EVENT_INSTANCE_DELETION_ID_INDEX)

                    if (eventIdNumber == foundEventID) {
                        val newRule = org.dmfs.rfc5545.recur.RecurrenceRule(
                            instanceCursor.getString(EVENT_INSTANCE_DELETION_RRULE_INDEX)
                        )
                        val lastDate =
                            instanceCursor.getLong(EVENT_INSTANCE_DELETION_LAST_DATE_INDEX)

                        if (lastDate > 0 && newRule.count != null && newRule.count > 0) { // Update occurrence rule
                            val cursor = CalendarContract.Instances.query(
                                contentResolver,
                                EVENT_INSTANCE_DELETION,
                                startDate,
                                lastDate
                            )
                            while (cursor.moveToNext()) {
                                if (eventIdNumber == cursor.getLong(
                                        EVENT_INSTANCE_DELETION_ID_INDEX
                                    )
                                ) {
                                    newRule.count--
                                }
                            }
                            cursor.close()
                        } else { // Indefinite and specified date rule
                            val cursor = CalendarContract.Instances.query(
                                contentResolver,
                                EVENT_INSTANCE_DELETION,
                                startDate - DateUtils.YEAR_IN_MILLIS,
                                startDate - 1
                            )
                            var lastRecurrenceDate: Long? = null

                            while (cursor.moveToNext()) {
                                if (eventIdNumber == cursor.getLong(
                                        EVENT_INSTANCE_DELETION_ID_INDEX
                                    )
                                ) {
                                    lastRecurrenceDate =
                                        cursor.getLong(EVENT_INSTANCE_DELETION_END_INDEX)
                                }
                            }

                            if (lastRecurrenceDate != null) {
                                newRule.until = DateTime(lastRecurrenceDate)
                            } else {
                                newRule.until = DateTime(startDate - 1)
                            }
                            cursor.close()
                        }

                        values.put(Events.RRULE, newRule.toString())
                        contentResolver?.update(eventsUriWithId, values, null, null)
                        if (!isInternalCall) finishWithSuccess(
                            true,
                            isAsync,
                            pendingChannelResult
                        )
                    }
                }
                instanceCursor.close()
            }
        }
    }

    fun deleteEvent(
        calendarId: String,
        eventId: String,
        isAsync: Boolean,
        pendingChannelResult: MethodChannel.Result,
        startDate: Long? = null,
        endDate: Long? = null,
        followingInstances: Boolean? = null,
    ) {
        if (arePermissionsGranted()) {

            val exceptionHandler = CoroutineExceptionHandler { _, exception ->
                finishWithError(
                    GENERIC_ERROR,
                    exception.message,
                    isAsync,
                    pendingChannelResult
                )
            }
            GlobalScope.maybeLaunch(isAsync, exceptionHandler) {
                deleteEventProcess(
                    calendarId,
                    eventId,
                    isAsync,
                    pendingChannelResult,
                    startDate,
                    endDate,
                    followingInstances,
                    false
                )
            }
        } else {
            val parameters = CalendarMethodsParametersCacheModel(
                pendingChannelResult,
                DELETE_EVENT_REQUEST_CODE,
                calendarId
            )
            parameters.eventId = eventId
            requestPermissions(parameters)
        }
    }

    private fun arePermissionsGranted(): Boolean {
        if (atLeastAPI(23)) {
            if (_binding == null) return true
            val writeCalendarPermissionGranted =
                _binding?.activity?.checkSelfPermission(Manifest.permission.WRITE_CALENDAR) == PackageManager.PERMISSION_GRANTED
            val readCalendarPermissionGranted =
                _binding?.activity?.checkSelfPermission(Manifest.permission.READ_CALENDAR) == PackageManager.PERMISSION_GRANTED
            return writeCalendarPermissionGranted && readCalendarPermissionGranted
        }

        return true
    }

    private fun requestPermissions(
        parameters: CalendarMethodsParametersCacheModel
    ): Boolean {
        val requestCode: Int = generateUniqueRequestCodeAndCacheParameters(parameters)
        return requestPermissions(requestCode).apply {
            if (!this) {
                finishWithError(
                    NOT_AUTHORIZED,
                    NOT_AUTHORIZED_MESSAGE,
                    false,
                    parameters.pendingChannelResult
                )
                _cachedParametersMap.remove(requestCode)
            }
        }
    }

    private fun requestPermissions(requestCode: Int): Boolean {
        if (atLeastAPI(23)) {
            return _binding?.activity?.requestPermissions(
                arrayOf(
                    Manifest.permission.WRITE_CALENDAR,
                    Manifest.permission.READ_CALENDAR
                ), requestCode
            )?.let { true } ?: false
        }
        return false
    }

    private fun parseCalendarRow(cursor: Cursor?): Calendar? {
        if (cursor == null) {
            return null
        }

        val calId = cursor.getLong(CALENDAR_PROJECTION_ID_INDEX)
        val displayName = cursor.getString(CALENDAR_PROJECTION_DISPLAY_NAME_INDEX)
        val accessLevel = cursor.getInt(CALENDAR_PROJECTION_ACCESS_LEVEL_INDEX)
        val calendarColor = cursor.getInt(CALENDAR_PROJECTION_COLOR_INDEX)
        val accountName = cursor.getString(CALENDAR_PROJECTION_ACCOUNT_NAME_INDEX)
        val accountType = cursor.getString(CALENDAR_PROJECTION_ACCOUNT_TYPE_INDEX)
        val ownerAccount = cursor.getString(CALENDAR_PROJECTION_OWNER_ACCOUNT_INDEX)

        val calendar = Calendar(
            calId.toString(),
            displayName,
            calendarColor,
            accountName,
            accountType,
            ownerAccount,
            cursor.getString(CALENDAR_ALLOWED_ATTENDEE_TYPES_INDEX).isNotEmpty(),
            !CalendarType.withMembers.contains(accountType.lowercase())
        )

        calendar.isReadOnly = isCalendarReadOnly(accessLevel)
        if (atLeastAPI(17)) {
            val isPrimary = cursor.getString(CALENDAR_PROJECTION_IS_PRIMARY_INDEX)
            calendar.isDefault = isPrimary == "1"
        } else {
            calendar.isDefault = false
        }
        return calendar
    }

    private fun parseEvent(cursor: Cursor?, calendars: Map<String, Calendar>): Event? {
        if (cursor == null) {
            return null
        }

        val eventId = cursor.getLong(EVENT_PROJECTION_ID_INDEX)
        val calendarId = cursor.getString(EVENT_PROJECTION_CALENDAR_ID)
        val title = cursor.getString(EVENT_PROJECTION_TITLE_INDEX)
        val description = cursor.getString(EVENT_PROJECTION_DESCRIPTION_INDEX)
        val begin = cursor.getLong(EVENT_PROJECTION_BEGIN_INDEX)
        val end = cursor.getLong(EVENT_PROJECTION_END_INDEX)
        val recurringRule = cursor.getString(EVENT_PROJECTION_RECURRING_RULE_INDEX)
        val allDay = cursor.getInt(EVENT_PROJECTION_ALL_DAY_INDEX) > 0
        val location = cursor.getString(EVENT_PROJECTION_EVENT_LOCATION_INDEX)
        val url = cursor.getString(EVENT_PROJECTION_CUSTOM_APP_URI_INDEX)
        val startTimeZone = cursor.getString(EVENT_PROJECTION_START_TIMEZONE_INDEX)
        val endTimeZone = cursor.getString(EVENT_PROJECTION_END_TIMEZONE_INDEX)
        val availability = parseAvailability(cursor.getInt(EVENT_PROJECTION_AVAILABILITY_INDEX))
        val organizer = cursor.getString(EVENT_PROJECTION_ORGANIZER)
        val event = Event()
        event.eventTitle = title ?: "New Event"
        event.eventId = eventId.toString()
        event.calendarId = calendarId
        event.eventDescription = description
        event.eventStartDate = begin
        event.eventEndDate = end
        event.eventAllDay = allDay
        event.eventLocation = location
        event.eventURL = url
        event.recurrenceRule = parseRecurrenceRuleString(recurringRule)
        event.eventStartTimeZone = startTimeZone
        event.eventEndTimeZone = endTimeZone
        event.availability = availability
        event.organizer = Attendee(
            "",
            eventId.toString(),
            organizer,
            name = null,
            isOrganizer = true,
            role = CalendarContract.Attendees.TYPE_REQUIRED,
            isCurrentUser = organizer == calendars[calendarId]?.ownerAccount,
            attendanceStatus = CalendarContract.Attendees.ATTENDEE_STATUS_ACCEPTED,
        )
        return event
    }

    private fun parseRecurrenceRuleString(recurrenceRuleString: String?): RecurrenceRule? {
        if (recurrenceRuleString == null || recurrenceRuleString.isEmpty()) {
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
        recurrenceRule.weekStart = rfcRecurrenceRule.weekStart.dayOfWeek()
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
            recurrenceRule.weekOfMonth =
                convertCalendarPartToNumericValues(
                    rfcRecurrenceRuleString,
                    BYSETPOS_PART
                )?.firstOrNull()

            // If value is not found in BYSETPOS and not repeating by nth day or nth month
            // Get the week number value from the BYDAY position
            if (recurrenceRule.weekOfMonth == null && rfcRecurrenceRule.byDayPart != null) {
                recurrenceRule.weekOfMonth = rfcRecurrenceRule.byDayPart.first().pos
            }

            recurrenceRule.dayOfMonth =
                convertCalendarPartToNumericValues(rfcRecurrenceRuleString, BYMONTHDAY_PART)

            if (rfcRecurrenceRule.freq == Freq.YEARLY) {
                recurrenceRule.monthOfYear =
                    convertCalendarPartToNumericValues(rfcRecurrenceRuleString, BYMONTH_PART)
            }
        }

        return recurrenceRule
    }

    private fun convertCalendarPartToNumericValues(
        rfcRecurrenceRuleString: String,
        partName: String
    ): MutableList<Int>? {
        val partIndex = rfcRecurrenceRuleString.indexOf(partName)
        if (partIndex == -1) {
            return null
        }

        return rfcRecurrenceRuleString.substring(partIndex).split(";").firstOrNull()?.split("=")
            ?.lastOrNull()?.split(",")?.map {
                it.toInt()
            }?.toMutableList()
    }

    private fun parseAttendeeRow(calendars: Map<String, Calendar>, cursor: Cursor?): Attendee? {
        if (cursor == null) {
            return null
        }
        return parseAttendeeRow(calendars[cursor.getString(ATTENDEE_CALENDAR_ID)], cursor)
    }

    private fun parseAttendeeRow(calendar: Calendar?, cursor: Cursor?): Attendee? {
        if (cursor == null) {
            return null
        }
        val emailAddress = cursor.getString(ATTENDEE_EMAIL_INDEX)
        return Attendee(
            cursor.getString(ATTENDEE_ID_INDEX),
            cursor.getString(ATTENDEE_EVENT_ID_INDEX),
            emailAddress,
            cursor.getString(ATTENDEE_NAME_INDEX),
            cursor.getInt(ATTENDEE_TYPE_INDEX),
            cursor.getInt(ATTENDEE_STATUS_INDEX),
            cursor.getInt(ATTENDEE_RELATIONSHIP_INDEX) == CalendarContract.Attendees.RELATIONSHIP_ORGANIZER,
            emailAddress == calendar?.ownerAccount
        )
    }

    private fun parseReminderRow(cursor: Cursor?): Reminder? {
        if (cursor == null) {
            return null
        }

        return Reminder(cursor.getString(REMINDER_EVENT_ID), cursor.getInt(REMINDER_MINUTES_INDEX))
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
    private fun retrieveAttendees(
        calendar: Calendar,
        eventId: String,
        contentResolver: ContentResolver?
    ): MutableList<Attendee> {
        val attendees: MutableList<Attendee> = mutableListOf()
        val attendeesQuery = "(${CalendarContract.Attendees.EVENT_ID} = ${eventId})"
        val attendeesCursor = contentResolver?.query(
            CalendarContract.Attendees.CONTENT_URI,
            ATTENDEE_PROJECTION,
            attendeesQuery,
            null,
            null
        )
        attendeesCursor.use { cursor ->
            if (cursor?.moveToFirst() == true) {
                do {
                    val attendee = parseAttendeeRow(calendar, attendeesCursor) ?: continue
                    attendees.add(attendee)
                } while (cursor.moveToNext())
            }
        }

        return attendees
    }

    @SuppressLint("MissingPermission")
    private fun retrieveReminders(
        eventId: String,
        contentResolver: ContentResolver?
    ): MutableList<Reminder> {
        val reminders: MutableList<Reminder> = mutableListOf()
        val remindersQuery = "(${CalendarContract.Reminders.EVENT_ID} = ${eventId})"
        val remindersCursor = contentResolver?.query(
            CalendarContract.Reminders.CONTENT_URI,
            REMINDER_PROJECTION,
            remindersQuery,
            null,
            null
        )
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

    @SuppressLint("MissingPermission")
    private fun addAttendees(
        calendars: Map<String, Calendar>,
        events: List<Event>,
        contentResolver: ContentResolver?
    ) {
        val attendees: MutableList<Attendee> = mutableListOf()
        val attendeesQuery = "(${CalendarContract.Attendees.EVENT_ID} in (${
            events.map { it.eventId }.joinToString(", ")
        }))"
        val attendeesCursor = contentResolver?.query(
            CalendarContract.Attendees.CONTENT_URI,
            ATTENDEE_PROJECTION,
            attendeesQuery,
            null,
            null
        )
        attendeesCursor.use { cursor ->
            if (cursor?.moveToFirst() == true) {
                do {
                    val attendee = parseAttendeeRow(calendars, attendeesCursor) ?: continue
                    attendees.add(attendee)
                } while (cursor.moveToNext())
            }
        }
        val mapAttendees = attendees.groupBy { it.eventId }
        for (event in events) {
            mapAttendees[event.eventId]?.run {
                event.attendees = toMutableList()
                firstOrNull { it.isOrganizer != null && it.isOrganizer }?.let {
                    event.organizer = it
                } ?: run {
                    event.organizer?.let { event.attendees.add(it) }
                }

            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun addReminders(
        events: List<Event>,
        contentResolver: ContentResolver?
    ) {
        val reminders: MutableList<Reminder> = mutableListOf()
        val remindersQuery = "(${CalendarContract.Reminders.EVENT_ID} in (${
            events.map { it.eventId }.joinToString(", ")
        }))"
        val remindersCursor = contentResolver?.query(
            CalendarContract.Reminders.CONTENT_URI,
            REMINDER_PROJECTION,
            remindersQuery,
            null,
            null
        )
        remindersCursor.use { cursor ->
            if (cursor?.moveToFirst() == true) {
                do {
                    val reminder = parseReminderRow(remindersCursor) ?: continue
                    reminders.add(reminder)
                } while (cursor.moveToNext())
            }
        }
        val mapReminders = reminders.groupBy { it.eventId }
        for (event in events) {
            mapReminders[event.eventId]?.run {
                event.reminders = this.toMutableList()
            }
        }
    }

    @Synchronized
    private fun generateUniqueRequestCodeAndCacheParameters(parameters: CalendarMethodsParametersCacheModel): Int {
        // TODO we can ran out of Int's at some point so this probably should re-use some of the freed ones
        val uniqueRequestCode: Int = (_cachedParametersMap.keys.maxOrNull() ?: 0) + 1
        parameters.ownCacheKey = uniqueRequestCode
        _cachedParametersMap[uniqueRequestCode] = parameters

        return uniqueRequestCode
    }

    private fun <T> finishWithSuccess(
        result: T,
        isAsync: Boolean,
        pendingChannelResult: MethodChannel.Result
    ) {
        uiThreadHandler.maybeAsync(isAsync) {
            pendingChannelResult.success(result)
            clearCachedParameters(pendingChannelResult)
        }
    }

    private fun finishWithError(
        errorCode: String,
        errorMessage: String?,
        isAsync: Boolean,
        pendingChannelResult: MethodChannel.Result
    ) {
        uiThreadHandler.maybeAsync(isAsync) {
            pendingChannelResult.error(errorCode, errorMessage, null)
            clearCachedParameters(pendingChannelResult)
        }
    }

    private fun clearCachedParameters(pendingChannelResult: MethodChannel.Result) {
        val cachedParameters =
            _cachedParametersMap.values.filter { it.pendingChannelResult == pendingChannelResult }
                .toList()
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
        rr.weekStart = recurrenceRule.weekStart?.weekday() ?: Weekday.MO
        if (recurrenceRule.interval != null) {
            rr.interval = recurrenceRule.interval!!
        }

        if (recurrenceRule.recurrenceFrequency == RecurrenceFrequency.WEEKLY ||
            recurrenceRule.weekOfMonth != null && (recurrenceRule.recurrenceFrequency == RecurrenceFrequency.MONTHLY || recurrenceRule.recurrenceFrequency == RecurrenceFrequency.YEARLY)
        ) {
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

        if (recurrenceRule.weekOfMonth == null && recurrenceRule.monthOfYear?.isNotEmpty() == true && recurrenceRule.recurrenceFrequency == RecurrenceFrequency.YEARLY) {
            rrString = rrString.addPartWithValues(BYMONTH_PART, recurrenceRule.monthOfYear)
        }

        if (recurrenceRule.weekOfMonth == null && recurrenceRule.dayOfMonth?.isNotEmpty() == true && (recurrenceRule.recurrenceFrequency == RecurrenceFrequency.MONTHLY || recurrenceRule.recurrenceFrequency == RecurrenceFrequency.YEARLY)) {
            rrString = rrString.addPartWithValues(BYMONTHDAY_PART, recurrenceRule.dayOfMonth)
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
            org.dmfs.rfc5545.recur.RecurrenceRule.WeekdayNum(recurrenceRule.weekOfMonth ?: 0, it)
        }
    }

    private fun String.addPartWithValues(partName: String, values: Int?): String {
        if (values != null) {
            return this + PART_TEMPLATE.format(partName) + values
        }

        return this
    }

    private fun String.addPartWithValues(partName: String, values: List<Int>?): String {
        if (values != null) {
            return this + PART_TEMPLATE.format(partName) + values.joinToString(",")
        }

        return this
    }

    private fun parseAvailability(availability: Int): Availability? = when (availability) {
        Events.AVAILABILITY_BUSY -> Availability.BUSY
        Events.AVAILABILITY_FREE -> Availability.FREE
        Events.AVAILABILITY_TENTATIVE -> Availability.TENTATIVE
        else -> null
    }
}


fun Handler.maybeAsync(isAsync: Boolean, run: Runnable) {
    if (isAsync) {
        post(run)
    } else {
        run.run()
    }
}

fun CoroutineScope.maybeLaunch(
    isAsync: Boolean,
    context: CoroutineContext = EmptyCoroutineContext,
    isNeedJob: Boolean = false,
    start: CoroutineStart = CoroutineStart.DEFAULT,
    block: CoroutineScope.() -> Unit
): Job? {
    return if (isAsync) {
        launch(Dispatchers.IO + context, start, block)
    } else {
        if (isNeedJob) launch(Dispatchers.Main + context, start, block) else {
            block()
            null
        }
    }
}

fun DayOfWeek.weekday(): Weekday {
    when (this) {
        DayOfWeek.SUNDAY -> return Weekday.SU
        DayOfWeek.MONDAY -> return Weekday.MO
        DayOfWeek.TUESDAY -> return Weekday.TU
        DayOfWeek.WEDNESDAY -> return Weekday.WE
        DayOfWeek.THURSDAY -> return Weekday.TH
        DayOfWeek.FRIDAY -> return Weekday.FR
        DayOfWeek.SATURDAY -> return Weekday.SA
    }
}

fun Weekday.dayOfWeek(): DayOfWeek {
    when (this) {
        Weekday.SU -> return DayOfWeek.SUNDAY
        Weekday.MO -> return DayOfWeek.MONDAY
        Weekday.TU -> return DayOfWeek.TUESDAY
        Weekday.WE -> return DayOfWeek.WEDNESDAY
        Weekday.TH -> return DayOfWeek.THURSDAY
        Weekday.FR -> return DayOfWeek.FRIDAY
        Weekday.SA -> return DayOfWeek.SATURDAY
    }
}