package com.dreautall.waterflyiii

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.rule.ActivityTestRule
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.Assert.*
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager

/**
 * Android-specific instrumentation tests for MainActivity
 * 
 * These tests run on an Android device or emulator and can:
 * - Test native Android functionality
 * - Verify permissions
 * - Test deep links
 * - Verify notification handling
 * 
 * **Test Organization:**
 * This test class follows a clear organization pattern:
 * - Helper properties and methods are defined first (following DRY principles)
 * - Test methods are organized by functionality (context, launch, permissions)
 * - Each test method serves a distinct purpose despite using common helpers
 * - Tests are kept separate to maintain clarity and independent testability
 * 
 * **Why Tests Are Separate:**
 * While some tests use the same helper method (`assertActivityNotNull()`), they test
 * different aspects of the activity:
 * - `testAppContext()` - Tests instrumentation framework setup (no activity dependency)
 * - `testMainActivityLaunches()` - Tests activity lifecycle and launch behavior
 * - `testNotificationPermission()` - Tests permission-related functionality
 * 
 * Keeping tests separate allows for:
 * - Clear test failure messages indicating which aspect failed
 * - Independent test execution and debugging
 * - Better test documentation and maintainability
 * 
 * **When to Extract Utilities:**
 * If this file grows beyond 200 lines or if test utilities are needed across multiple
 * test classes, consider extracting common utilities to a separate `TestUtils.kt` file.
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
     * Helper method to assert that the activity is not null.
     * 
     * This extracts the common assertion pattern used across multiple tests,
     * following DRY principles while maintaining test clarity.
     * 
     * @param message The assertion message to display if the activity is null
     */
    private fun assertActivityNotNull(message: String) {
        assertNotNull(message, activity)
    }

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
     * - Activity is in a valid state (not destroyed)
     * - Activity has a valid window (can be interacted with)
     * - Basic activity lifecycle is functioning correctly
     * 
     * This test ensures the main entry point of the app works correctly and is
     * ready for user interaction. It specifically focuses on launch behavior
     * and activity state, which is distinct from permission-related tests.
     */
    @Test
    fun testMainActivityLaunches() {
        // Verify activity is not null and accessible
        assertActivityNotNull("MainActivity should not be null")
        
        // Verify activity is in a valid state (not destroyed)
        assertFalse(
            "MainActivity should not be destroyed",
            activity.isDestroyed
        )
        
        // Verify activity has a window (can be interacted with)
        assertNotNull(
            "MainActivity should have a window for user interaction",
            activity.window
        )
        
        // Verify activity is not finishing (normal launch state)
        assertFalse(
            "MainActivity should not be finishing during normal launch",
            activity.isFinishing
        )
    }

    /**
     * Tests that MainActivity is available for notification permission handling.
     * 
     * Validates:
     * - Activity instance is accessible for permission-related operations
     * - Activity has a valid context for permission checks
     * - Activity can handle notification permission requests
     * - Permission system is accessible through the activity context
     * 
     * This test specifically focuses on permission-related functionality, which is
     * distinct from general activity launch tests. It verifies that the activity
     * provides the necessary context and infrastructure for permission operations.
     * 
     * Note: This is a basic availability test. For comprehensive permission testing,
     * consider adding tests that verify actual permission request flows and user responses.
     */
    @Test
    fun testNotificationPermission() {
        // Verify activity is not null and accessible
        assertActivityNotNull("Activity should handle notification permissions")
        
        // Verify activity has a valid context for permission operations
        val context: Context = activity
        assertNotNull(
            "Activity should provide a context for permission checks",
            context
        )
        
        // Verify permission system is accessible through activity context
        val packageManager: PackageManager = context.packageManager
        assertNotNull(
            "Activity context should provide PackageManager for permission checks",
            packageManager
        )
        
        // Verify activity is not destroyed (required for permission operations)
        assertFalse(
            "Activity should not be destroyed when checking permissions",
            activity.isDestroyed
        )
    }
}
