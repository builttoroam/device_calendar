package com.builttoroam.devicecalendar

import android.Manifest
import io.flutter.plugin.common.PluginRegistry;
import android.content.pm.PackageManager
import android.app.Activity
import android.content.ContentResolver
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.provider.CalendarContract
import com.builttoroam.devicecalendar.models.Calendar
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
            val selection: String = ("((" + CalendarContract.Calendars.ACCOUNT_NAME + " = ?) AND ("
                    + CalendarContract.Calendars.ACCOUNT_TYPE + " = ?) AND ("
                    + CalendarContract.Calendars.OWNER_ACCOUNT + " = ?))");
            val cursor: Cursor? = contentResolver?.query(uri, EVENT_PROJECTION, null, null, null);

            val calendars: MutableList<Calendar> = mutableListOf<Calendar>();

            while (cursor != null && cursor.moveToNext()) {
                // Get the field values
                val calID = cursor.getLong(PROJECTION_ID_INDEX);
                val displayName = cursor.getString(PROJECTION_DISPLAY_NAME_INDEX);
                val accountName = cursor.getString(PROJECTION_ACCOUNT_NAME_INDEX);
                val ownerName = cursor.getString(PROJECTION_OWNER_ACCOUNT_INDEX);

                calendars.add(Calendar(calID.toString(), displayName));
            }

            _channelResult?.success(_gson?.toJson(calendars));
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