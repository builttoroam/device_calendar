package com.builttoroam.devicecalendar.models

import com.builttoroam.devicecalendar.common.ByWeekDayEntry
import com.builttoroam.devicecalendar.common.RecurrenceFrequency

class RecurrenceRule(val recurrenceFrequency: RecurrenceFrequency) {
    var count: Int? = null
    var interval: Int? = null
    var until: Long? = null
    var sourceRruleString: String? = null
    var weekStart: Int? = null
    var byWeekDays: MutableList<ByWeekDayEntry>? = null
    var byMonthDays: MutableList<Int>? = null
    var byYearDays: MutableList<Int>? = null
    var byWeeks: MutableList<Int>? = null
    var byMonths: MutableList<Int>? = null
    var bySetPositions: MutableList<Int>? = null

    fun toDebugString(): String {
        return "count: $count, interval: $interval, until: $until, sourceRruleString: $sourceRruleString, weekStart: $weekStart, byWeekDays: ${byWeekDays?.firstOrNull()?.day}, byMonthDays: $byMonthDays, byYearDays: $byYearDays, byWeeks: $byWeeks, byMonths: $byMonths, bySetPositions: $bySetPositions, recurrenceFrequency_name: ${recurrenceFrequency.name}, recurrenceFrequency_ordinal: ${recurrenceFrequency.ordinal}"
    }

}
