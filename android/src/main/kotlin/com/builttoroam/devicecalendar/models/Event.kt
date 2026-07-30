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
    var originalInstanceTime: Long? = null
    // #509: the calendar provider's stable, sync-adapter-assigned identifier
    // (CalendarContract.Events._SYNC_ID) for this event, as opposed to
    // [eventId] which is only the local provider row id and can change if
    // the event gets re-synced/recreated. Null if the provider hasn't
    // assigned one yet (e.g. a local-only, never-synced calendar).
    var syncId: String? = null
}