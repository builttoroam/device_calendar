package com.builttoroam.devicecalendar

import android.content.Context
import android.database.ContentObserver
import android.os.Handler
import android.os.Looper
import android.provider.CalendarContract
import io.flutter.plugin.common.EventChannel

private const val DEBOUNCE_MILLIS = 500L

/**
 * Forwards CalendarContract change notifications to Dart as a stream of
 * no-payload "something changed" events. CalendarContract fires bursts of
 * onChange callbacks for a single logical edit (e.g. one attendee update
 * touches Events + Attendees + Instances), so bursts are coalesced into one
 * emitted event per debounce window rather than forwarded 1:1.
 */
class CalendarChangeStreamHandler(private val context: Context) : EventChannel.StreamHandler {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var observer: ContentObserver? = null
    private var pendingEmit: Runnable? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        val contentObserver = object : ContentObserver(mainHandler) {
            override fun onChange(selfChange: Boolean) {
                pendingEmit?.let { mainHandler.removeCallbacks(it) }
                val emit = Runnable { events.success(null) }
                pendingEmit = emit
                mainHandler.postDelayed(emit, DEBOUNCE_MILLIS)
            }
        }
        observer = contentObserver
        context.contentResolver.registerContentObserver(
            CalendarContract.CONTENT_URI,
            true,
            contentObserver
        )
    }

    override fun onCancel(arguments: Any?) {
        pendingEmit?.let { mainHandler.removeCallbacks(it) }
        pendingEmit = null
        observer?.let { context.contentResolver.unregisterContentObserver(it) }
        observer = null
    }
}
