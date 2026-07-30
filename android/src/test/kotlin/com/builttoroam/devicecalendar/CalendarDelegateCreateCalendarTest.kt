package com.builttoroam.devicecalendar

import android.content.ContentResolver
import android.content.Context
import io.flutter.plugin.common.MethodChannel
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.kotlin.any
import org.mockito.kotlin.anyOrNull
import org.mockito.kotlin.argumentCaptor
import org.mockito.kotlin.mock
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Regression coverage for #216: `createCalendar()` force-unwrapped
 * `contentResolver?.insert(...)?.lastPathSegment!!` to get the new
 * calendar's ID. On some OEM calendar-provider implementations `insert()`
 * rejects the row and returns `null` instead of throwing, which crashed the
 * whole call with an NPE instead of surfacing a clean plugin error. Fixed by
 * null-checking the returned Uri's `lastPathSegment` and routing to
 * `finishWithError` (matching every other failure path in this file) when
 * it's missing.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CalendarDelegateCreateCalendarTest {
    private lateinit var delegate: CalendarDelegate
    private lateinit var contentResolver: ContentResolver

    @Before
    fun setUp() {
        contentResolver = mock()
        val context: Context = mock()
        whenever(context.contentResolver).thenReturn(contentResolver)
        delegate = CalendarDelegate(null, context)
    }

    @Test
    fun CreateCalendar_InsertReturnsNull_FinishesWithErrorInsteadOfCrashing() {
        whenever(contentResolver.insert(any(), any())).thenReturn(null)
        val result: MethodChannel.Result = mock()

        delegate.createCalendar("Test calendar", "0xFFFF0000", "acct@example.com", result)

        val errorCodeCaptor = argumentCaptor<String>()
        verify(result).error(errorCodeCaptor.capture(), any(), anyOrNull())
        assertEquals("500", errorCodeCaptor.firstValue)
    }
}
