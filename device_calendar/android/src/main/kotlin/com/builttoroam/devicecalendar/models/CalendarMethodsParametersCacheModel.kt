package com.builttoroam.devicecalendar.models

import io.flutter.plugin.common.MethodChannel

class CalendarMethodsParametersCacheModel(val pendingChannelResult: MethodChannel.Result,
                                          val calendarDelegateMethodCode: Int,
                                          var calendarId: String = "",
                                          var calendarEventsStartDate: Long = -1,
                                          var calendarEventsEndDate: Long = -1,
                                          var eventId: String = "",
                                          var event: Event? = null) {
    var ownCacheKey: Int? = null
}