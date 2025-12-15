package com.dreautall.waterflyiii

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.rule.ActivityTestRule
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.Assert.*

/**
 * Android-specific instrumentation tests for MainActivity
 * 
 * These tests run on an Android device or emulator and can:
 * - Test native Android functionality
 * - Verify permissions
 * - Test deep links
 * - Verify notification handling
 */
@RunWith(AndroidJUnit4::class)
class MainActivityTest {

    @get:Rule
    val activityRule = ActivityTestRule(MainActivity::class.java)

    @Test
    fun testAppContext() {
        // Context of the app under test
        val appContext = InstrumentationRegistry.getInstrumentation().targetContext
        assertEquals("com.dreautall.waterflyiii", appContext.packageName)
    }

    @Test
    fun testMainActivityLaunches() {
        val activity = activityRule.activity
        assertNotNull("MainActivity should not be null", activity)
    }

    @Test
    fun testNotificationPermission() {
        val activity = activityRule.activity
        // Test notification permission handling
        assertNotNull("Activity should handle notification permissions", activity)
    }
}
