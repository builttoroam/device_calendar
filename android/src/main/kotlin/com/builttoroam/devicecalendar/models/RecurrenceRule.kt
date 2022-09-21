package com.builttoroam.devicecalendar.models

import com.builttoroam.devicecalendar.common.DayOfWeek
import com.builttoroam.devicecalendar.common.RecurrenceFrequency


class RecurrenceRule(
    val recurrenceFrequency: RecurrenceFrequency
) {
    var totalOccurrences: Int? = null

    var interval: Int? = null

    var endDate: Long? = null

    var daysOfWeek: MutableList<DayOfWeek>? = null

    var weekStart: DayOfWeek? = null

    var dayOfMonth: MutableList<Int>? = null

    var monthOfYear: MutableList<Int>? = null

    var weekOfMonth: Int? = null
}
