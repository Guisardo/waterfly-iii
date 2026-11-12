package com.dreautall.waterflyiii

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Opening from Recents replays the original launch intent, which would
        // reopen the Add Transaction shortcut every time.
        if (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) {
            intent.removeExtra("some unique action key")
        }
        super.onCreate(savedInstanceState)
    }
}
