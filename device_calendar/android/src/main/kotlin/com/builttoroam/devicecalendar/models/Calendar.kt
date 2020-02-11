package com.builttoroam.devicecalendar.models

import android.graphics.Color

class Calendar(val id: String, val name: String, val color : Int) {
    var isReadOnly: Boolean = false
    var isDefault: Boolean = false
}