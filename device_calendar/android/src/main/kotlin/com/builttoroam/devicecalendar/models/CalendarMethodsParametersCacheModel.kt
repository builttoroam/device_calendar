package com.builttoroam.devicecalendar.models

import io.flutter.plugin.common.MethodChannel

class CalendarMethodsParametersCacheModel(val pendingChannelResult: MethodChannel.Result,
                                          val calendarDelegateMethodCode: Int,
                                          var calendarId: String = "",
                                          var calendarEventsStartDate: Long? = null,
                                          var calendarEventsEndDate: Long? = null,
                                          var calendarEventsIdsOrUrls: List<String> = listOf(),
                                          var retrieveByUrl: Boolean = false,
                                          var eventId: String = "",
                                          var event: Event? = null) {
    var ownCacheKey: Int? = null
}