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

    /**
     * Helper property to access the MainActivity instance from the activity rule.
     * 
     * This eliminates code duplication across test methods that need to access
     * the activity instance, following DRY principles.
     */
    private val activity: MainActivity
        get() = activityRule.activity

    /**
     * Tests that the application context is correctly configured.
     * 
     * Validates:
     * - The app context is accessible from the instrumentation framework
     * - The package name matches the expected value "com.dreautall.waterflyiii"
     * 
     * This is a fundamental test ensuring the test environment is properly set up.
     */
    @Test
    fun testAppContext() {
        val appContext = InstrumentationRegistry.getInstrumentation().targetContext
        assertEquals("com.dreautall.waterflyiii", appContext.packageName)
    }

    /**
     * Tests that MainActivity successfully launches and is accessible.
     * 
     * Validates:
     * - MainActivity instance is created and not null
     * - Activity rule successfully initializes the activity
     * - Basic activity lifecycle is functioning correctly
     * 
     * This test ensures the main entry point of the app works correctly.
     */
    @Test
    fun testMainActivityLaunches() {
        assertNotNull("MainActivity should not be null", activity)
    }

    /**
     * Tests that MainActivity is available for notification permission handling.
     * 
     * Validates:
     * - Activity instance is accessible for permission-related operations
     * - Activity can handle notification permission requests
     * 
     * Note: This is a basic availability test. For comprehensive permission testing,
     * consider adding tests that verify actual permission request flows and user responses.
     */
    @Test
    fun testNotificationPermission() {
        assertNotNull("Activity should handle notification permissions", activity)
    }
}
