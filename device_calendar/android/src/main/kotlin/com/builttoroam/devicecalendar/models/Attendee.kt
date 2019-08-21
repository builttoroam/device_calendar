package com.builttoroam.devicecalendar.models

class Attendee(val eventId: Long, val emailAddress: String, val name: String?, val isRequired: Boolean, val isOrganizer: Boolean) {
}