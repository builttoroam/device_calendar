package com.builttoroam.devicecalendar.models

import io.flutter.plugin.common.MethodChannel

class CalendarMethodsParametersCacheModel(
    val pendingChannelResult: MethodChannel.Result,
    val calendarDelegateMethodCode: Int,
    var calendarId: String = "",
    var calendarIds: List<String>? = null,
    var calendarEventsStartDate: Long? = null,
    var calendarEventsEndDate: Long? = null,
    var calendarEventsIds: List<String> = listOf(),
    var eventId: String = "",
    var event: Event? = null,
    var isAsync: Boolean = false,
) {
    var ownCacheKey: Int? = null
}