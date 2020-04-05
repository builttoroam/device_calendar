package com.builttoroam.devicecalendar.common

class ErrorMessages {
    companion object {
        const val CALENDAR_ID_INVALID_ARGUMENT_NOT_A_NUMBER_MESSAGE: String = "Calendar ID is not a number"
        const val EVENT_ID_CANNOT_BE_NULL_ON_DELETION_MESSAGE: String = "Event ID cannot be null on deletion"
        const val RETRIEVE_EVENTS_ARGUMENTS_NOT_VALID_MESSAGE: String = "Provided arguments (i.e. start, end and event ids) are null or empty"
        const val CREATE_EVENT_ARGUMENTS_NOT_VALID_MESSAGE: String = "Some of the event arguments are not valid"
        const val NOT_AUTHORIZED_MESSAGE: String = "The user has not allowed this application to modify their calendar(s)"
    }
}
