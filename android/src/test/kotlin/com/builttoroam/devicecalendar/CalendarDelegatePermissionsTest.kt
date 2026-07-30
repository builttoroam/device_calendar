package com.builttoroam.devicecalendar

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.kotlin.any
import org.mockito.kotlin.argumentCaptor
import org.mockito.kotlin.mock
import org.mockito.kotlin.never
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Regression coverage for #233: Android has no native read-only permission
 * tier -- `arePermissionsGranted()`/`requestPermissions()` always checked
 * and requested both `WRITE_CALENDAR` and `READ_CALENDAR`, so a caller that
 * only wanted to read calendars/events (e.g. via
 * `CalendarAccessLevel.readOnly`) was still forced through a
 * `WRITE_CALENDAR` prompt. Fixed by threading the `calendarAccessLevel`
 * channel argument into `requestPermissions()`, which now only
 * requests/checks `READ_CALENDAR` when the caller passed "READ_ONLY" --
 * every other value (including no value at all) keeps requesting both,
 * unchanged.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CalendarDelegatePermissionsTest {
    private lateinit var delegate: CalendarDelegate
    private lateinit var activity: Activity
    private lateinit var binding: ActivityPluginBinding

    @Before
    fun setUp() {
        activity = mock()
        binding = mock()
        whenever(binding.activity).thenReturn(activity)
        val context: Context = mock()
        delegate = CalendarDelegate(binding, context)
    }

    private fun denyAllPermissions() {
        whenever(activity.checkSelfPermission(any())).thenReturn(PackageManager.PERMISSION_DENIED)
    }

    @Test
    fun RequestPermissions_ReadOnly_OnlyRequestsReadCalendar() {
        denyAllPermissions()
        val result: MethodChannel.Result = mock()

        delegate.requestPermissions(result, "READ_ONLY")

        val captor = argumentCaptor<Array<String>>()
        verify(activity).requestPermissions(captor.capture(), any())
        assertEquals(listOf(Manifest.permission.READ_CALENDAR), captor.firstValue.toList())
    }

    @Test
    fun RequestPermissions_Full_RequestsBothPermissions() {
        denyAllPermissions()
        val result: MethodChannel.Result = mock()

        delegate.requestPermissions(result, "FULL")

        val captor = argumentCaptor<Array<String>>()
        verify(activity).requestPermissions(captor.capture(), any())
        assertEquals(
            listOf(Manifest.permission.WRITE_CALENDAR, Manifest.permission.READ_CALENDAR),
            captor.firstValue.toList()
        )
    }

    @Test
    fun RequestPermissions_NoAccessLevel_DefaultsToBothPermissions() {
        denyAllPermissions()
        val result: MethodChannel.Result = mock()

        // No accessLevel passed at all -- must match pre-#233 behavior exactly.
        delegate.requestPermissions(result)

        val captor = argumentCaptor<Array<String>>()
        verify(activity).requestPermissions(captor.capture(), any())
        assertEquals(
            listOf(Manifest.permission.WRITE_CALENDAR, Manifest.permission.READ_CALENDAR),
            captor.firstValue.toList()
        )
    }

    @Test
    fun RequestPermissions_ReadOnly_ReadAlreadyGranted_SkipsPromptAndSucceeds() {
        whenever(activity.checkSelfPermission(Manifest.permission.READ_CALENDAR))
            .thenReturn(PackageManager.PERMISSION_GRANTED)
        whenever(activity.checkSelfPermission(Manifest.permission.WRITE_CALENDAR))
            .thenReturn(PackageManager.PERMISSION_DENIED)
        val result: MethodChannel.Result = mock()

        delegate.requestPermissions(result, "READ_ONLY")

        verify(result).success(true)
        verify(activity, never()).requestPermissions(any(), any())
    }

    @Test
    fun RequestPermissions_Full_ReadGrantedButWriteMissing_StillPromptsForBoth() {
        whenever(activity.checkSelfPermission(Manifest.permission.READ_CALENDAR))
            .thenReturn(PackageManager.PERMISSION_GRANTED)
        whenever(activity.checkSelfPermission(Manifest.permission.WRITE_CALENDAR))
            .thenReturn(PackageManager.PERMISSION_DENIED)
        val result: MethodChannel.Result = mock()

        delegate.requestPermissions(result)

        val captor = argumentCaptor<Array<String>>()
        verify(activity).requestPermissions(captor.capture(), any())
        assertEquals(
            listOf(Manifest.permission.WRITE_CALENDAR, Manifest.permission.READ_CALENDAR),
            captor.firstValue.toList()
        )
    }

    @Test
    fun HasPermissions_OnlyReadGranted_ReturnsFalse_UnchangedBehavior() {
        whenever(activity.checkSelfPermission(Manifest.permission.READ_CALENDAR))
            .thenReturn(PackageManager.PERMISSION_GRANTED)
        whenever(activity.checkSelfPermission(Manifest.permission.WRITE_CALENDAR))
            .thenReturn(PackageManager.PERMISSION_DENIED)
        val result: MethodChannel.Result = mock()

        delegate.hasPermissions(result)

        verify(result).success(false)
    }

    @Test
    fun HasPermissions_BothGranted_ReturnsTrue() {
        whenever(activity.checkSelfPermission(any())).thenReturn(PackageManager.PERMISSION_GRANTED)
        val result: MethodChannel.Result = mock()

        delegate.hasPermissions(result)

        verify(result).success(true)
    }
}
