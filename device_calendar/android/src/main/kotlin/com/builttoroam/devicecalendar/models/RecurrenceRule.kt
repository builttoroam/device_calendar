package com.builttoroam.devicecalendar.models

import com.builttoroam.devicecalendar.common.DayOfWeek
import com.builttoroam.devicecalendar.common.RecurrenceFrequency


class RecurrenceRule(val recurrenceFrequency : RecurrenceFrequency) {
    var totalOccurrences: Int? = null
    var interval: Int? = null
    var endDate: Long? = null
    val daysOfWeek: MutableList<DayOfWeek> = mutableListOf()
}
