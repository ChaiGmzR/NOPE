package com.nopefocus.nope

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.provider.Telephony
import android.view.accessibility.AccessibilityEvent
import org.json.JSONArray
import java.util.Calendar

class BlockingAccessibilityService : AccessibilityService() {
    companion object {
        private const val PREFS = "nope_focus"
        private const val RELAUNCH_COOLDOWN_MS = 700L
    }

    private var lastRelaunchAt = 0L
    private var allowedPackagesCache: Set<String> = emptySet()

    override fun onServiceConnected() {
        super.onServiceConnected()
        allowedPackagesCache = resolveAllowedPackages()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            event.eventType != AccessibilityEvent.TYPE_WINDOWS_CHANGED
        ) return

        val foregroundPackage = event.packageName?.toString() ?: return
        if (!isProtectionActive(System.currentTimeMillis())) return
        if (isAllowed(foregroundPackage)) return

        val now = System.currentTimeMillis()
        if (now - lastRelaunchAt < RELAUNCH_COOLDOWN_MS) return
        lastRelaunchAt = now
        bringNopeToFront()
    }

    private fun isProtectionActive(now: Long): Boolean {
        val preferences = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val pausedUntil = preferences.getLong("pausedUntil", 0L)
        if (pausedUntil > now) return false
        if (preferences.getLong("activeUntil", 0L) > now) return true
        return isAnyScheduleActive(preferences.getString("schedulesJson", "[]") ?: "[]")
    }

    private fun isAnyScheduleActive(raw: String): Boolean {
        return try {
            val schedules = JSONArray(raw)
            val calendar = Calendar.getInstance()
            val calendarDay = calendar.get(Calendar.DAY_OF_WEEK)
            val weekday = if (calendarDay == Calendar.SUNDAY) 7 else calendarDay - 1
            val previousWeekday = if (weekday == 1) 7 else weekday - 1
            val minute = calendar.get(Calendar.HOUR_OF_DAY) * 60 + calendar.get(Calendar.MINUTE)

            for (index in 0 until schedules.length()) {
                val schedule = schedules.getJSONObject(index)
                if (!schedule.optBoolean("enabled", true)) continue
                val start = schedule.optInt("startMinute")
                val end = schedule.optInt("endMinute")
                val days = schedule.optJSONArray("weekdays") ?: continue
                val todaySelected = containsDay(days, weekday)
                val previousSelected = containsDay(days, previousWeekday)
                val active = if (start < end) {
                    todaySelected && minute >= start && minute < end
                } else {
                    (todaySelected && minute >= start) || (previousSelected && minute < end)
                }
                if (active) return true
            }
            false
        } catch (_: Exception) {
            false
        }
    }

    private fun containsDay(days: JSONArray, weekday: Int): Boolean {
        for (index in 0 until days.length()) {
            if (days.optInt(index) == weekday) return true
        }
        return false
    }

    private fun isAllowed(packageName: String): Boolean {
        if (packageName == applicationContext.packageName) return true
        if (allowedPackagesCache.isEmpty()) {
            allowedPackagesCache = resolveAllowedPackages()
        }
        return allowedPackagesCache.contains(packageName)
    }

    private fun resolveAllowedPackages(): Set<String> {
        val packages = mutableSetOf(
            applicationContext.packageName,
            "com.whatsapp",
            "com.whatsapp.w4b",
            "com.android.systemui",
            "com.android.permissioncontroller",
            "com.google.android.permissioncontroller",
            "com.android.packageinstaller",
            "com.google.android.packageinstaller",
        )

        fun addResolved(intent: Intent) {
            packageManager.resolveActivity(intent, 0)?.activityInfo?.packageName?.let(packages::add)
        }

        addResolved(Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME))
        addResolved(Intent(Intent.ACTION_DIAL))
        addResolved(Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:")))
        Telephony.Sms.getDefaultSmsPackage(this)?.let(packages::add)

        Settings.Secure.getString(contentResolver, Settings.Secure.DEFAULT_INPUT_METHOD)
            ?.substringBefore('/')
            ?.takeIf { it.isNotBlank() }
            ?.let(packages::add)

        return packages
    }

    private fun bringNopeToFront() {
        val intent = packageManager.getLaunchIntentForPackage(applicationContext.packageName)
            ?: Intent(this, MainActivity::class.java)
        intent.addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                Intent.FLAG_ACTIVITY_SINGLE_TOP,
        )
        intent.putExtra("showFocusGate", true)
        try {
            startActivity(intent)
        } catch (_: Exception) {
            performGlobalAction(GLOBAL_ACTION_HOME)
        }
    }

    override fun onInterrupt() = Unit
}
