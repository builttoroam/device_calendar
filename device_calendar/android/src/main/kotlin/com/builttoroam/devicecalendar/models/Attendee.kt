package com.builttoroam.devicecalendar.models

class Attendee(var eventId: Long?, val emailAddress: String, val name: String?, val isRequired: Boolean?, val attendanceStatus: Int?, val isOrganizer: Boolean?) {
}