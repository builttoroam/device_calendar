package com.builttoroam.devicecalendar.models

class Attendee(
    val id: String,
    val eventId: String,
    val emailAddress: String,
    val name: String?,
    val role: Int,
    val attendanceStatus: Int?,
    val isOrganizer: Boolean?,
    val isCurrentUser: Boolean?
)