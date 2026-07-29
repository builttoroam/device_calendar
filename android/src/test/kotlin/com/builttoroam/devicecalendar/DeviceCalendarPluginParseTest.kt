package com.builttoroam.devicecalendar

import com.builttoroam.devicecalendar.models.Availability
import com.builttoroam.devicecalendar.models.EventStatus
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * Regression coverage for the null-safety fix TESTING_PLAN.md attributes to
 * CalendarDelegate's getAvailability/getEventStatus, but which actually
 * lives here: Kotlin's Availability/EventStatus enums have no
 * UNAVAILABLE/NONE constant (see models/Availability.kt, models/EventStatus.kt),
 * so parseAvailability/parseEventStatus must intercept those two strings
 * before calling `Availability.valueOf()`/`EventStatus.valueOf()`, or those
 * throw IllegalArgumentException instead of returning null.
 */
class DeviceCalendarPluginParseTest {
    private val plugin = DeviceCalendarPlugin()

    private fun <T> invokePrivate(name: String, vararg args: Any?): T {
        val method = DeviceCalendarPlugin::class.java.declaredMethods
            .first { it.name == name && it.parameterCount == args.size }
        method.isAccessible = true
        @Suppress("UNCHECKED_CAST")
        return method.invoke(plugin, *args) as T
    }

    private fun parseAvailability(value: String?): Availability? =
        invokePrivate("parseAvailability", value)

    private fun parseEventStatus(value: String?): EventStatus? =
        invokePrivate("parseEventStatus", value)

    @Test
    fun parseAvailability_Unavailable_ReturnsNullNotThrow() {
        assertNull(parseAvailability("UNAVAILABLE"))
    }

    @Test
    fun parseAvailability_Null_ReturnsNull() {
        assertNull(parseAvailability(null))
    }

    @Test
    fun parseAvailability_Busy_ReturnsBusy() {
        assertEquals(Availability.BUSY, parseAvailability("BUSY"))
    }

    @Test
    fun parseEventStatus_None_ReturnsNullNotThrow() {
        assertNull(parseEventStatus("NONE"))
    }

    @Test
    fun parseEventStatus_Null_ReturnsNull() {
        assertNull(parseEventStatus(null))
    }

    @Test
    fun parseEventStatus_Confirmed_ReturnsConfirmed() {
        assertEquals(EventStatus.CONFIRMED, parseEventStatus("CONFIRMED"))
    }
}
