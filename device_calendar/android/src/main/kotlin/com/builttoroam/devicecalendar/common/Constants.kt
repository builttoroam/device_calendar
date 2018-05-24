package com.builttoroam.devicecalendar.common

import android.provider.CalendarContract

class Constants {
    companion object {
        const val CALENDAR_PROJECTION_ID_INDEX: Int = 0
        const val CALENDAR_PROJECTION_ACCOUNT_NAME_INDEX: Int = 1
        const val CALENDAR_PROJECTION_DISPLAY_NAME_INDEX: Int = 2
        const val CALENDAR_PROJECTION_OWNER_ACCOUNT_INDEX: Int = 3
        const val CALENDAR_PROJECTION_ACCESS_LEVEL_INDEX: Int = 4

        val CALENDAR_PROJECTION: Array<String> = arrayOf(
                CalendarContract.Calendars._ID,                           // 0
                CalendarContract.Calendars.ACCOUNT_NAME,                  // 1
                CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,         // 2
                CalendarContract.Calendars.OWNER_ACCOUNT,                 // 3
                CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL          // 4
        )

        const val EVENT_PROJECTION_ID_INDEX: Int = 0
        const val EVENT_PROJECTION_TITLE_INDEX: Int = 1
        const val EVENT_PROJECTION_DESCRIPTION_INDEX: Int = 2
        const val EVENT_PROJECTION_BEGIN_INDEX: Int = 3
        const val EVENT_PROJECTION_END_INDEX: Int = 4
        const val EVENT_PROJECTION_DURATION_INDEX: Int = 5
        const val EVENT_PROJECTION_RECURRING_DATE_INDEX: Int = 6
        const val EVENT_PROJECTION_RECURRING_RULE_INDEX: Int = 7
        const val EVENT_PROJECTION_ALL_DAY_INDEX: Int = 8
        const val EVENT_PROJECTION_EVENT_LOCATION_INDEX: Int = 9

        val EVENT_PROJECTION: Array<String> = arrayOf(
                CalendarContract.Events._ID,
                CalendarContract.Events.TITLE,
                CalendarContract.Events.DESCRIPTION,
                CalendarContract.Instances.BEGIN,
                CalendarContract.Instances.END,
                CalendarContract.Instances.DURATION,
                CalendarContract.Events.RDATE,
                CalendarContract.Events.RRULE,
                CalendarContract.Events.ALL_DAY,
                CalendarContract.Events.EVENT_LOCATION
        )
    }
}