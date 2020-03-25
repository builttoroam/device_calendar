package com.builttoroam.devicecalendar.models

import android.graphics.Color

class Calendar(val id: String, val name: String, val color : Int, val accountName: String, val accountType: String) {
    var isReadOnly: Boolean = false
    var isDefault: Boolean = false
}