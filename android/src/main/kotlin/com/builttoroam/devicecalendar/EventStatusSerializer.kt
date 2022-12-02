package com.builttoroam.devicecalendar

import com.builttoroam.devicecalendar.models.EventStatus
import com.google.gson.*
import java.lang.reflect.Type

class EventStatusSerializer: JsonSerializer<EventStatus> {
    override fun serialize(src: EventStatus?, typeOfSrc: Type?, context: JsonSerializationContext?): JsonElement {
        if(src != null) {
            return JsonPrimitive(src.name)
        }
        return JsonObject()
    }

}