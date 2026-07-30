package com.builttoroam.devicecalendar

import android.content.ContentResolver
import android.content.Context
import android.database.Cursor
import android.database.MatrixCursor
import android.net.Uri
import android.provider.CalendarContract
import io.flutter.plugin.common.MethodChannel
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.kotlin.any
import org.mockito.kotlin.anyOrNull
import org.mockito.kotlin.mock
import org.mockito.kotlin.whenever
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import com.builttoroam.devicecalendar.common.Constants.Companion as Cst

/**
 * Regression coverage for #613: the `instanceCursor` opened by
 * `CalendarContract.Instances.query(...)` in `deleteEvent()` was only closed
 * *after* its `while (instanceCursor.moveToNext())` loop, so any exception
 * thrown mid-iteration (malformed row data, `CursorWindowAllocationException`
 * under memory pressure, etc.) skipped `close()` and leaked the cursor. Fixed
 * by wrapping the query in `.use { }`, matching the convention already used
 * elsewhere in this file (`retrieveAttendees`/`retrieveReminders`).
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CalendarDelegateCursorLeakTest {
    private lateinit var delegate: CalendarDelegate
    private lateinit var contentResolver: ContentResolver

    private val calendarId = 1L
    private val eventId = 42L

    /**
     * A cursor that throws part-way through iteration, and tracks whether close() ran.
     * `moveToNext()`/`close()` are final on `AbstractCursor` (MatrixCursor's base class), so
     * this wraps a real MatrixCursor via interface delegation instead of subclassing it.
     */
    private class ThrowingCursor(private val delegate: Cursor) : Cursor by delegate {
        var closeCalled = false
            private set
        private var moveToNextCallCount = 0

        override fun moveToNext(): Boolean {
            moveToNextCallCount++
            if (moveToNextCallCount == 2) {
                throw IllegalStateException("simulated malformed instance row")
            }
            return delegate.moveToNext()
        }

        override fun close() {
            closeCalled = true
            delegate.close()
        }
    }

    @Before
    fun setUp() {
        contentResolver = mock()
        val context: Context = mock()
        whenever(context.contentResolver).thenReturn(contentResolver)
        delegate = CalendarDelegate(null, context)
    }

    @Test
    fun DeleteEvent_InstanceCursorThrowsMidIteration_StillClosesCursor() {
        val calendarCursor = MatrixCursor(Cst.CALENDAR_PROJECTION).apply {
            addRow(
                arrayOf<Any?>(
                    calendarId,
                    "acct@example.com",
                    CalendarContract.ACCOUNT_TYPE_LOCAL,
                    "Test calendar",
                    "acct@example.com",
                    CalendarContract.Events.CAL_ACCESS_OWNER,
                    0,
                    "1"
                )
            )
        }
        val underlyingInstanceCursor = MatrixCursor(Cst.EVENT_INSTANCE_DELETION).apply {
            addRow(arrayOf<Any?>(eventId, "FREQ=DAILY", 0L, 1000L, 2000L))
            addRow(arrayOf<Any?>(eventId, "FREQ=DAILY", 0L, 3000L, 4000L))
        }
        val instanceCursor = ThrowingCursor(underlyingInstanceCursor)

        // Route the two distinct queries deleteEvent() makes (calendar lookup, then instance
        // lookup) by URI path, since both go through the same mocked ContentResolver.query().
        whenever(contentResolver.query(any(), any(), anyOrNull(), anyOrNull(), anyOrNull())).thenAnswer { invocation ->
            val uri = invocation.getArgument<Uri>(0)
            when {
                uri.toString().contains("/calendars/") -> calendarCursor
                uri.toString().contains("/instances/") -> instanceCursor
                else -> null
            }
        }

        val result: MethodChannel.Result = mock()

        try {
            delegate.deleteEvent(
                calendarId.toString(),
                eventId.toString(),
                result,
                startDate = 1000L,
                endDate = 5000L,
                followingInstances = false
            )
        } catch (e: Exception) {
            // Expected: the simulated malformed row propagates out of deleteEvent.
            // What matters for #613 is whether the cursor was closed on the way out.
        }

        assertTrue("instanceCursor.close() should be called even when iteration throws", instanceCursor.closeCalled)
    }
}
