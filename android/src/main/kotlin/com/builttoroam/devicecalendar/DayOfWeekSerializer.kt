package com.builttoroam.devicecalendar

import com.builttoroam.devicecalendar.common.DayOfWeek
import com.google.gson.*
import java.lang.reflect.Type

class DayOfWeekSerializer: JsonSerializer<DayOfWeek> {
    override fun serialize(src: DayOfWeek?, typeOfSrc: Type?, context: JsonSerializationContext?): JsonElement {
        if(src != null) {
            return JsonPrimitive(src.ordinal)
        }
        return JsonObject()
    }
}