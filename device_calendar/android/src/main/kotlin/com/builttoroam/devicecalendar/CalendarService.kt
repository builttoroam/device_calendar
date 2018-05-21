package com.builttoroam.devicecalendar

import android.Manifest
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
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION_ACCOUNT_NAME_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION_DISPLAY_NAME_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION_ID_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.CALENDAR_PROJECTION_OWNER_ACCOUNT_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_DESCRIPTION_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_ID_INDEX
import com.builttoroam.devicecalendar.common.Constants.Companion.EVENT_PROJECTION_TITLE_INDEX
import com.builttoroam.devicecalendar.common.ErrorCodes.Companion.CALENDAR_RETRIEVAL_FAILURE
import com.builttoroam.devicecalendar.common.ErrorCodes.Companion.EXCEPTION
import com.builttoroam.devicecalendar.common.ErrorCodes.Companion.INVALID_ARGUMENT
import com.builttoroam.devicecalendar.common.ErrorMessages.Companion.CALENDAR_ID_INVALID_ARGUMENT_MESSAGE
import com.builttoroam.devicecalendar.models.Calendar
import com.builttoroam.devicecalendar.models.Event
import io.flutter.plugin.common.MethodChannel
import com.google.gson.Gson


public class CalendarService : PluginRegistry.RequestPermissionsResultListener {

    private val REQUEST_CODE_RETRIEVE_CALENDARS = 0

    private var _activity: Activity? = null;
    private var _context: Context? = null;
    private var _channelResult: MethodChannel.Result? = null;
    private var _gson: Gson? = null;

    public constructor(activity: Activity, context: Context) {
        _activity = activity;
        _context = context;
        _gson = Gson();
    }

    public override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray): Boolean {
        val permissionGranted = grantResults.isNotEmpty() && grantResults[0] === PackageManager.PERMISSION_GRANTED

        if (requestCode === REQUEST_CODE_RETRIEVE_CALENDARS) {
            if (permissionGranted) {
                retrieveCalendars();
            } else {
                finishWithSuccess()
            }
            return true
        }

        return false
    }

    public fun setPendingResult(channelResult: MethodChannel.Result) {
        _channelResult = channelResult;
    }

    public fun retrieveCalendars() {
        if (ensurePermissionsGranted()) {

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

                _channelResult?.success(_gson?.toJson(calendars));
            } catch (e: Exception) {
                _channelResult?.error(EXCEPTION, e.message, null);
                println(e.message);
            } finally {
                cursor?.close();
            }
        }

        return;
    }

    public fun retrieveCelandar(calendarId: String): Calendar? {
        if (ensurePermissionsGranted()) {

            val calendarIdNumber = calendarId?.toLongOrNull();
            if (calendarIdNumber == null) {
                _channelResult?.error(INVALID_ARGUMENT, CALENDAR_ID_INVALID_ARGUMENT_MESSAGE, null);
                return null;
            }

            val contentResolver: ContentResolver? = _context?.getContentResolver();
            val uri: Uri = CalendarContract.Calendars.CONTENT_URI;
            val cursor: Cursor? = contentResolver?.query(ContentUris.withAppendedId(uri, calendarIdNumber), CALENDAR_PROJECTION, null, null, null);

            try {
                if (cursor?.moveToFirst() ?: false) {
                    val calendar = parseCalendar(cursor);
                    return calendar;
                } else {

                }
            } catch (e: Exception) {
                println(e.message);
            } finally {
                cursor?.close();
            }

        }

        return null;
    }


    public fun retrieveEvents(calendarId: String) {
        if (ensurePermissionsGranted()) {
            val calendar = retrieveCelandar(calendarId);
            if (calendar == null) {
                _channelResult?.error(CALENDAR_RETRIEVAL_FAILURE, "Couldn't retrieve the Calendar with ID ${calendarId}", null);
                return;
            }
            val contentResolver: ContentResolver? = _context?.getContentResolver();
            var eventsUriBuilder = CalendarContract.Events.CONTENT_URI.buildUpon();

            // TODO add start & end date

            var eventsUri = eventsUriBuilder.build();
            var eventsSelectionQuery = "${CalendarContract.Events.CALENDAR_ID} = ${calendarId}";
            var cursor = contentResolver?.query(eventsUri, EVENT_PROJECTION, eventsSelectionQuery, null, CalendarContract.Events.DTSTART + " ASC");

            try {

                val events: MutableList<Event> = mutableListOf<Event>();
                while (cursor?.moveToNext() ?: false) {

                    val event = parseEvent(cursor);
                    if (event == null) {
                        continue;
                    }

                    events.add(event);
                }

                _channelResult?.success(_gson?.toJson(events));
            } catch (e: Exception) {
                _channelResult?.error(EXCEPTION, e.message, null);
                println(e.message);
            } finally {
                cursor?.close();
            }

        }

        return;
    }

    private fun ensurePermissionsGranted(): Boolean {

        if (atLeastAPI(23)) {
            val writeCalendarPermissionGranted = _activity?.checkSelfPermission(Manifest.permission.WRITE_CALENDAR) == PackageManager.PERMISSION_GRANTED;
            val readCalendarPermissionGranted = _activity?.checkSelfPermission(Manifest.permission.READ_CALENDAR) == PackageManager.PERMISSION_GRANTED;
            if (!writeCalendarPermissionGranted || !readCalendarPermissionGranted) {
                _activity?.requestPermissions(arrayOf(Manifest.permission.WRITE_CALENDAR, Manifest.permission.READ_CALENDAR), REQUEST_CODE_RETRIEVE_CALENDARS);
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
        val accountName = cursor.getString(CALENDAR_PROJECTION_ACCOUNT_NAME_INDEX);
        val ownerName = cursor.getString(CALENDAR_PROJECTION_OWNER_ACCOUNT_INDEX);

        return Calendar(calId.toString(), displayName);
    }

    private fun parseEvent(cursor: Cursor?): Event? {
        if (cursor == null) {
            return null;
        }

        val eventId = cursor.getString(EVENT_PROJECTION_ID_INDEX);
        val title = cursor.getString(EVENT_PROJECTION_TITLE_INDEX);
        val description = cursor.getString(EVENT_PROJECTION_DESCRIPTION_INDEX);

        return Event(eventId.toString(), title);
    }

    private fun finishWithSuccess() {
        _channelResult?.success(null);
        clearChannelResult();
    }

    private fun clearChannelResult() {

        _channelResult = null;
    }

    private fun atLeastAPI(api: Int): Boolean {
        return api <= android.os.Build.VERSION.SDK_INT
    }
}