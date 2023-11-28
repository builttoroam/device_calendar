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
}
