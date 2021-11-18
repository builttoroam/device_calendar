package com.hello.calendar.models

import com.hello.calendar.common.DayOfWeek
import com.hello.calendar.common.RecurrenceFrequency


class RecurrenceRule(val recurrenceFrequency : RecurrenceFrequency) {
    var totalOccurrences: Int? = null
    var interval: Int? = null
    var endDate: Long? = null
    var daysOfWeek: MutableList<DayOfWeek>? = null
    var dayOfMonth: Int? = null
    var monthOfYear: Int? = null
    var weekOfMonth: Int? = null
}
