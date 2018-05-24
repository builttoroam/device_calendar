package com.builttoroam.devicecalendar.models

class Event(val title: String) {
    var id: String? = null
    var description: String? = null
    var start: Long = -1
    var end: Long = -1
}