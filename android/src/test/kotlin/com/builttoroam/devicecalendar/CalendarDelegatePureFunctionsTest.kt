package com.builttoroam.devicecalendar

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.builttoroam.devicecalendar.models.Availability
import com.builttoroam.devicecalendar.models.EventStatus
import com.builttoroam.devicecalendar.models.RecurrenceRule
import org.dmfs.rfc5545.recur.Freq
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.util.TimeZone

/**
 * TESTING_PLAN.md section 2, "pure/near-pure functions" list. These are all
 * `private` instance methods of CalendarDelegate, so they're invoked via
 * reflection rather than a production visibility change -- see
 * [invokePrivate]. A CalendarDelegate instance still needs a real Context
 * (constructor requirement), which is why this runs under Robolectric
 * rather than plain JUnit even though none of these specific functions
 * touch ContentResolver/Cursor.
 */
// compileSdk (36) requires Java 21 for Robolectric's sandbox; this
// environment only has Java 17, so pin the simulated SDK to 34 (Android 14),
// which Robolectric supports on Java 17. None of these tests touch
// SDK-36-specific behavior.
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CalendarDelegatePureFunctionsTest {
    private lateinit var delegate: CalendarDelegate

    @Before
    fun setUp() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        delegate = CalendarDelegate(null, context)
    }

    private fun <T> invokePrivate(name: String, vararg args: Any?): T {
        val method = CalendarDelegate::class.java.declaredMethods
            .first { it.name == name && it.parameterCount == args.size }
        method.isAccessible = true
        @Suppress("UNCHECKED_CAST")
        return method.invoke(delegate, *args) as T
    }

    private fun buildDurationString(startMillis: Long, endMillis: Long): String? =
        invokePrivate("buildDurationString", startMillis, endMillis)

    private fun buildRecurrenceRuleParams(rule: RecurrenceRule): String? =
        invokePrivate("buildRecurrenceRuleParams", rule)

    private fun getAvailability(availability: Availability?): Int? =
        invokePrivate("getAvailability", availability)

    private fun getEventStatus(eventStatus: EventStatus?): Int? =
        invokePrivate("getEventStatus", eventStatus)

    private fun getTimeZone(timeZoneString: String?): TimeZone =
        invokePrivate("getTimeZone", timeZoneString)

    private fun parseRecurrenceRuleString(recurrenceRuleString: String?): RecurrenceRule? =
        invokePrivate("parseRecurrenceRuleString", recurrenceRuleString)

    // ---- buildDurationString ----

    @Test
    fun buildDurationString_ZeroDuration_ReturnsNull() {
        assertNull(buildDurationString(0L, 0L))
    }

    @Test
    fun buildDurationString_ExactlyOneDay_ReturnsP1D() {
        assertEquals("P1D", buildDurationString(0L, 24 * 60 * 60 * 1000L))
    }

    @Test
    fun buildDurationString_ExactlyOneHour_ReturnsPT1H() {
        assertEquals("PT1H", buildDurationString(0L, 60 * 60 * 1000L))
    }

    @Test
    fun buildDurationString_ExactlyOneSecond_ReturnsPT1S() {
        assertEquals("PT1S", buildDurationString(0L, 1000L))
    }

    @Test
    fun buildDurationString_Mixed_ReturnsAllComponents() {
        val millis =
            (1 * 24 * 60 * 60 * 1000L) + (2 * 60 * 60 * 1000L) + (3 * 60 * 1000L) + (4 * 1000L)
        assertEquals("P1DT2H3M4S", buildDurationString(0L, millis))
    }

    @Test
    fun buildDurationString_JustUnderOneDay_OmitsDayComponent() {
        // The 0-vs-1 boundary this function branches on: 23h59m59s must not
        // round up into a "D" component.
        val millis = (23 * 60 * 60 * 1000L) + (59 * 60 * 1000L) + (59 * 1000L)
        assertEquals("PT23H59M59S", buildDurationString(0L, millis))
    }

    // ---- getAvailability / getEventStatus ----
    // Note: Kotlin's Availability/EventStatus enums (models/Availability.kt,
    // models/EventStatus.kt) only have BUSY/FREE/TENTATIVE and
    // CONFIRMED/CANCELED/TENTATIVE respectively -- there's no UNAVAILABLE or
    // NONE case to pass in here, so those can't be exercised at this
    // function. The actual null-safety fix TESTING_PLAN.md describes lives
    // one layer up, in DeviceCalendarPlugin.parseAvailability/
    // parseEventStatus, which intercepts the "UNAVAILABLE"/"NONE" strings
    // before calling `Availability.valueOf()`/`EventStatus.valueOf()` --
    // otherwise those would throw IllegalArgumentException, since the
    // Kotlin enums have no matching constant. See
    // DeviceCalendarPluginParseTest.kt for that regression test.

    @Test
    fun getAvailability_Busy_ReturnsBusyConstant() {
        assertEquals(android.provider.CalendarContract.Events.AVAILABILITY_BUSY,
            getAvailability(Availability.BUSY))
    }

    @Test
    fun getAvailability_Free_ReturnsFreeConstant() {
        assertEquals(android.provider.CalendarContract.Events.AVAILABILITY_FREE,
            getAvailability(Availability.FREE))
    }

    @Test
    fun getAvailability_Tentative_ReturnsTentativeConstant() {
        assertEquals(android.provider.CalendarContract.Events.AVAILABILITY_TENTATIVE,
            getAvailability(Availability.TENTATIVE))
    }

    @Test
    fun getAvailability_Null_ReturnsNull() {
        assertNull(getAvailability(null))
    }

    @Test
    fun getEventStatus_Confirmed_ReturnsConfirmedConstant() {
        assertEquals(android.provider.CalendarContract.Events.STATUS_CONFIRMED,
            getEventStatus(EventStatus.CONFIRMED))
    }

    @Test
    fun getEventStatus_Tentative_ReturnsTentativeConstant() {
        assertEquals(android.provider.CalendarContract.Events.STATUS_TENTATIVE,
            getEventStatus(EventStatus.TENTATIVE))
    }

    @Test
    fun getEventStatus_Canceled_ReturnsCanceledConstant() {
        assertEquals(android.provider.CalendarContract.Events.STATUS_CANCELED,
            getEventStatus(EventStatus.CANCELED))
    }

    @Test
    fun getEventStatus_Null_ReturnsNull() {
        assertNull(getEventStatus(null))
    }

    // ---- getTimeZone ----

    @Test
    fun getTimeZone_ValidName_ReturnsIt() {
        assertEquals("Australia/Sydney", getTimeZone("Australia/Sydney").id)
    }

    @Test
    fun getTimeZone_InvalidName_FallsBackToDeviceTimeZone() {
        val deviceTimeZone = java.util.Calendar.getInstance().timeZone
        assertEquals(deviceTimeZone.id, getTimeZone("Not/ARealZone").id)
    }

    @Test
    fun getTimeZone_Null_FallsBackToDeviceTimeZone() {
        val deviceTimeZone = java.util.Calendar.getInstance().timeZone
        assertEquals(deviceTimeZone.id, getTimeZone(null).id)
    }

    // ---- parseRecurrenceRuleString ----

    @Test
    fun parseRecurrenceRuleString_Null_ReturnsNull() {
        assertNull(parseRecurrenceRuleString(null))
    }

    @Test
    fun parseRecurrenceRuleString_Blank_ReturnsNull() {
        assertNull(parseRecurrenceRuleString(""))
    }

    @Test
    fun parseRecurrenceRuleString_ValidDaily_ReturnsFrequencyDaily() {
        assertEquals(Freq.DAILY, parseRecurrenceRuleString("FREQ=DAILY")?.freq)
    }

    @Test
    fun parseRecurrenceRuleString_MalformedMissingFreq_ReturnsNullInsteadOfCrashing() {
        // #566: some third-party sync adapters write a non-blank RRULE column value
        // that's missing the RFC 5545-mandatory FREQ part (e.g. "COUNT=5" alone).
        // org.dmfs.rfc5545.recur.RecurrenceRule(String) throws
        // InvalidRecurrenceRuleException("FREQ part is missing") in that case; since
        // Kotlin doesn't enforce checked exceptions, that propagated uncaught all the
        // way out of retrieveEvents and crashed the whole call instead of just
        // skipping the one unparseable recurrence rule.
        assertNull(parseRecurrenceRuleString("COUNT=5"))
    }

    // ---- buildRecurrenceRuleParams ----

    @Test
    fun buildRecurrenceRuleParams_Daily_ReturnsFreqDaily() {
        val rule = RecurrenceRule(Freq.DAILY)
        assertEquals("FREQ=DAILY", buildRecurrenceRuleParams(rule))
    }

    @Test
    fun buildRecurrenceRuleParams_Weekly_ReturnsFreqWeekly() {
        val rule = RecurrenceRule(Freq.WEEKLY)
        assertEquals("FREQ=WEEKLY", buildRecurrenceRuleParams(rule))
    }

    @Test
    fun buildRecurrenceRuleParams_Monthly_ReturnsFreqMonthly() {
        val rule = RecurrenceRule(Freq.MONTHLY)
        assertEquals("FREQ=MONTHLY", buildRecurrenceRuleParams(rule))
    }

    @Test
    fun buildRecurrenceRuleParams_Yearly_ReturnsFreqYearly() {
        val rule = RecurrenceRule(Freq.YEARLY)
        assertEquals("FREQ=YEARLY", buildRecurrenceRuleParams(rule))
    }

    @Test
    fun buildRecurrenceRuleParams_Interval_IncludesIntervalPart() {
        val rule = RecurrenceRule(Freq.DAILY).apply { interval = 3 }
        assertEquals("FREQ=DAILY;INTERVAL=3", buildRecurrenceRuleParams(rule))
    }

    @Test
    fun buildRecurrenceRuleParams_Count_IncludesCountPart() {
        val rule = RecurrenceRule(Freq.DAILY).apply { count = 5 }
        assertEquals("FREQ=DAILY;COUNT=5", buildRecurrenceRuleParams(rule))
    }

    @Test
    fun buildRecurrenceRuleParams_Until_IncludesUntilPart() {
        // Dashed ISO-ish format, not compact iCal -- this is what the `rrule`
        // Dart package's encoder actually emits for `until` (see
        // rrule's json/encoder.dart _formatDateTime); parseDateTime's own
        // regex requires exactly this shape.
        val rule = RecurrenceRule(Freq.DAILY).apply { until = "2024-01-01T00:00:00" }
        assertEquals(
            "FREQ=DAILY;UNTIL=20240101T000000Z",
            buildRecurrenceRuleParams(rule),
        )
    }

    @Test
    fun buildRecurrenceRuleParams_SingleByDay_IncludesBydayPart() {
        val rule = RecurrenceRule(Freq.WEEKLY).apply { byday = mutableListOf("MO") }
        assertEquals("FREQ=WEEKLY;BYDAY=MO", buildRecurrenceRuleParams(rule))
    }

    @Test
    fun buildRecurrenceRuleParams_MultipleByDayWithOccurrence_IncludesEach() {
        // "2nd Tuesday" -- a numeric occurrence prefix, valid for MONTHLY/YEARLY.
        val rule = RecurrenceRule(Freq.MONTHLY).apply {
            byday = mutableListOf("1MO", "2TU")
        }
        assertEquals("FREQ=MONTHLY;BYDAY=1MO,2TU", buildRecurrenceRuleParams(rule))
    }

    @Test
    fun buildRecurrenceRuleParams_SingleByMonthDay_IncludesPart() {
        val rule = RecurrenceRule(Freq.MONTHLY).apply { bymonthday = mutableListOf(15) }
        assertEquals("FREQ=MONTHLY;BYMONTHDAY=15", buildRecurrenceRuleParams(rule))
    }

    @Test
    fun buildRecurrenceRuleParams_MultipleByMonthDay_IncludesPart() {
        val rule = RecurrenceRule(Freq.MONTHLY).apply { bymonthday = mutableListOf(1, 15) }
        assertEquals("FREQ=MONTHLY;BYMONTHDAY=1,15", buildRecurrenceRuleParams(rule))
    }

    @Test
    fun buildRecurrenceRuleParams_ByYearDay_IncludesPart() {
        val rule = RecurrenceRule(Freq.YEARLY).apply { byyearday = mutableListOf(100) }
        assertEquals("FREQ=YEARLY;BYYEARDAY=100", buildRecurrenceRuleParams(rule))
    }

    @Test
    fun buildRecurrenceRuleParams_ByWeekNo_IncludesPart() {
        val rule = RecurrenceRule(Freq.YEARLY).apply { byweekno = mutableListOf(20) }
        assertEquals("FREQ=YEARLY;BYWEEKNO=20", buildRecurrenceRuleParams(rule))
    }

    @Test
    fun buildRecurrenceRuleParams_ByMonth_IncludesPart_ZeroIndexedInput() {
        // Regression guard for the documented "library gives a wrong int" -1
        // adjustment: a *1-indexed* input month (3 == March) must round-trip
        // back to a 1-indexed BYMONTH in the RRULE string.
        val rule = RecurrenceRule(Freq.YEARLY).apply { bymonth = mutableListOf(3) }
        assertEquals("FREQ=YEARLY;BYMONTH=3", buildRecurrenceRuleParams(rule))
    }

    @Test
    fun buildRecurrenceRuleParams_BySetPos_IncludesPart() {
        val rule = RecurrenceRule(Freq.MONTHLY).apply {
            byday = mutableListOf("MO", "TU", "WE", "TH", "FR")
            bysetpos = mutableListOf(-1)
        }
        assertEquals(
            "FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-1",
            buildRecurrenceRuleParams(rule),
        )
    }

    @Test
    fun buildRecurrenceRuleParams_EverythingSetAtOnce() {
        val rule = RecurrenceRule(Freq.YEARLY).apply {
            interval = 2
            count = 10
            byday = mutableListOf("1MO")
            bymonthday = mutableListOf(15)
            byyearday = mutableListOf(100)
            bymonth = mutableListOf(6)
            bysetpos = mutableListOf(1)
        }
        // org.dmfs's RecurrenceRule.toString() reorders parts internally
        // (verified: it isn't simply construction order), so this asserts
        // part membership rather than a hard-coded sequence -- the point of
        // this case is that every part survives when they're all set
        // together, not the exact string layout.
        val parts = buildRecurrenceRuleParams(rule)!!.split(";").toSet()
        assertEquals(
            setOf(
                "FREQ=YEARLY",
                "COUNT=10",
                "INTERVAL=2",
                "BYDAY=1MO",
                "BYMONTHDAY=15",
                "BYYEARDAY=100",
                "BYMONTH=6",
                "BYSETPOS=1",
            ),
            parts,
        )
    }
}
