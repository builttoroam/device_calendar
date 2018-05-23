package com.builttoroam.devicecalendar.models

class CalendarMethodsParametersCacheModel(val calendarServiceMethodCode: Int,
                                          var calendarId: String = "",
                                          var calendarEventsStartDate: Long = -1,
                                          var calendarEventsEndDate: Long = -1,
                                          var eventId: String = "",
                                          var event: Event? = null) {
}