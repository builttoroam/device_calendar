package com.builttoroam.devicecalendar

import android.content.ContentResolver
import android.content.ContentValues
import android.content.Context
import android.database.MatrixCursor
import android.provider.CalendarContract
import androidx.test.core.app.ApplicationProvider
import com.builttoroam.devicecalendar.models.Attendee
import com.builttoroam.devicecalendar.models.Calendar
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.kotlin.any
import org.mockito.kotlin.argThat
import org.mockito.kotlin.eq
import org.mockito.kotlin.mock
import org.mockito.kotlin.never
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import com.builttoroam.devicecalendar.common.Constants.Companion as Cst

/**
 * Regression coverage for #572: `updateAttendees()` only wrote a changed
 * attendance status back to the Attendees table when the attendee being
 * updated was `calendar.ownerAccount`, so status changes for every other
 * attendee were silently dropped instead of being synced. Uses a mocked
 * ContentResolver (rather than a Robolectric ShadowContentResolver) since
 * what's under test is *which arguments* CalendarDelegate passes to
 * `update`, not real CalendarContract provider behavior.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CalendarDelegateAttendeeSyncTest {
    private lateinit var delegate: CalendarDelegate
    private lateinit var contentResolver: ContentResolver

    private val ownerEmail = "owner@example.com"
    private val guestEmail = "guest@example.com"
    private val eventId = 42L

    @Before
    fun setUp() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        delegate = CalendarDelegate(null, context)
        contentResolver = mock()
    }

    private fun invokeUpdateAttendees(calendar: Calendar, attendees: List<Attendee>) {
        val method = CalendarDelegate::class.java.declaredMethods
            .first { it.name == "updateAttendees" }
        method.isAccessible = true
        method.invoke(delegate, calendar, eventId, contentResolver, attendees)
    }

    private fun stubExistingAttendees(existing: List<Attendee>) {
        val cursor = MatrixCursor(Cst.ATTENDEE_PROJECTION)
        existing.forEachIndexed { index, attendee ->
            cursor.addRow(
                arrayOf<Any?>(
                    index.toLong(),
                    eventId,
                    attendee.name,
                    attendee.emailAddress,
                    attendee.role,
                    CalendarContract.Attendees.RELATIONSHIP_ATTENDEE,
                    attendee.attendanceStatus
                )
            )
        }
        whenever(
            contentResolver.query(
                eq(CalendarContract.Attendees.CONTENT_URI), any(), any(), eq(null), eq(null)
            )
        ).thenReturn(cursor)
    }

    private fun calendar() = Calendar(
        id = "1",
        name = "Test",
        color = 0,
        accountName = ownerEmail,
        accountType = CalendarContract.ACCOUNT_TYPE_LOCAL,
        ownerAccount = ownerEmail
    )

    private fun verifyStatusUpdateSent(forEmail: String, newStatus: Int) {
        verify(contentResolver).update(
            eq(CalendarContract.Attendees.CONTENT_URI),
            argThat<ContentValues> { getAsInteger(CalendarContract.Attendees.ATTENDEE_STATUS) == newStatus },
            any(),
            eq(arrayOf(eventId.toString(), forEmail))
        )
    }

    @Test
    fun UpdateAttendees_SelfAttendeeStatusChanged_CallsUpdateAttendeeStatus() {
        val existing = Attendee(ownerEmail, "Owner", 1, CalendarContract.Attendees.ATTENDEE_STATUS_TENTATIVE, false, true)
        val updated = Attendee(ownerEmail, "Owner", 1, CalendarContract.Attendees.ATTENDEE_STATUS_ACCEPTED, false, true)
        stubExistingAttendees(listOf(existing))

        invokeUpdateAttendees(calendar(), listOf(updated))

        verifyStatusUpdateSent(ownerEmail, CalendarContract.Attendees.ATTENDEE_STATUS_ACCEPTED)
    }

    @Test
    fun UpdateAttendees_NonSelfAttendeeStatusChanged_CallsUpdateAttendeeStatus() {
        // #572: guest is not calendar.ownerAccount -- must still sync.
        val existing = Attendee(guestEmail, "Guest", 1, CalendarContract.Attendees.ATTENDEE_STATUS_INVITED, false, false)
        val updated = Attendee(guestEmail, "Guest", 1, CalendarContract.Attendees.ATTENDEE_STATUS_DECLINED, false, false)
        stubExistingAttendees(listOf(existing))

        invokeUpdateAttendees(calendar(), listOf(updated))

        verifyStatusUpdateSent(guestEmail, CalendarContract.Attendees.ATTENDEE_STATUS_DECLINED)
    }

    @Test
    fun UpdateAttendees_StatusUnchanged_DoesNotCallUpdateAttendeeStatus() {
        val existing = Attendee(guestEmail, "Guest", 1, CalendarContract.Attendees.ATTENDEE_STATUS_ACCEPTED, false, false)
        val unchanged = Attendee(guestEmail, "Guest", 1, CalendarContract.Attendees.ATTENDEE_STATUS_ACCEPTED, false, false)
        stubExistingAttendees(listOf(existing))

        invokeUpdateAttendees(calendar(), listOf(unchanged))

        verify(contentResolver, never()).update(any(), any(), any(), any())
    }
}
