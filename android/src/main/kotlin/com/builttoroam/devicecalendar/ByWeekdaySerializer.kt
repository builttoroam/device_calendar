package com.builttoroam.devicecalendar

import com.builttoroam.devicecalendar.common.ByWeekDayEntry
import com.google.gson.*
import java.lang.reflect.Type

class ByWeekdaySerializer : JsonSerializer<ByWeekDayEntry> {
    override fun serialize(
        src: ByWeekDayEntry?,
        typeOfSrc: Type?,
        context: JsonSerializationContext?
    ): JsonElement {
        val jsonObject = JsonObject()
        if (src != null) {
            jsonObject.addProperty("day", src.day)
            jsonObject.addProperty("occurrence", src.occurrence)
//            return JsonPrimitive(src.day)
        }
        return jsonObject
    }
}