package com.builttoroam.devicecalendar.models

class Event(val title: String) {
    var eventId: String? = null
    var calendarId: String? = null
    var description: String? = null
    var start: Long = -1
    var end: Long = -1
    var allDay: Boolean = false
    var location: String? = null
    var attendees: MutableList<Attendee> = mutableListOf()
}