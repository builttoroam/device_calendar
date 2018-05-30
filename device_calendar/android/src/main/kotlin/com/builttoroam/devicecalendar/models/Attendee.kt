package com.builttoroam.devicecalendar.models

class Attendee(val name: String) {
    var id: Long = -1
    var eventId: Long = -1
    var email: String? = null
    var attendanceRequired: Boolean = false
}