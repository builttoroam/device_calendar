package com.builttoroam.devicecalendar.common

class ErrorMessages {
    companion object {
        const val CALENDAR_ID_INVALID_ARGUMENT_NOT_A_NUMBER_MESSAGE: String = "Calendar ID is not a number"
        const val RETRIEVE_EVENTS_ARGUMENTS_NOT_VALID_MESSAGE: String = "Provided arguments (i.e. start, end and event ids) are null or emtpy"
        const val CREATE_EVENT_ARGUMENTS_NOT_VALID_MESSAGE: String = "Some of the event arguments are not valid"
        const val DELETING_RECURRING_EVENT_NOT_SUPPORTED_MESSAGE: String = "Currently, deleting of recurring events is not supported"
        const val NOT_AUTHORIZED_MESSAGE: String = "The user has not allowed this application to modify their calendar(s)"
    }
}
