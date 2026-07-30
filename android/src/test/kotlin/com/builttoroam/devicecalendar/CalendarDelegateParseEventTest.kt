package com.builttoroam.devicecalendar

import android.content.Context
import android.database.MatrixCursor
import android.provider.CalendarContract.Events
import androidx.test.core.app.ApplicationProvider
import com.builttoroam.devicecalendar.models.Event
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import com.builttoroam.devicecalendar.common.Constants.Companion as Cst

/**
 * Regression coverage for #509: expose the calendar provider's stable
 * sync-adapter identifier (`CalendarContract.Events._SYNC_ID`) on the parsed
 * [Event], distinct from `eventId` (a local provider row id that can change
 * if the event gets re-synced/recreated). Verifies `parseEvent` reads the
 * `_SYNC_ID` projection column added to `Cst.EVENT_PROJECTION` into
 * `Event.syncId`, and that it's left null when the cursor has no value for
 * it (e.g. a local-only, never-synced event).
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CalendarDelegateParseEventTest {
    private lateinit var delegate: CalendarDelegate

    @Before
    fun setUp() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        delegate = CalendarDelegate(null, context)
    }

    private fun parseEvent(calendarId: String, cursor: android.database.Cursor?): Event? {
        val method = CalendarDelegate::class.java.declaredMethods
            .first { it.name == "parseEvent" }
        method.isAccessible = true
        return method.invoke(delegate, calendarId, cursor) as Event?
    }

    // Builds a MatrixCursor with one row over Cst.EVENT_PROJECTION, in
    // column order, so every EVENT_PROJECTION_*_INDEX constant lines up with
    // a real value the way a live CalendarContract.Events query would.
    private fun buildRow(syncId: String?): MatrixCursor {
        val cursor = MatrixCursor(Cst.EVENT_PROJECTION)
        cursor.addRow(
            arrayOf<Any?>(
                1L, // _ID
                "Title", // TITLE
                "Description", // DESCRIPTION
                1000L, // BEGIN
                2000L, // END
                null, // DURATION (unused by parseEvent)
                null, // RDATE (unused by parseEvent)
                null, // RRULE
                0, // ALL_DAY
                "Location", // EVENT_LOCATION
                null, // CUSTOM_APP_URI
                "UTC", // EVENT_TIMEZONE
                "UTC", // EVENT_END_TIMEZONE
                Events.AVAILABILITY_BUSY, // AVAILABILITY
                Events.STATUS_CONFIRMED, // STATUS
                0, // EVENT_COLOR
                0, // EVENT_COLOR_KEY
                syncId // _SYNC_ID
            )
        )
        cursor.moveToFirst()
        return cursor
    }

    @Test
    fun ParseEvent_SyncIdPresentInCursor_IsSetOnEvent() {
        val cursor = buildRow(syncId = "provider-sync-id-123")
        val event = parseEvent("1", cursor)
        assertEquals("provider-sync-id-123", event?.syncId)
    }

    @Test
    fun ParseEvent_SyncIdNullInCursor_IsNullOnEvent() {
        // Local-only calendars (never synced to any account) have no
        // _SYNC_ID -- must not crash and must come back null, not a bogus
        // default.
        val cursor = buildRow(syncId = null)
        val event = parseEvent("1", cursor)
        assertNull(event?.syncId)
    }
}
