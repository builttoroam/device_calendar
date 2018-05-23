package com.builttoroam.devicecalendar

import android.Manifest
import android.annotation.SuppressLint
import io.flutter.plugin.common.PluginRegistry;
import android.content.pm.PackageManager
import android.app.Activity
import android.content.ContentResolver
import android.content.ContentUris
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.provider.CalendarContract
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION_ACCESS_LEVEL_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION_ACCOUNT_NAME_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION_DISPLAY_NAME_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION_ID_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION_OWNER_ACCOUNT_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_DESCRIPTION_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_ID_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_TITLE_INDEX
import com.builttoroam.devicecalendar.common.ErrorCodes.Companion.CALENDAR_IS_READ_ONLY
import com.builttoroam.devicecalendar.common.ErrorCodes.Companion.CALENDAR_RETRIEVAL_FAILURE
import com.builttoroam.devicecalendar.common.ErrorCodes.Companion.EXCEPTION
import com.builttoroam.devicecalendar.common.ErrorCodes.Companion.INVALID_ARGUMENT
import com.builttoroam.devicecalendar.common.ErrorMessages.Companion.CALENDAR_ID_INVALID_ARGUMENT_NOT_A_NUMBER_MESSAGE
import com.builttoroam.devicecalendar.models.Calendar
import com.builttoroam.devicecalendar.models.Event
import io.flutter.plugin.common.MethodChannel
import com.google.gson.Gson
import android.provider.CalendarContract.Events
import android.content.ContentValues
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_END_DATE_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_START_DATE_INDEX
import com.builttoroam.devicecalendar.common.ErrorCodes.Companion.EVENTS_RETRIEVAL_FAILURE
import com.builttoroam.devicecalendar.common.ErrorCodes.Companion.EVENT_CREATION_FAILURE
import com.builttoroam.devicecalendar.common.ErrorMessages.Companion.CREATE_EVENT_ARGUMENTS_NOT_VALID_MESSAGE
import com.builttoroam.devicecalendar.common.ErrorMessages.Companion.EVENTS_START_DATE_LARGER_THAN_END_DATE_MESSAGE
import java.util.*


public class CalendarService : PluginRegistry.RequestPermissionsResultListener {

    private val REQUEST_CODE_RETRIEVE_CALENDARS = 0;
    private val REQUEST_CODE_RETRIEVE_EVENTS = REQUEST_CODE_RETRIEVE_CALENDARS + 1;
    private val REQUEST_CODE_RETRIEVE_CALENDAR = REQUEST_CODE_RETRIEVE_EVENTS + 1;
    private val REQUEST_CODE_CREATE_EVENT = REQUEST_CODE_RETRIEVE_CALENDAR + 1;
    private val REQUEST_CODE_DELETE_EVENT = REQUEST_CODE_CREATE_EVENT + 1;

    private var _activity: Activity? = null;
    private var _context: Context? = null;
    private var _channelResult: MethodChannel.Result? = null;
    private var _gson: Gson? = null;

    // TODO MK Rethink this approach of 'caching' values between getting the permissions and running the calendar function again
    //         The issue with this approach is that it will fail when there's multiple calls handled at the same time
    private var _calendarId: String = "";
    private var _calendarEventsStartDate: Long = -1;
    private var _calendarEventsEndDate: Long = -1;
    private var _eventId: String = "";

    private var _event: Event? = null;

    public constructor(activity: Activity, context: Context) {
        _activity = activity;
        _context = context;
        _gson = Gson();
    }

    public override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray): Boolean {
        val permissionGranted = grantResults.isNotEmpty() && grantResults[0] === PackageManager.PERMISSION_GRANTED

        when (requestCode) {
            REQUEST_CODE_RETRIEVE_CALENDARS -> {
                if (permissionGranted) {
                    retrieveCalendars();
                } else {
                    finishWithSuccess(null);
                }
                return true;
            }
            REQUEST_CODE_RETRIEVE_EVENTS -> {
                if (permissionGranted) {
                    retrieveEvents(_calendarId, _calendarEventsStartDate, _calendarEventsEndDate);
                } else {
                    finishWithSuccess(null);
                }
                return true;
            }
            REQUEST_CODE_RETRIEVE_CALENDAR -> {
                if (permissionGranted) {
                    retrieveCalendar(_calendarId);
                } else {
                    finishWithSuccess(null);
                }
                return true;
            }
            REQUEST_CODE_CREATE_EVENT -> {
                if (permissionGranted) {
                    createEvent(_calendarId, _event);
                } else {
                    finishWithSuccess(null);
                }
                return true;
            }
            REQUEST_CODE_DELETE_EVENT -> {
                if (permissionGranted) {
                    deleteEvent(_eventId, _calendarId);
                } else {
                    finishWithSuccess(null);
                }
                return true;
            }
        }

        return false
    }

    public fun setPendingResult(channelResult: MethodChannel.Result) {
        _channelResult = channelResult;
    }

    @SuppressLint("MissingPermission")
    public fun retrieveCalendars() {
        if (ensurePermissionsGranted(REQUEST_CODE_RETRIEVE_CALENDARS)) {

            val contentResolver: ContentResolver? = _context?.getContentResolver();
            val uri: Uri = CalendarContract.Calendars.CONTENT_URI;
            val cursor: Cursor? = contentResolver?.query(uri, CALENDAR_PROJECTION, null, null, null);

            val calendars: MutableList<Calendar> = mutableListOf<Calendar>();

            try {
                while (cursor?.moveToNext() ?: false) {

                    val calendar = parseCalendar(cursor);
                    if (calendar == null) {
                        continue;
                    }
                    calendars.add(calendar);
                }

                finishWithSuccess(_gson?.toJson(calendars));
            } catch (e: Exception) {
                finishWithError(EXCEPTION, e.message);
                println(e.message);
            } finally {
                cursor?.close();
            }
        }

        return;
    }

    public fun retrieveCalendar(calendarId: String, isInternalCall: Boolean = false): Calendar? {
        _calendarId = calendarId;
        if (isInternalCall || ensurePermissionsGranted(REQUEST_CODE_RETRIEVE_CALENDAR)) {
            val calendarIdNumber = calendarId?.toLongOrNull();
            if (calendarIdNumber == null) {
                if (!isInternalCall) {
                    finishWithError(INVALID_ARGUMENT, CALENDAR_ID_INVALID_ARGUMENT_NOT_A_NUMBER_MESSAGE);
                }
                return null;
            }

            val contentResolver: ContentResolver? = _context?.getContentResolver();
            val uri: Uri = CalendarContract.Calendars.CONTENT_URI;
            val cursor: Cursor? = contentResolver?.query(ContentUris.withAppendedId(uri, calendarIdNumber), CALENDAR_PROJECTION, null, null, null);

            try {
                if (cursor?.moveToFirst() ?: false) {
                    val calendar = parseCalendar(cursor);
                    if (isInternalCall) {
                        return calendar;
                    } else {
                        finishWithSuccess(_gson?.toJson(calendar));
                    }
                } else {
                    if (!isInternalCall) {
                        finishWithError(CALENDAR_RETRIEVAL_FAILURE, "Couldn't retrieve the Calendar with ID ${calendarId}");
                    }
                }
            } catch (e: Exception) {
                println(e.message);
            } finally {
                cursor?.close();
            }
        }

        return null;
    }

    public fun retrieveEvents(calendarId: String, startDate: Long, endDate: Long) {
        _calendarId = calendarId;
        _calendarEventsStartDate = startDate;
        _calendarEventsEndDate = endDate;
        if (ensurePermissionsGranted(REQUEST_CODE_RETRIEVE_EVENTS)) {
            val calendar = retrieveCalendar(calendarId, true);
            if (calendar == null) {
                finishWithError(CALENDAR_RETRIEVAL_FAILURE, "Couldn't retrieve the Calendar with ID ${calendarId}");
                return;
            }
            if (startDate > endDate) {
                finishWithError(EVENTS_RETRIEVAL_FAILURE, EVENTS_START_DATE_LARGER_THAN_END_DATE_MESSAGE);
                return;
            }

            val contentResolver: ContentResolver? = _context?.getContentResolver();
            var eventsUriBuilder = CalendarContract.Events.CONTENT_URI.buildUpon();

            var eventsUri = eventsUriBuilder.build();
            var eventsSelectionQuery = "(${CalendarContract.Events.CALENDAR_ID} = ${calendarId}) AND " +
                    "(${CalendarContract.Instances.DTSTART} >= ${startDate}) AND " +
                    "(${CalendarContract.Instances.DTEND} <= ${endDate}) AND " +
                    "(${CalendarContract.Events.DELETED} != 1)";
            var cursor = contentResolver?.query(eventsUri, EVENT_PROJECTION, eventsSelectionQuery, null, CalendarContract.Events.DTSTART + " ASC");

            val events: MutableList<Event> = mutableListOf<Event>();

            try {
                if (cursor?.moveToFirst() ?: false) {
                    do {
                        val event = parseEvent(cursor);
                        if (event == null) {
                            continue;
                        }

                        events.add(event);

                    } while (cursor?.moveToNext() ?: false);

                }
            } catch (e: Exception) {
                finishWithError(EXCEPTION, e.message);
                println(e.message);
            } finally {
                cursor?.close();
            }

            finishWithSuccess(_gson?.toJson(events));

        }

        return;
    }

    @SuppressLint("MissingPermission")
    public fun createEvent(calendarId: String, event: Event?) {
        _calendarId = calendarId;
        _event = event;
        if (ensurePermissionsGranted(REQUEST_CODE_CREATE_EVENT)) {
            if (event == null) {
                finishWithError(EVENT_CREATION_FAILURE, CREATE_EVENT_ARGUMENTS_NOT_VALID_MESSAGE);
                return;
            }

            val contentResolver: ContentResolver? = _context?.getContentResolver();
            val values = ContentValues();
            values.put(Events.DTSTART, event.start);
            values.put(Events.DTEND, event.end);
            values.put(Events.TITLE, event.title);
            values.put(Events.DESCRIPTION, event.description);
            values.put(Events.CALENDAR_ID, calendarId);

            // MK using current device time zone
            val calendar: java.util.Calendar = java.util.Calendar.getInstance();
            val currentTimeZone: TimeZone = calendar.timeZone;
            values.put(Events.EVENT_TIMEZONE, currentTimeZone.displayName);

            try {
                val uri = contentResolver?.insert(CalendarContract.Events.CONTENT_URI, values);

                // get the event ID that is the last element in the Uri
                val eventID = java.lang.Long.parseLong(uri?.getLastPathSegment());

                finishWithSuccess(eventID.toString());
            } catch (e: Exception) {
                finishWithError(EXCEPTION, e.message);
                println(e.message);
            } finally {
            }
        }
    }

    public fun deleteEvent(calendarId: String, eventId: String) {
        _eventId = eventId;
        _calendarId = calendarId;
        if (ensurePermissionsGranted(REQUEST_CODE_DELETE_EVENT)) {
            var existingCal = retrieveCalendar(calendarId, true);
            if (existingCal == null) {
                finishWithError(CALENDAR_RETRIEVAL_FAILURE, "Couldn't retrieve the Calendar with ID ${calendarId}");
                return;
            }

            if (existingCal.isReadyOnly) {
                finishWithError(CALENDAR_IS_READ_ONLY, "Calendar with ID ${calendarId} is read only");
                return;
            }

            // TODO handle recurring events

            val eventIdNumber = eventId.toLongOrNull();
            if (eventIdNumber == null) {
                finishWithError(INVALID_ARGUMENT, CALENDAR_ID_INVALID_ARGUMENT_NOT_A_NUMBER_MESSAGE);
                return;
            }

            val eventsUriWithId = ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, eventIdNumber);
            val contentResolver: ContentResolver? = _context?.getContentResolver();
            contentResolver?.notifyChange(eventsUriWithId, null);
            val deleteSucceeded = contentResolver?.delete(eventsUriWithId, null, null) ?: 0;

            finishWithSuccess(deleteSucceeded > 0);
        }
    }

    private fun ensurePermissionsGranted(requestCode: Int): Boolean {

        if (atLeastAPI(23)) {
            val writeCalendarPermissionGranted = _activity?.checkSelfPermission(Manifest.permission.WRITE_CALENDAR) == PackageManager.PERMISSION_GRANTED;
            val readCalendarPermissionGranted = _activity?.checkSelfPermission(Manifest.permission.READ_CALENDAR) == PackageManager.PERMISSION_GRANTED;
            if (!writeCalendarPermissionGranted || !readCalendarPermissionGranted) {
                _activity?.requestPermissions(arrayOf(Manifest.permission.WRITE_CALENDAR, Manifest.permission.READ_CALENDAR), requestCode);
                return false;
            }
        }

        return true;
    }

    private fun parseCalendar(cursor: Cursor?): Calendar? {
        if (cursor == null) {
            return null;
        }

        val calId = cursor.getLong(CALENDAR_PROJECTION_ID_INDEX);
        val displayName = cursor.getString(CALENDAR_PROJECTION_DISPLAY_NAME_INDEX);
        val accessLevel = cursor.getInt(CALENDAR_PROJECTION_ACCESS_LEVEL_INDEX);
        val accountName = cursor.getString(CALENDAR_PROJECTION_ACCOUNT_NAME_INDEX);
        val ownerName = cursor.getString(CALENDAR_PROJECTION_OWNER_ACCOUNT_INDEX);

        val calendar = Calendar(calId.toString(), displayName);
        calendar.isReadyOnly = isCalendarReadOnly(accessLevel);

        return calendar;
    }

    private fun parseEvent(cursor: Cursor?): Event? {
        if (cursor == null) {
            return null;
        }

        val eventId = cursor.getString(EVENT_PROJECTION_ID_INDEX);
        val title = cursor.getString(EVENT_PROJECTION_TITLE_INDEX);
        val description = cursor.getString(EVENT_PROJECTION_DESCRIPTION_INDEX);
        val startDate = cursor.getLong(EVENT_PROJECTION_START_DATE_INDEX);
        val endDate = cursor.getLong(EVENT_PROJECTION_END_DATE_INDEX);

        val event = Event(title);
        event.id = eventId.toString();
        event.description = description;
        event.start = startDate;
        event.end = endDate;

        return event;
    }

    private fun isCalendarReadOnly(accessLevel: Int): Boolean {
        when (accessLevel) {
            CalendarContract.Events.CAL_ACCESS_CONTRIBUTOR,
            CalendarContract.Events.CAL_ACCESS_ROOT,
            CalendarContract.Events.CAL_ACCESS_OWNER,
            CalendarContract.Events.CAL_ACCESS_EDITOR
            -> return false;
            else -> return true;
        }
    }

    private fun <T> finishWithSuccess(result: T) {
        _channelResult?.success(result);
        clearChannelResult();
    }

    private fun finishWithError(errorCode: String, errorMessage: String?) {
        _channelResult?.error(errorCode, errorMessage, null);
        clearChannelResult();
    }

    private fun clearChannelResult() {
        _channelResult = null;
    }

    private fun atLeastAPI(api: Int): Boolean {
        return api <= android.os.Build.VERSION.SDK_INT
    }
}