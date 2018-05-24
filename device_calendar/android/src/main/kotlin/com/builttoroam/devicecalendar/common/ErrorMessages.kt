package com.builttoroam.devicecalendar.common

class ErrorMessages {
    companion object {
        const val CALENDAR_ID_INVALID_ARGUMENT_NOT_A_NUMBER_MESSAGE: String = "Calendar ID is not a number"
        const val CALENDAR_ID_INVALID_ARGUMENT_NOT_SPECIFIED_MESSAGE: String = "Calendar ID argument has not been specified or is invalid"
        const val EVENT_ID_INVALID_ARGUMENT_NOT_SPECIFIED_MESSAGE: String = "Event ID argument has not been specified or is invalid"
        const val EVENT_ID_INVALID_ARGUMENT_NOT_A_NUMBER_MESSAGE: String = "Event ID is not a number"
        const val EVENTS_START_DATE_LARGER_THAN_END_DATE_MESSAGE: String = "The starting date needs to be lower than the end date"
        const val CREATE_EVENT_ARGUMENTS_NOT_VALID_MESSAGE: String = "Some of the event arguments are not valid"
        const val DELETING_RECURRING_EVENT_NOT_SUPPORTED_MESSAGE: String = "Currently, deleting of recurring events is not supported"
    }
}
