package com.builttoroam.devicecalendar.models

import org.dmfs.rfc5545.recur.Freq

class RecurrenceRule(val freq: Freq) {
    var count: Int? = null
    var interval: Int? = null
    var until: String? = null
    var sourceRruleString: String? = null
    var wkst: String? = null

    var byday: MutableList<String>? = null
    var bymonthday: MutableList<Int>? = null
    var byyearday: MutableList<Int>? = null
    var byweekno: MutableList<Int>? = null
    var bymonth: MutableList<Int>? = null
    var bysetpos: MutableList<Int>? = null

    fun toDebugString(): String {
        return "count: $count, interval: $interval, until: $until, sourceRruleString: $sourceRruleString, weekStart: $wkst, byWeekDays: $byday, byMonthDays: $bymonthday, byYearDays: $byyearday, byWeeks: $byweekno, byMonths: $bymonth, bySetPositions: $bysetpos, recurrenceFrequency: ${freq.name}"
    }

}
