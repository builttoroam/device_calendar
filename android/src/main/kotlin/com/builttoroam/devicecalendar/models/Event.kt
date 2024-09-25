package com.builttoroam.devicecalendar.models

class Event {
    var eventTitle: String? = null
    var eventId: String? = null
    var calendarId: String? = null
    var eventDescription: String? = null
    var eventStartDate: Long? = null
    var eventEndDate: Long? = null
    var eventStartTimeZone: String? = null
    var eventEndTimeZone: String? = null
    var eventAllDay: Boolean = false
    var eventLocation: String? = null
    var eventURL: String? = null
    var attendees: MutableList<Attendee> = mutableListOf()
    var recurrenceRule: RecurrenceRule? = null
    var organizer: Attendee? = null
    var reminders: MutableList<Reminder> = mutableListOf()
    var availability: Availability? = null
    var eventStatus: EventStatus? = null
    var eventColor: Int? = null
    var eventColorKey: Int? = null
}