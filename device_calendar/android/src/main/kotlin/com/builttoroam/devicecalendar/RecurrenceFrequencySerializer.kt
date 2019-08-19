package com.builttoroam.devicecalendar

import com.builttoroam.devicecalendar.common.RecurrenceFrequency
import com.google.gson.*
import java.lang.reflect.Type

class RecurrenceFrequencySerializer: JsonSerializer<RecurrenceFrequency> {
    override fun serialize(src: RecurrenceFrequency?, typeOfSrc: Type?, context: JsonSerializationContext?): JsonElement {
        if(src != null) {
            return JsonPrimitive(src.ordinal)
        }
        return JsonObject()
    }

}