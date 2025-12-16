# Incremental Sync User Guide

Welcome to the Incremental Sync feature in Waterfly III! This guide explains how to use and configure incremental sync to improve your app's performance and reduce data usage.

## What is Incremental Sync?

Incremental Sync is a smart synchronization feature that **only fetches changed data** from your Firefly III server instead of downloading everything every time. This makes syncing:

- **Faster** - Syncs complete in seconds instead of minutes
- **Lighter** - Uses 70-80% less mobile data
- **Smarter** - Automatically decides what needs updating

## Benefits

### For You
- ⚡ **Faster Syncs** - Get your data in 10-15 seconds instead of 45+ seconds
- 📱 **Less Data Usage** - Save your mobile data plan (80% reduction)
- 🔋 **Better Battery Life** - Sync uses 60% less battery
- 📶 **Works on Slow Networks** - Syncs successfully even on 3G

### For Your Server
- 🖥️ **Reduced Server Load** - 80% fewer API requests
- 🌍 **Kinder to Shared Hosting** - Less stress on shared servers
- ⚡ **Faster Response Times** - Server responds quicker to all users

## How It Works

Instead of downloading all your transactions, accounts, and budgets every time, Incremental Sync:

1. **Checks what changed** since your last sync
2. **Downloads only new or updated data**
3. **Skips unchanged data** to save time and bandwidth
4. **Uses smart caching** for rarely-changed data (categories, bills)

### Example

**Before (Full Sync):**
- Downloads: 1,523 transactions
- Time: 45 seconds
- Data used: 5 MB

**After (Incremental Sync):**
- Downloads: 45 transactions (only changed since last sync)
- Time: 12 seconds
- Data used: 1 MB

**Result:** 73% faster, 80% less data!

## Getting Started

### Enable Incremental Sync

Incremental Sync is **enabled by default** after updating to this version.

To verify or change the setting:

1. Open Waterfly III
2. Go to **Settings** → **Sync Settings**
3. Find **"Incremental Sync"** toggle
4. Ensure it's **ON** (blue)

![Incremental Sync Toggle](images/incremental-sync-toggle.png)

### First Sync After Update

After updating to this version:

1. The app will perform a **full sync** on first launch (this is normal!)
2. Subsequent syncs will be **incremental** automatically
3. You'll see "Incremental Sync" in the progress indicator

## Using Incremental Sync

### Automatic Sync

Incremental Sync happens automatically when:

- You pull down to refresh in any screen
- The app reconnects to the internet after being offline
- Background sync runs (every 15 minutes by default)

You don't need to do anything - it just works!

### Manual Sync

To manually trigger a sync:

1. Go to any screen with transaction data
2. **Pull down** on the screen
3. Release to start sync
4. Watch the progress indicator show "Incremental Sync"

### Viewing Sync Statistics

To see how much you're saving:

1. Go to **Settings** → **Sync Settings**
2. Scroll to **"Last Sync Statistics"**
3. See your savings:
   - Bandwidth Saved (MB/GB)
   - API Calls Saved
   - Items Updated vs. Skipped

![Sync Statistics](images/sync-statistics.png)

## Force Full Sync

Sometimes you may want to download everything from scratch:

### When to Use Full Sync

- You suspect data inconsistencies
- You've made many changes on the web interface
- It's been more than a week since your last full sync

### How to Force Full Sync

1. Go to **Settings** → **Sync Settings**
2. Scroll to **"Manual Sync"**
3. Tap **"Force Full Sync"** button
4. Confirm in the dialog
5. Wait for sync to complete

⚠️ **Note:** Full sync takes longer and uses more data than incremental sync.

## Force Sync Specific Data

Need to refresh just one type of data? You can force sync individual entity types:

### Available Force Sync Options

- **Categories** - Refresh your category list
- **Bills** - Update recurring bills
- **Piggy Banks** - Sync savings goals
- **Transactions** - Refresh all transactions
- **Accounts** - Update account balances
- **Budgets** - Sync budget limits

### How to Force Sync Specific Data

1. Go to **Settings** → **Sync Settings**
2. Scroll to **"Force Sync by Entity Type"**
3. Tap the **[Sync]** button next to the data type
4. Wait for sync to complete

![Force Sync Entities](images/force-sync-entities.png)

### When to Use

- **Categories:** After adding categories on the web interface
- **Bills:** After creating or editing bills
- **Piggy Banks:** After adjusting savings goals
- **Transactions:** When transactions seem out of date
- **Accounts:** After reconciling accounts on the web
- **Budgets:** After changing budget limits

## Advanced Settings

### Sync Window

The **Sync Window** determines how far back incremental sync looks for changes.

**Default:** 30 days

To change:

1. Go to **Settings** → **Sync Settings**
2. Scroll to **"Advanced"**
3. Tap **"Sync Window"**
4. Choose from: 7, 14, 30, 60, or 90 days

**Recommendations:**
- **7 days** - If you sync daily (fastest, minimal data)
- **30 days** - Recommended for most users (balanced)
- **90 days** - If you sync infrequently (safest, more data)

### Cache TTL for Low-Change Entities

Categories, bills, and piggy banks don't change often. To reduce unnecessary API calls, they're cached for a set time.

**Default:** 24 hours

To change:

1. Go to **Settings** → **Sync Settings**
2. Scroll to **"Advanced"**
3. Tap **"Cache TTL"**
4. Choose from: 6, 12, 24, or 48 hours

**Recommendations:**
- **6 hours** - If you frequently add categories/bills
- **24 hours** - Recommended for most users
- **48 hours** - If you rarely change categories/bills (saves most data)

## Understanding Sync Status

### Sync Progress Indicator

During sync, you'll see:

```
Incremental Sync
Fetched: 45
Updated: 12
Skipped: 33 (unchanged)
Bandwidth Saved: 3.2 MB
```

**What it means:**
- **Fetched:** How many items were downloaded from the server
- **Updated:** How many items actually changed and were updated locally
- **Skipped:** How many items were unchanged (saved database writes!)
- **Bandwidth Saved:** How much data you saved vs. full sync

### Cache Age Indicators

In the Sync Settings screen, you'll see cache ages for each data type:

```
Categories       Yesterday
• Cached (23h fresh)
```

**What it means:**
- The data was last synced yesterday
- It's still fresh (within 24-hour cache window)
- Next incremental sync will skip this data

## Troubleshooting

### Sync Seems Slower Than Expected

**Possible causes:**
1. **First sync after update** - First sync is always full (normal)
2. **More than 7 days since last sync** - Automatic full sync fallback
3. **Many changes on server** - Lots of updates to download
4. **Slow network** - Even incremental sync needs good connection

**Solutions:**
- Wait for first full sync to complete
- Sync more frequently to benefit from incremental
- Use WiFi for better performance

### Data Seems Out of Date

**Possible causes:**
1. **Cache is fresh but data changed** - Categories/bills cached for 24h
2. **Changes made outside sync window** - Incremental sync looks back only 30 days

**Solutions:**
1. **Force sync the specific entity type**:
   - Settings → Sync Settings → Force Sync by Entity Type
   - Tap [Sync] next to the stale data
2. **Force full sync**:
   - Settings → Sync Settings → Force Full Sync

### Incremental Sync Disabled Automatically

If incremental sync turns off automatically, it's because:

1. **First sync after install** - Must do full sync first
2. **More than 7 days since last full sync** - Safety fallback
3. **Feature disabled in settings** - Check Settings → Sync Settings

**Solution:**
- Let the full sync complete
- Incremental sync will automatically resume

### Seeing "Clock Skew" Warnings

**What it means:**
Your device's clock and the server's clock are significantly different (>1 hour).

**Solutions:**
1. Enable **automatic date & time** in device settings
2. Ensure correct timezone is selected
3. Sync with WiFi (some mobile networks have time sync issues)

## FAQ

### Q: Will I lose data switching to incremental sync?

**A:** No! Your data is completely safe. The first sync after updating performs a full sync to ensure everything is up to date.

### Q: Can I switch back to full sync only?

**A:** Yes! Go to Settings → Sync Settings → Turn off "Incremental Sync" toggle. All syncs will be full syncs.

### Q: How often should I force a full sync?

**A:** The app automatically does a full sync every 7 days. You don't need to manually force it unless you suspect data issues.

### Q: Does incremental sync work offline?

**A:** Incremental sync requires an internet connection, just like full sync. However, Waterfly III's offline mode still works - your offline changes will sync when you reconnect.

### Q: Why does categories sync say "skipped" every time?

**A:** Categories are cached for 24 hours because they rarely change. This is intentional to save data and server load. Use "Force Sync Categories" if you've added new categories on the web.

### Q: Will incremental sync work with my Firefly III server version?

**A:** Yes! Incremental sync works with all Firefly III API versions. It uses standard API endpoints that have been available for years.

### Q: Does incremental sync affect background sync?

**A:** Yes! Background sync (every 15 minutes on Android) now uses incremental sync by default, making it much faster and more battery-efficient.

### Q: What happens if sync fails halfway through?

**A:** The sync is transactional - either everything succeeds or nothing is changed. Your data stays consistent even if sync is interrupted.

### Q: Can I see detailed sync logs?

**A:** Yes! If you're experiencing issues:
1. Go to Settings → Debug
2. Enable "Verbose Logging"
3. Attempt sync
4. Check logs in Settings → Debug → View Logs

### Q: Does incremental sync sync deletes?

**A:** Yes! If you delete a transaction/account on the web interface, incremental sync will detect and remove it from the app.

## Performance Tips

### Maximize Bandwidth Savings

1. **Sync frequently** - More frequent syncs = less data per sync
2. **Use WiFi for first sync** - Initial full sync is large
3. **Increase cache TTL** - Set to 48h for categories/bills if they rarely change
4. **Reduce sync window** - If you sync daily, use 7-day window

### Maximize Speed

1. **Sync on WiFi** - WiFi is faster than mobile data
2. **Sync during off-peak hours** - Server responds faster
3. **Reduce sync window** - Smaller window = fewer items to check
4. **Keep the app updated** - Performance improvements in each release

### Minimize Battery Usage

1. **Enable incremental sync** - Uses 60% less battery than full sync
2. **Reduce sync window** - Smaller window = less processing
3. **Avoid force syncing unnecessarily** - Only force sync when needed
4. **Use background sync sparingly** - Adjust interval in Settings if needed

## What's Next?

### Planned Improvements

- **Smart sync scheduling** - Sync more frequently when actively using the app
- **Predictive prefetching** - Preload data you're likely to view
- **Compressed responses** - Further reduce bandwidth usage
- **Sync conflicts UI** - Better visibility when data conflicts occur

### Feedback

Found a bug or have a suggestion? Please report it:
- **GitHub Issues**: [waterfly-iii/issues](https://github.com/dreautall/waterfly-iii/issues)
- **In-App Feedback**: Settings → About → Send Feedback

## Technical Details

### How Incremental Sync Works (Technical)

For developers and curious users:

1. **Date-Range Filtering**: Fetches transactions/accounts/budgets modified in last 30 days
2. **Timestamp Comparison**: Compares server `updated_at` with local `server_updated_at`
3. **Smart Caching**: Categories/bills/piggy banks cached for 24h (API doesn't support date filtering)
4. **7-Day Fallback**: Automatically performs full sync if >7 days since last full sync

### Statistics Tracked

The app tracks these metrics locally:
- Total items fetched
- Total items updated
- Total items skipped (unchanged)
- Total bandwidth saved (bytes)
- Total API calls saved
- Last incremental sync timestamp
- Last full sync timestamp

**Privacy:** These statistics are stored only on your device and are never sent anywhere.

## Glossary

- **Full Sync**: Downloads all data from server (slow, high data usage)
- **Incremental Sync**: Downloads only changed data (fast, low data usage)
- **Sync Window**: Time period to look back for changes (e.g., 30 days)
- **Cache TTL**: How long to cache rarely-changed data (e.g., 24 hours)
- **Force Sync**: Manually trigger sync, bypassing cache
- **Bandwidth**: Amount of data transferred over network
- **API Calls**: Number of requests made to Firefly III server

## Conclusion

Incremental Sync makes Waterfly III faster, more efficient, and kinder to your data plan. It works automatically in the background, but gives you full control when you need it.

Enjoy faster syncing! 🚀

---

**Version:** 1.0 (December 2024)
**Compatible with:** Waterfly III v2.0+ / Firefly III API v2.0+

For technical documentation, see [README.md](./README.md).
