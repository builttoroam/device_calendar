package com.builttoroam.devicecalendar.common

import android.provider.CalendarContract

class Constants {
    companion object {
        const val CALENDAR_PROJECTION_ID_INDEX: Int = 0
        const val CALENDAR_PROJECTION_ACCOUNT_NAME_INDEX: Int = 1
        const val CALENDAR_PROJECTION_ACCOUNT_TYPE_INDEX: Int = 2
        const val CALENDAR_PROJECTION_DISPLAY_NAME_INDEX: Int = 3
        const val CALENDAR_PROJECTION_OWNER_ACCOUNT_INDEX: Int = 4
        const val CALENDAR_PROJECTION_ACCESS_LEVEL_INDEX: Int = 5
        const val CALENDAR_PROJECTION_COLOR_INDEX: Int = 6
        const val CALENDAR_PROJECTION_IS_PRIMARY_INDEX: Int = 7

        // API 17 or higher
        val CALENDAR_PROJECTION: Array<String> = arrayOf(
                CalendarContract.Calendars._ID,                           // 0
                CalendarContract.Calendars.ACCOUNT_NAME,                  // 1
                CalendarContract.Calendars.ACCOUNT_TYPE,                  // 2
                CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,         // 3
                CalendarContract.Calendars.OWNER_ACCOUNT,                 // 4
                CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL,         // 5
                CalendarContract.Calendars.CALENDAR_COLOR,                // 6
                CalendarContract.Calendars.IS_PRIMARY                     // 7

        )

        // API 16 or lower
        val CALENDAR_PROJECTION_OLDER_API: Array<String> = arrayOf(
                CalendarContract.Calendars._ID,                           // 0
                CalendarContract.Calendars.ACCOUNT_NAME,                  // 1
                CalendarContract.Calendars.ACCOUNT_TYPE,                  // 2
                CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,         // 3
                CalendarContract.Calendars.OWNER_ACCOUNT,                 // 4
                CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL,         // 5
                CalendarContract.Calendars.CALENDAR_COLOR                 // 6
        )

        const val EVENT_PROJECTION_ID_INDEX: Int = 0
        const val EVENT_PROJECTION_TITLE_INDEX: Int = 1
        const val EVENT_PROJECTION_DESCRIPTION_INDEX: Int = 2
        const val EVENT_PROJECTION_BEGIN_INDEX: Int = 3
        const val EVENT_PROJECTION_END_INDEX: Int = 4
        const val EVENT_PROJECTION_RECURRING_RULE_INDEX: Int = 7
        const val EVENT_PROJECTION_ALL_DAY_INDEX: Int = 8
        const val EVENT_PROJECTION_EVENT_LOCATION_INDEX: Int = 9
        const val EVENT_PROJECTION_CUSTOM_APP_URI_INDEX: Int = 10
        const val EVENT_PROJECTION_START_TIMEZONE_INDEX: Int = 11
        const val EVENT_PROJECTION_END_TIMEZONE_INDEX: Int = 12
        const val EVENT_PROJECTION_AVAILABILITY_INDEX: Int = 13

        val EVENT_PROJECTION: Array<String> = arrayOf(
                CalendarContract.Instances.EVENT_ID,
                CalendarContract.Events.TITLE,
                CalendarContract.Events.DESCRIPTION,
                CalendarContract.Instances.BEGIN,
                CalendarContract.Instances.END,
                CalendarContract.Instances.DURATION,
                CalendarContract.Events.RDATE,
                CalendarContract.Events.RRULE,
                CalendarContract.Events.ALL_DAY,
                CalendarContract.Events.EVENT_LOCATION,
                CalendarContract.Events.CUSTOM_APP_URI,
                CalendarContract.Events.EVENT_TIMEZONE,
                CalendarContract.Events.EVENT_END_TIMEZONE,
                CalendarContract.Events.AVAILABILITY
        )

        const val EVENT_INSTANCE_DELETION_ID_INDEX: Int = 0
        const val EVENT_INSTANCE_DELETION_RRULE_INDEX: Int = 1
        const val EVENT_INSTANCE_DELETION_LAST_DATE_INDEX: Int = 2
        const val EVENT_INSTANCE_DELETION_BEGIN_INDEX: Int = 3
        const val EVENT_INSTANCE_DELETION_END_INDEX: Int = 4

        val EVENT_INSTANCE_DELETION: Array<String> = arrayOf(
                CalendarContract.Instances.EVENT_ID,
                CalendarContract.Events.RRULE,
                CalendarContract.Events.LAST_DATE,
                CalendarContract.Instances.BEGIN,
                CalendarContract.Instances.END
        )

        const val ATTENDEE_ID_INDEX: Int = 0
        const val ATTENDEE_EVENT_ID_INDEX: Int = 1
        const val ATTENDEE_NAME_INDEX: Int = 2
        const val ATTENDEE_EMAIL_INDEX: Int = 3
        const val ATTENDEE_TYPE_INDEX: Int = 4
        const val ATTENDEE_RELATIONSHIP_INDEX: Int = 5
        const val ATTENDEE_STATUS_INDEX: Int = 6

        val ATTENDEE_PROJECTION: Array<String> = arrayOf(
                CalendarContract.Attendees._ID,
                CalendarContract.Attendees.EVENT_ID,
                CalendarContract.Attendees.ATTENDEE_NAME,
                CalendarContract.Attendees.ATTENDEE_EMAIL,
                CalendarContract.Attendees.ATTENDEE_TYPE,
                CalendarContract.Attendees.ATTENDEE_RELATIONSHIP,
                CalendarContract.Attendees.ATTENDEE_STATUS
        )

        const val REMINDER_MINUTES_INDEX = 1
        val REMINDER_PROJECTION: Array<String> = arrayOf(
                CalendarContract.Reminders.EVENT_ID,
                CalendarContract.Reminders.MINUTES
        )

        const val AVAILABILITY_UNAVAILABLE = "UNAVAILABLE"
    }
}