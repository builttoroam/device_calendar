package com.builttoroam.devicecalendar.common

class ErrorCodes {
    companion object {
        const val EXCEPTION: String = "exception";
        const val INVALID_ARGUMENT: String = "invalid_argument";
        const val CALENDAR_RETRIEVAL_FAILURE: String = "calendar_retrieval_failure";
        const val EVENTS_RETRIEVAL_FAILURE: String = "events_retrieval_failure";
        const val EVENT_CREATION_FAILURE: String = "event_creation_failure";
        const val CALENDAR_IS_READ_ONLY: String = "calendar_is_read_only";
    }
}
