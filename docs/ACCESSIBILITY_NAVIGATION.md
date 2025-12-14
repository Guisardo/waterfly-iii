# Accessibility Navigation

This document describes accessibility navigation features in Waterfly III for mobile devices.

## Overview

Waterfly III is a mobile application designed for Android and iOS. Accessibility features focus on:
- **TalkBack** (Android) and **VoiceOver** (iOS) screen reader support
- **Focus indicators** for users with external keyboards or accessibility devices
- **Logical navigation order** for screen readers
- **Semantic labels** for all interactive elements

## Screen Reader Support

### TalkBack (Android)
- Swipe right/left to navigate between elements
- Double-tap to activate focused element
- Two-finger swipe to scroll
- All buttons and interactive elements have descriptive labels
- State changes are announced automatically

### VoiceOver (iOS)
- Swipe right/left to navigate between elements
- Double-tap to activate focused element
- Three-finger swipe to scroll
- All buttons and interactive elements have descriptive labels
- State changes are announced automatically

## Focus Navigation

For users with external keyboards or accessibility devices:

| Action | Gesture/Key |
|--------|-------------|
| Next element | Swipe right / Tab |
| Previous element | Swipe left / Shift+Tab |
| Activate element | Double-tap / Enter/Space |
| Scroll | Two-finger swipe / Arrow keys |

## Focus Indicators

When using external keyboards or switch controls:
- Focused elements are highlighted with a **blue border** (2px width)
- Border follows Material 3 design guidelines
- Visible on all interactive elements (buttons, text fields, list items)

## Announced Events

The app automatically announces:

### Connectivity Changes
- "You are now offline. Changes will sync when back online."
- "Back online. X items pending sync."
- "Back online. All data synced."

### Sync Progress
- "Syncing: X percent complete."
- "Sync complete. X items synced successfully."
- "Sync complete. X items synced, Y items failed."

### Conflicts
- "X conflicts detected. Review required."
- "Conflict resolved successfully."

### Errors
- "Sync error: [error message]"
- "Network error: [error message]"

## Semantic Labels

All UI elements have descriptive labels:

### Sync Status Indicators
- "Synced with server"
- "Pending sync. Will sync when online"
- "Currently syncing with server"
- "Sync failed. Tap to retry"

### Connectivity Status
- "Online. All data synced. Tap for details"
- "Online. X items pending sync. Tap for details"
- "Offline. Changes will sync when online. Tap for details"

### Buttons
- All buttons include action descriptions
- Example: "Sync Now button", "Clear Completed button"

## Navigation Order

Screen readers follow a logical top-to-bottom, left-to-right order:
1. App bar and navigation
2. Primary content
3. Action buttons
4. Bottom navigation (if present)

## Best Practices

### For Screen Reader Users
1. Enable TalkBack (Android) or VoiceOver (iOS) in device settings
2. Use swipe gestures to explore the interface
3. Listen for automatic announcements during sync operations
4. Double-tap to activate buttons and controls

### For External Keyboard Users
1. Connect Bluetooth keyboard to device
2. Use Tab/Shift+Tab to navigate
3. Use Enter/Space to activate elements
4. Focus indicators will show current position

### For Switch Control Users
1. Enable Switch Control in device accessibility settings
2. Configure switches for navigation and selection
3. Focus indicators will highlight current element
4. Use selection switch to activate elements

## Accessibility Settings

Configure accessibility features in:
**Settings → Offline Mode → Accessibility**

Options include:
- Enable/disable sync progress announcements
- Enable/disable connectivity change announcements
- Enable/disable conflict announcements
- Adjust announcement frequency

## Testing

The app has been tested with:
- **TalkBack** on Android 12+
- **VoiceOver** on iOS 15+
- External Bluetooth keyboards
- Switch Control on iOS
- Android Switch Access

## Troubleshooting

**Screen reader not announcing changes?**
- Ensure TalkBack/VoiceOver is enabled
- Check app notification permissions
- Verify accessibility settings in app

**Focus indicator not visible?**
- Connect external keyboard
- Press Tab key to verify focus is moving
- Check theme contrast settings

**Navigation order seems wrong?**
- Report issue with specific screen name
- Include screen reader being used

## Feedback

We continuously improve accessibility. Please report issues or suggestions:
- GitHub Issues: [waterfly-iii/issues](https://github.com/dreautall/waterfly-iii/issues)
- Include: Device, OS version, screen reader used, specific issue

---

Last updated: 2025-12-14
